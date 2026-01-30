/**
 * 스케줄 기반 마음케어 알림 함수
 *
 * 왜 onSchedule을 사용하는가?
 * - 일일 정기 발송에 최적화 (운영 개입 불필요)
 * - cron 표현식으로 정확한 시간 지정
 * - 내장 재시도 메커니즘 활용
 *
 * 실행 시간:
 * - 아침: 매일 오전 9시 (KST) - 활기찬 하루 시작 메시지
 * - 저녁: 매일 오후 9시 (KST) - 하루 마무리 메시지
 */

import { onSchedule, ScheduledEvent } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { SCHEDULE, TIMEZONE, RETRY } from "../config/constants";
import { sendToMindcareTopic } from "../services/fcm.service";
import {
  checkIfSentToday,
  getTodayMessage,
  markAsSent,
  getTodayKey,
  getMessageByTimeSlot,
} from "../services/firestore.service";

/**
 * 매일 오전 9시 (KST) 아침 마음케어 알림 발송
 *
 * 메시지 유형: 활기찬 하루 시작 (좋은 아침이에요!, 상쾌한 아침이에요 등)
 *
 * Idempotency 보장:
 * - 발송 전 오늘 아침 발송 여부 확인
 * - 중복 발송 방지
 */
export const scheduledMindcareNotification = onSchedule(
  {
    schedule: SCHEDULE.MORNING_CRON,
    timeZone: TIMEZONE,
    retryCount: RETRY.MAX_ATTEMPTS,
    // 한국 리전 사용 (latency 최소화)
    region: "asia-northeast3",
  },
  async (_event: ScheduledEvent) => {
    const today = getTodayKey();
    const timeSlot = "morning";
    logger.info("[Scheduled] Starting morning mindcare notification", { today, timeSlot });

    // Step 1: 중복 발송 방지 (Idempotency)
    const alreadySent = await checkIfSentToday(timeSlot);
    if (alreadySent) {
      logger.info("[Scheduled] Already sent morning notification, skipping", { today });
      return;
    }

    // Step 2: 오늘의 메시지 조회 (Firestore 우선, fallback은 아침 메시지)
    const message = await getTodayMessage(timeSlot);
    if (!message) {
      logger.warn("[Scheduled] No message available", { today });
      return;
    }

    // Step 3: FCM 토픽 발송
    const result = await sendToMindcareTopic({
      title: message.title,
      body: message.body,
      data: {
        date: today,
        source: "scheduled",
        timeSlot,
      },
    });

    // Step 4: 결과 처리
    if (result.success && result.messageId) {
      await markAsSent(result.messageId, message, timeSlot);
      logger.info("[Scheduled] Successfully sent morning notification", {
        today,
        messageId: result.messageId,
        title: message.title,
      });
    } else {
      logger.error("[Scheduled] Failed to send morning notification", {
        today,
        error: result.error,
      });
      throw new Error(`FCM send failed: ${result.error}`);
    }
  }
);

/**
 * 매일 오후 9시 (KST) 저녁 마음케어 알림 발송
 *
 * 메시지 유형: 하루 마무리 (오늘 하루는 어떠셨나요?, 마음 정리할 시간이에요 등)
 *
 * Idempotency 보장:
 * - 발송 전 오늘 저녁 발송 여부 확인
 * - 중복 발송 방지
 */
export const scheduledEveningNotification = onSchedule(
  {
    schedule: SCHEDULE.EVENING_CRON,
    timeZone: TIMEZONE,
    retryCount: RETRY.MAX_ATTEMPTS,
    region: "asia-northeast3",
  },
  async (_event: ScheduledEvent) => {
    const today = getTodayKey();
    const timeSlot = "evening";
    logger.info("[Scheduled] Starting evening mindcare notification", { today, timeSlot });

    // Step 1: 중복 발송 방지 (Idempotency)
    const alreadySent = await checkIfSentToday(timeSlot);
    if (alreadySent) {
      logger.info("[Scheduled] Already sent evening notification, skipping", { today });
      return;
    }

    // Step 2: 저녁 메시지 선택 (항상 저녁 메시지 사용)
    const message = getMessageByTimeSlot(timeSlot);

    // Step 3: FCM 토픽 발송
    const result = await sendToMindcareTopic({
      title: message.title,
      body: message.body,
      data: {
        date: today,
        source: "scheduled",
        timeSlot,
      },
    });

    // Step 4: 결과 처리
    if (result.success && result.messageId) {
      await markAsSent(result.messageId, message, timeSlot);
      logger.info("[Scheduled] Successfully sent evening notification", {
        today,
        messageId: result.messageId,
        title: message.title,
      });
    } else {
      logger.error("[Scheduled] Failed to send evening notification", {
        today,
        error: result.error,
      });
      throw new Error(`FCM send failed: ${result.error}`);
    }
  }
);
