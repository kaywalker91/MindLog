/**
 * Firestore 데이터 서비스
 *
 * 마음케어 메시지 조회, 발송 이력 관리, 통계 업데이트 담당
 * Idempotency: 중복 발송 방지를 위한 발송 로그 관리
 */

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {
  COLLECTIONS,
  DEFAULT_EVENING_MESSAGES,
  TIMEZONE,
} from "../config/constants";
import { MindcareStats } from "../types";

const db = admin.firestore();

/**
 * 오늘 날짜 키 생성 (YYYY-MM-DD, KST 기준)
 * Firebase Functions는 UTC에서 실행되므로 명시적 변환 필요
 */
export function getTodayKey(): string {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: TIMEZONE,
  });
  return formatter.format(new Date());
}

/**
 * 저녁 마음케어 메시지 선택 (랜덤)
 */
export function getEveningMessage(): { title: string; body: string } {
  const randomIndex = Math.floor(Math.random() * DEFAULT_EVENING_MESSAGES.length);
  return {
    title: DEFAULT_EVENING_MESSAGES[randomIndex].title,
    body: DEFAULT_EVENING_MESSAGES[randomIndex].body,
  };
}

/**
 * 발송 로그 키 생성 (날짜 + 시간대)
 * - 저녁: "2024-01-15_evening"
 * - manual: "2024-01-15_manual" (수동 발송)
 */
function getSentLogKey(timeSlot: "evening" | "manual"): string {
  return `${getTodayKey()}_${timeSlot}`;
}

/**
 * 오늘 특정 시간대에 이미 발송했는지 확인 (Idempotency)
 *
 * @param timeSlot - 시간대 ("evening" | "manual")
 * @returns true면 이미 발송됨, false면 미발송
 */
export async function checkIfSentToday(
  timeSlot: "evening" | "manual" = "evening"
): Promise<boolean> {
  const logKey = getSentLogKey(timeSlot);

  try {
    const doc = await db.collection(COLLECTIONS.SENT_LOG).doc(logKey).get();
    return doc.exists;
  } catch (error) {
    logger.warn("[Firestore] Failed to check sent log", { error, logKey });
    return false; // 확인 실패 시 발송 시도
  }
}

/**
 * 발송 완료 기록 (Idempotency 보장)
 *
 * @param messageId - FCM 메시지 ID
 * @param messageContent - 발송된 메시지 내용
 * @param timeSlot - 시간대 ("evening" | "manual")
 */
export async function markAsSent(
  messageId: string,
  messageContent: { title: string; body: string },
  timeSlot: "evening" | "manual" = "evening"
): Promise<void> {
  const logKey = getSentLogKey(timeSlot);
  const today = getTodayKey();

  try {
    await db.collection(COLLECTIONS.SENT_LOG).doc(logKey).set({
      messageId,
      title: messageContent.title,
      body: messageContent.body,
      timeSlot,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 통계 업데이트
    await updateStats(today);

    logger.info("[Firestore] Marked as sent", { logKey, messageId, timeSlot });
  } catch (error) {
    logger.error("[Firestore] Failed to mark as sent", { error, logKey });
    throw error;
  }
}

/**
 * 통계 업데이트
 */
async function updateStats(todayKey: string): Promise<void> {
  const statsRef = db.collection(COLLECTIONS.STATS).doc("global");

  try {
    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(statsRef);

      if (!doc.exists) {
        // 최초 생성
        const newStats: MindcareStats = {
          totalSent: 1,
          lastSentAt: admin.firestore.Timestamp.now(),
          dailyCounts: { [todayKey]: 1 },
        };
        transaction.set(statsRef, newStats);
      } else {
        // 업데이트
        const data = doc.data() as MindcareStats;
        const dailyCounts = data.dailyCounts || {};
        dailyCounts[todayKey] = (dailyCounts[todayKey] || 0) + 1;

        transaction.update(statsRef, {
          totalSent: admin.firestore.FieldValue.increment(1),
          lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
          dailyCounts,
        });
      }
    });
  } catch (error) {
    logger.warn("[Firestore] Failed to update stats", { error });
    // 통계 업데이트 실패는 무시
  }
}

/**
 * 새 메시지 추가 (관리용)
 */
export async function addMessage(
  title: string,
  body: string,
  options?: {
    category?: "daily" | "weekly" | "special";
    scheduledAt?: Date;
    priority?: "high" | "normal";
  }
): Promise<string> {
  const docRef = await db.collection(COLLECTIONS.MESSAGES).add({
    title,
    body,
    category: options?.category || "daily",
    scheduledAt: options?.scheduledAt
      ? admin.firestore.Timestamp.fromDate(options.scheduledAt)
      : null,
    sentAt: null,
    status: "pending",
    priority: options?.priority || "normal",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return docRef.id;
}

/**
 * 발송 통계 조회
 */
export async function getStats(): Promise<MindcareStats | null> {
  try {
    const doc = await db.collection(COLLECTIONS.STATS).doc("global").get();
    return doc.exists ? (doc.data() as MindcareStats) : null;
  } catch (error) {
    logger.error("[Firestore] Failed to get stats", { error });
    return null;
  }
}
