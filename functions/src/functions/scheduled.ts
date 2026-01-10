/**
 * 스케줄 기반 마음케어 알림 함수
 *
 * 왜 onSchedule을 사용하는가?
 * - 일일 정기 발송에 최적화 (운영 개입 불필요)
 * - cron 표현식으로 정확한 시간 지정
 * - 내장 재시도 메커니즘 활용
 *
 * 실행 시간: 매일 오전 9시 (KST)
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
} from "../services/firestore.service";

/**
 * 매일 오전 9시 (KST) 마음케어 알림 발송
 *
 * Idempotency 보장:
 * - 발송 전 오늘 발송 여부 확인
 * - 중복 발송 방지
 */
export const scheduledMindcareNotification = onSchedule(
  {
    schedule: SCHEDULE.DAILY_CRON,
    timeZone: TIMEZONE,
    retryCount: RETRY.MAX_ATTEMPTS,
    // 한국 리전 사용 (latency 최소화)
    region: "asia-northeast3",
  },
  async (_event: ScheduledEvent) => {
    const today = getTodayKey();
    logger.info("[Scheduled] Starting daily mindcare notification", { today });

    // Step 1: 중복 발송 방지 (Idempotency)
    const alreadySent = await checkIfSentToday();
    if (alreadySent) {
      logger.info("[Scheduled] Already sent today, skipping", { today });
      return;
    }

    // Step 2: 오늘의 메시지 조회
    const message = await getTodayMessage();
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
      },
    });

    // Step 4: 결과 처리
    if (result.success && result.messageId) {
      await markAsSent(result.messageId, message);
      logger.info("[Scheduled] Successfully sent", {
        today,
        messageId: result.messageId,
        title: message.title,
      });
    } else {
      logger.error("[Scheduled] Failed to send", {
        today,
        error: result.error,
      });
      // 재시도를 위해 에러 throw
      throw new Error(`FCM send failed: ${result.error}`);
    }
  }
);
