/**
 * MindLog Firebase Cloud Functions
 *
 * 마음케어 알림 시스템의 서버 사이드 구현
 *
 * 기능:
 * 1. scheduledEveningNotification - 매일 오후 9시(KST) 저녁 알림
 *
 * 관리자용 HTTP 함수(sendMindcareNotification / addMindcareMessage /
 * getMindcareStatus)는 제거되었다. 인증·App Check 없이 `cors: true` 로
 * 공개되어 있어 누구나 마음케어 토픽 전체에 임의 푸시를 발송할 수 있었고,
 * Flutter 앱은 이 엔드포인트를 한 번도 호출하지 않았다.
 * 재도입 시에는 반드시 App Check 또는 시크릿 헤더 인증과 CORS 도메인 제한을
 * 함께 구현할 것.
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
