/**
 * MindLog Firebase Cloud Functions
 *
 * 마음케어 알림 시스템의 서버 사이드 구현
 *
 * 기능:
 * 1. scheduledEveningNotification - 매일 오후 9시(KST) 저녁 알림
 * 2. sendMindcareNotification - 관리자 수동 발송
 * 3. addMindcareMessage - 새 메시지 추가
 * 4. getMindcareStatus - 발송 상태 조회
 *
 * @see Flutter 앱의 FCMService.subscribeToTopic('mindlog_mindcare')
 */

import * as admin from "firebase-admin";

// Firebase Admin 초기화
admin.initializeApp();

// 스케줄 함수: 매일 오후 9시 (KST) 저녁 마음케어 메시지 발송
export {
  scheduledEveningNotification,
} from "./functions/scheduled";

// HTTP 함수: 관리자용 API
export {
  sendMindcareNotification,
  addMindcareMessage,
  getMindcareStatus,
} from "./functions/http";
