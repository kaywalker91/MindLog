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
  getMessageByTimeSlot,
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
 * constants.ts의 시간대별 메시지 사용
 */
export function getEveningMessage(): { title: string; body: string } {
  return getMessageByTimeSlot("evening");
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
    throw error; // fail-safe: Firestore 읽기 실패 시 발송하지 않음
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
 * 발송 잠금 획득 (원자적 create — 이미 존재하면 false 반환)
 *
 * @param timeSlot - 시간대 ("evening" | "manual")
 * @returns true면 잠금 획득 성공 (발송 진행), false면 이미 발송됨 (skip)
 */
export async function acquireSendLock(
  timeSlot: "evening" | "manual" = "evening"
): Promise<boolean> {
  const logKey = getSentLogKey(timeSlot);
  try {
    await db.collection(COLLECTIONS.SENT_LOG).doc(logKey).create({
      status: "sending",
      lockedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    logger.info("[Firestore] Send lock acquired", { logKey });
    return true;
  } catch (error: unknown) {
    // Firestore ALREADY_EXISTS: gRPC code 6
    const code = (error as { code?: number }).code;
    const details = (error as { details?: string }).details ?? "";
    if (code === 6 || details.includes("ALREADY_EXISTS")) {
      // 이미 발송됨 또는 발송 중 → 상태 확인
      try {
        const doc = await db.collection(COLLECTIONS.SENT_LOG).doc(logKey).get();
        const status = doc.data()?.status as string | undefined;
        if (status === "failed") {
          // 실패한 잠금 → 해제 후 재시도
          await db.collection(COLLECTIONS.SENT_LOG).doc(logKey).delete();
          logger.info("[Firestore] Released failed lock, retrying", { logKey });
          return acquireSendLock(timeSlot);
        }
        // "sending" or "sent" → skip
        logger.info("[Firestore] Already sent/locked, skipping", { logKey, status });
        return false;
      } catch (innerError) {
        logger.warn("[Firestore] Could not read lock status, skipping", { innerError, logKey });
        return false; // 보수적: 잠금 상태 불명 → skip
      }
    }
    // 다른 Firestore 오류 → fail-safe: 상위로 전파
    throw error;
  }
}

/**
 * 발송 잠금 완료 상태로 업데이트
 *
 * @param messageId - FCM 메시지 ID
 * @param content - 발송된 메시지 내용
 * @param timeSlot - 시간대
 */
export async function completeSendLock(
  messageId: string,
  content: { title: string; body: string },
  timeSlot: "evening" | "manual" = "evening"
): Promise<void> {
  const logKey = getSentLogKey(timeSlot);
  try {
    await db.collection(COLLECTIONS.SENT_LOG).doc(logKey).update({
      status: "sent",
      messageId,
      title: content.title,
      body: content.body,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await updateStats(getTodayKey());
    logger.info("[Firestore] Send lock completed", { logKey, messageId });
  } catch (error) {
    // completeSendLock 실패 → 잠금은 "sending" 상태 유지 → 재시도 시 skip
    logger.error("[Firestore] Failed to complete send lock (FCM already sent)", { error, logKey });
    // throw하지 않음: FCM은 이미 발송됨
  }
}

/**
 * 발송 실패 시 잠금 해제 (재시도 허용)
 *
 * @param timeSlot - 시간대
 */
export async function releaseSendLockOnFailure(
  timeSlot: "evening" | "manual" = "evening"
): Promise<void> {
  const logKey = getSentLogKey(timeSlot);
  try {
    await db.collection(COLLECTIONS.SENT_LOG).doc(logKey).update({ status: "failed" });
    logger.info("[Firestore] Send lock released (failed)", { logKey });
  } catch (e) {
    logger.warn("[Firestore] Could not release send lock", { e, logKey });
    // 무시: 다음 재시도에서 acquireSendLock이 failed 상태 정리
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
