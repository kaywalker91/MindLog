/**
 * MindLog Functions 상수 정의
 *
 * Flutter 앱과 동일한 값 유지 필수:
 * - MINDCARE_TOPIC: lib/core/services/notification_settings_service.dart
 * - CHANNEL_ID: lib/core/services/notification_service.dart
 */

/** FCM 토픽 - Flutter 앱의 mindcareTopic과 동일해야 함 */
export const MINDCARE_TOPIC = "mindlog_mindcare";

/** 타임존 - 한국 표준시 */
export const TIMEZONE = "Asia/Seoul";

/** Android 알림 채널 ID - Flutter와 일치 */
export const ANDROID_CHANNEL_ID = "mindlog_mindcare";

/** Firestore 컬렉션명 */
export const COLLECTIONS = {
  MESSAGES: "mindcare_messages",
  SCHEDULES: "mindcare_schedules",
  STATS: "mindcare_stats",
  SENT_LOG: "mindcare_sent_log",
} as const;

/** 기본 스케줄 설정 */
export const SCHEDULE = {
  /** 저녁 발송 시간 (KST 기준, 24시간제) */
  EVENING_HOUR: 21,
  EVENING_MINUTE: 0,
  /** cron 표현식: 매일 오후 9시 */
  EVENING_CRON: "0 21 * * *",
} as const;

/** 재시도 설정 */
export const RETRY = {
  MAX_ATTEMPTS: 3,
  BACKOFF_MS: 1000,
} as const;

/** 저녁 마음케어 메시지 (저녁 발송용 - 하루 마무리) */
export const DEFAULT_EVENING_MESSAGES = [
  { title: "오늘 하루는 어떠셨나요?", body: "잠시 멈추고 마음을 돌아봐요 💙" },
  { title: "당신의 하루를 기록해보세요", body: "작은 기록이 큰 변화를 만들어요 ✨" },
  { title: "오늘의 감정은 어떤가요?", body: "마음을 글로 표현해보세요 📝" },
  { title: "잠깐, 오늘 하루 괜찮았나요?", body: "당신의 이야기를 들려주세요 💭" },
  { title: "마음 정리할 시간이에요", body: "오늘의 생각과 감정을 기록해봐요 🌙" },
] as const;
