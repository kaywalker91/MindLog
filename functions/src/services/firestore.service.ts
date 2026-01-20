/**
 * Firestore 데이터 서비스
 *
 * 마음케어 메시지 조회, 발송 이력 관리, 통계 업데이트 담당
 * Idempotency: 중복 발송 방지를 위한 발송 로그 관리
 */

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { COLLECTIONS, DEFAULT_MORNING_MESSAGES, DEFAULT_EVENING_MESSAGES } from "../config/constants";
import { MindcareMessage, MindcareStats } from "../types";

const db = admin.firestore();

/**
 * 오늘 날짜 키 생성 (YYYY-MM-DD)
 */
export function getTodayKey(): string {
  const now = new Date();
  return now.toISOString().split("T")[0];
}

/**
 * 시간대에 따른 기본 메시지 선택
 *
 * - 오전 5시 ~ 11시: 아침 메시지 (활기찬 하루 시작)
 * - 그 외: 저녁 메시지 (하루 마무리)
 */
function getDefaultMessageByTimeOfDay(): { title: string; body: string } {
  const now = new Date();
  // KST 기준 (Firebase Functions asia-northeast3 리전 사용)
  const hour = now.getHours();

  // 오전 5시 ~ 11시: 아침 메시지
  const messages = (hour >= 5 && hour < 12)
    ? DEFAULT_MORNING_MESSAGES
    : DEFAULT_EVENING_MESSAGES;

  const randomIndex = Math.floor(Math.random() * messages.length);
  return { title: messages[randomIndex].title, body: messages[randomIndex].body };
}

/**
 * 오늘 이미 발송했는지 확인 (Idempotency)
 *
 * @returns true면 이미 발송됨, false면 미발송
 */
export async function checkIfSentToday(): Promise<boolean> {
  const today = getTodayKey();

  try {
    const doc = await db.collection(COLLECTIONS.SENT_LOG).doc(today).get();
    return doc.exists;
  } catch (error) {
    logger.warn("[Firestore] Failed to check sent log", { error, today });
    return false; // 확인 실패 시 발송 시도
  }
}

/**
 * 발송 완료 기록 (Idempotency 보장)
 *
 * @param messageId - FCM 메시지 ID
 * @param messageContent - 발송된 메시지 내용
 */
export async function markAsSent(
  messageId: string,
  messageContent: { title: string; body: string }
): Promise<void> {
  const today = getTodayKey();

  try {
    await db.collection(COLLECTIONS.SENT_LOG).doc(today).set({
      messageId,
      title: messageContent.title,
      body: messageContent.body,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 통계 업데이트
    await updateStats(today);

    logger.info("[Firestore] Marked as sent", { today, messageId });
  } catch (error) {
    logger.error("[Firestore] Failed to mark as sent", { error, today });
    throw error;
  }
}

/**
 * 오늘의 메시지 조회
 *
 * 우선순위:
 * 1. Firestore에 오늘 예정된 메시지
 * 2. 상태가 pending인 메시지 중 가장 오래된 것
 * 3. 기본 메시지 (랜덤)
 */
export async function getTodayMessage(): Promise<{ title: string; body: string } | null> {
  try {
    // 1. 오늘 날짜에 예정된 메시지 찾기
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const scheduledQuery = await db
      .collection(COLLECTIONS.MESSAGES)
      .where("scheduledAt", ">=", admin.firestore.Timestamp.fromDate(today))
      .where("scheduledAt", "<", admin.firestore.Timestamp.fromDate(tomorrow))
      .where("status", "==", "pending")
      .limit(1)
      .get();

    if (!scheduledQuery.empty) {
      const doc = scheduledQuery.docs[0];
      const message = doc.data() as MindcareMessage;

      // 상태 업데이트
      await doc.ref.update({
        status: "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { title: message.title, body: message.body };
    }

    // 2. pending 상태의 가장 오래된 메시지
    const pendingQuery = await db
      .collection(COLLECTIONS.MESSAGES)
      .where("status", "==", "pending")
      .orderBy("createdAt", "asc")
      .limit(1)
      .get();

    if (!pendingQuery.empty) {
      const doc = pendingQuery.docs[0];
      const message = doc.data() as MindcareMessage;

      await doc.ref.update({
        status: "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { title: message.title, body: message.body };
    }

    // 3. 시간대에 맞는 기본 메시지 (랜덤)
    return getDefaultMessageByTimeOfDay();
  } catch (error) {
    logger.error("[Firestore] Failed to get today message", { error });

    // 에러 시 시간대에 맞는 기본 메시지 반환
    return getDefaultMessageByTimeOfDay();
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
