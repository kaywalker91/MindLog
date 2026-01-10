/**
 * FCM 발송 서비스
 *
 * Topic 기반 발송을 사용하는 이유:
 * - 토큰 관리 불필요 (구독자 자동 관리)
 * - 무제한 구독자 지원
 * - Flutter 앱에서 FCMService.subscribeToTopic()으로 구독 관리
 */

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { MINDCARE_TOPIC, ANDROID_CHANNEL_ID } from "../config/constants";
import { MindcarePayload, SendResult } from "../types";

/**
 * 마음케어 토픽으로 FCM 메시지 발송
 *
 * @param payload - 발송할 메시지 내용
 * @returns 발송 결과 (성공 여부, 메시지 ID)
 */
export async function sendToMindcareTopic(
  payload: MindcarePayload
): Promise<SendResult> {
  const message: admin.messaging.Message = {
    topic: MINDCARE_TOPIC,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: {
      ...payload.data,
      type: "mindcare",
      sentAt: new Date().toISOString(),
    },
    android: {
      priority: "high",
      notification: {
        channelId: ANDROID_CHANNEL_ID,
        sound: "default",
        priority: "high",
      },
    },
    apns: {
      headers: {
        "apns-priority": "10",
        "apns-push-type": "alert",
      },
      payload: {
        aps: {
          sound: "default",
          badge: 1,
          contentAvailable: true,
        },
      },
    },
  };

  try {
    const messageId = await admin.messaging().send(message);

    logger.info("[FCM] Message sent successfully", {
      messageId,
      topic: MINDCARE_TOPIC,
      title: payload.title,
    });

    return { success: true, messageId };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error";

    logger.error("[FCM] Failed to send message", {
      error: errorMessage,
      topic: MINDCARE_TOPIC,
      payload,
    });

    return { success: false, error: errorMessage };
  }
}

/**
 * 특정 토픽으로 FCM 메시지 발송 (범용)
 *
 * @param topic - 대상 토픽
 * @param payload - 발송할 메시지 내용
 * @returns 발송 결과
 */
export async function sendToTopic(
  topic: string,
  payload: MindcarePayload
): Promise<SendResult> {
  const message: admin.messaging.Message = {
    topic,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: payload.data,
  };

  try {
    const messageId = await admin.messaging().send(message);
    return { success: true, messageId };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    return { success: false, error: errorMessage };
  }
}
