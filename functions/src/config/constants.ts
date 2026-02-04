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

/** 시간대 타입 정의 */
export type TimeSlot = "morning" | "afternoon" | "evening" | "night";

/** 시간대별 마음케어 메시지
 *
 * {name} 템플릿 지원:
 * - "{name}님, " → 클라이언트에서 이름으로 치환 (이름 없으면 제거)
 * - "{name}" → 클라이언트에서 이름으로 치환 (이름 없으면 제거)
 *
 * 주의: 모든 메시지에 {name}을 넣을 필요 없음 (일부만 개인화)
 */
export const MESSAGES_BY_SLOT: Record<TimeSlot, ReadonlyArray<{ title: string; body: string }>> = {
  morning: [
    { title: "좋은 아침이에요", body: "오늘 하루도 당신을 응원해요 ☀️" },
    { title: "{name}님, 좋은 아침이에요", body: "오늘 하루도 힘내세요 ☀️" },
    { title: "새로운 하루가 시작됐어요", body: "작은 것에도 감사하는 하루 되세요 🌱" },
    { title: "오늘도 힘내세요", body: "좋은 일이 기다리고 있을 거예요 💪" },
    { title: "활기찬 하루 되세요", body: "가볍게 스트레칭으로 시작해보세요 🌿" },
    { title: "상쾌한 아침이에요", body: "오늘의 작은 목표를 세워볼까요? ✨" },
  ],
  afternoon: [
    { title: "잠시 쉬어가요", body: "깊게 숨을 쉬어보세요 🌿" },
    { title: "{name}님, 잠시 쉬어가요", body: "오늘 자신에게 친절해보세요 💚" },
    { title: "마음 한 스푼", body: "오늘 자신에게 친절해보세요 💚" },
    { title: "오후도 파이팅", body: "충분히 쉬어도 괜찮아요 ☕" },
    { title: "잠깐 여유를 가져봐요", body: "작은 행복을 발견해보세요 🌸" },
    { title: "좋은 오후예요", body: "좋아하는 음료 한 잔 어때요? 🍵" },
  ],
  evening: [
    { title: "오늘 하루는 어떠셨나요?", body: "잠시 멈추고 마음을 돌아봐요 💙" },
    { title: "{name}님, 오늘 하루는 어떠셨나요?", body: "당신의 이야기를 들려주세요 💭" },
    { title: "당신의 하루를 기록해보세요", body: "작은 기록이 큰 변화를 만들어요 ✨" },
    { title: "오늘의 감정은 어떤가요?", body: "마음을 글로 표현해보세요 📝" },
    { title: "잠깐, 오늘 하루 괜찮았나요?", body: "당신의 이야기를 들려주세요 💭" },
    { title: "마음 정리할 시간이에요", body: "오늘의 생각과 감정을 기록해봐요 🌙" },
    { title: "하루를 마무리해요", body: "오늘도 수고한 당신에게 박수를 👏" },
  ],
  night: [
    { title: "편안한 밤 되세요", body: "푹 쉬고 내일 만나요 🌙" },
    { title: "{name}님, 오늘도 수고했어요", body: "좋은 꿈 꾸세요 ✨" },
    { title: "오늘도 수고했어요", body: "좋은 꿈 꾸세요 ✨" },
    { title: "좋은 꿈 꾸세요", body: "내일은 더 좋은 하루가 될 거예요 💫" },
    { title: "고요한 밤이에요", body: "따뜻한 잠자리 되세요 🌟" },
    { title: "푹 쉬세요", body: "오늘 하루도 감사해요 🙏" },
  ],
} as const;

/**
 * 시간대에 맞는 메시지 선택 (랜덤)
 * @param slot - 시간대
 */
export function getMessageByTimeSlot(slot: TimeSlot): { title: string; body: string } {
  const messages = MESSAGES_BY_SLOT[slot];
  const randomIndex = Math.floor(Math.random() * messages.length);
  return {
    title: messages[randomIndex].title,
    body: messages[randomIndex].body,
  };
}

/** 저녁 마음케어 메시지 (하위 호환성 유지) */
export const DEFAULT_EVENING_MESSAGES = MESSAGES_BY_SLOT.evening;
