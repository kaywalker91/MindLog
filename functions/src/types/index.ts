/**
 * MindLog Firebase Functions 타입 정의
 */

/** 마음케어 메시지 상태 */
export type MessageStatus = "pending" | "sent" | "failed";

/** 메시지 우선순위 */
export type MessagePriority = "high" | "normal";

/** 메시지 카테고리 */
export type MessageCategory = "daily" | "weekly" | "special" | "morning";

/** Firestore에 저장되는 마음케어 메시지 */
export interface MindcareMessage {
  id: string;
  title: string;
  body: string;
  category: MessageCategory;
  scheduledAt: FirebaseFirestore.Timestamp | null;
  sentAt: FirebaseFirestore.Timestamp | null;
  status: MessageStatus;
  priority: MessagePriority;
  createdAt: FirebaseFirestore.Timestamp;
  metadata?: Record<string, unknown>;
}

/** FCM 발송 페이로드 */
export interface MindcarePayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/** FCM 발송 결과 */
export interface SendResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

/** 발송 통계 */
export interface MindcareStats {
  totalSent: number;
  lastSentAt: FirebaseFirestore.Timestamp | null;
  dailyCounts: Record<string, number>;
}

/** HTTP 응답 */
export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  timestamp: string;
}
