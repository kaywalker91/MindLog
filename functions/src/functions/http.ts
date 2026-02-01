/**
 * HTTP 트리거 함수
 *
 * 관리자용 수동 발송 및 API 엔드포인트 제공
 * Firebase Console에서 호출하거나 curl로 테스트 가능
 *
 * 보안:
 * - Firebase App Check 또는 API Key 인증 권장
 * - 현재는 기본 보안만 적용 (프로덕션에서 강화 필요)
 */

import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { sendToMindcareTopic } from "../services/fcm.service";
import {
  addMessage,
  getStats,
  getTodayKey,
  checkIfSentToday,
  markAsSent,
  getEveningMessage,
} from "../services/firestore.service";
import { ApiResponse } from "../types";

/**
 * 수동 마음케어 알림 발송
 *
 * POST /sendMindcareNotification
 * Body: { title?: string, body?: string }
 *
 * title/body 미제공 시 Firestore에서 메시지 조회
 */
export const sendMindcareNotification = onRequest(
  {
    region: "asia-northeast3",
    cors: true, // CORS 허용 (필요시 도메인 제한)
  },
  async (req, res) => {
    // POST만 허용
    if (req.method !== "POST") {
      res.status(405).json({
        success: false,
        error: "Method not allowed",
        timestamp: new Date().toISOString(),
      } as ApiResponse);
      return;
    }

    const today = getTodayKey();
    logger.info("[HTTP] Manual send request", { today, body: req.body });

    try {
      // 커스텀 메시지 또는 기본 메시지
      let title: string;
      let body: string;

      if (req.body?.title && req.body?.body) {
        title = req.body.title;
        body = req.body.body;
      } else {
        // 커스텀 메시지가 없으면 저녁 메시지 풀에서 랜덤 선택
        const message = getEveningMessage();
        title = message.title;
        body = message.body;
      }

      // FCM 발송
      const result = await sendToMindcareTopic({
        title,
        body,
        data: {
          date: today,
          source: "manual",
        },
      });

      if (result.success && result.messageId) {
        // 발송 이력 기록 (중복 방지용)
        await markAsSent(result.messageId, { title, body });

        res.status(200).json({
          success: true,
          data: {
            messageId: result.messageId,
            title,
            body,
            sentAt: new Date().toISOString(),
          },
          timestamp: new Date().toISOString(),
        } as ApiResponse);
      } else {
        res.status(500).json({
          success: false,
          error: result.error,
          timestamp: new Date().toISOString(),
        } as ApiResponse);
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : "Unknown error";
      logger.error("[HTTP] Send failed", { error: errorMessage });

      res.status(500).json({
        success: false,
        error: errorMessage,
        timestamp: new Date().toISOString(),
      } as ApiResponse);
    }
  }
);

/**
 * 새 메시지 추가
 *
 * POST /addMindcareMessage
 * Body: { title, body, category?, scheduledAt?, priority? }
 */
export const addMindcareMessage = onRequest(
  {
    region: "asia-northeast3",
    cors: true,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({
        success: false,
        error: "Method not allowed",
        timestamp: new Date().toISOString(),
      } as ApiResponse);
      return;
    }

    const { title, body, category, scheduledAt, priority } = req.body;

    if (!title || !body) {
      res.status(400).json({
        success: false,
        error: "title and body are required",
        timestamp: new Date().toISOString(),
      } as ApiResponse);
      return;
    }

    try {
      const messageId = await addMessage(title, body, {
        category,
        scheduledAt: scheduledAt ? new Date(scheduledAt) : undefined,
        priority,
      });

      logger.info("[HTTP] Message added", { messageId, title });

      res.status(201).json({
        success: true,
        data: { messageId, title, body },
        timestamp: new Date().toISOString(),
      } as ApiResponse);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : "Unknown error";
      logger.error("[HTTP] Add message failed", { error: errorMessage });

      res.status(500).json({
        success: false,
        error: errorMessage,
        timestamp: new Date().toISOString(),
      } as ApiResponse);
    }
  }
);

/**
 * 발송 상태 확인
 *
 * GET /getMindcareStatus
 */
export const getMindcareStatus = onRequest(
  {
    region: "asia-northeast3",
    cors: true,
  },
  async (req, res) => {
    if (req.method !== "GET") {
      res.status(405).json({
        success: false,
        error: "Method not allowed",
        timestamp: new Date().toISOString(),
      } as ApiResponse);
      return;
    }

    try {
      const today = getTodayKey();
      const sentToday = await checkIfSentToday();
      const stats = await getStats();

      res.status(200).json({
        success: true,
        data: {
          today,
          sentToday,
          stats: stats || { totalSent: 0, lastSentAt: null, dailyCounts: {} },
        },
        timestamp: new Date().toISOString(),
      } as ApiResponse);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : "Unknown error";
      logger.error("[HTTP] Get status failed", { error: errorMessage });

      res.status(500).json({
        success: false,
        error: errorMessage,
        timestamp: new Date().toISOString(),
      } as ApiResponse);
    }
  }
);
