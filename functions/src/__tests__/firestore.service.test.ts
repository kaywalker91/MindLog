/**
 * Firestore Service 테스트
 *
 * 마음케어 저녁 알림 (오후 9시 KST) 관련 기능 검증
 */

import { getTodayKey, getEveningMessage } from "../services/firestore.service";
import { DEFAULT_EVENING_MESSAGES } from "../config/constants";

// Firebase Admin 모킹
jest.mock("firebase-admin", () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn(() => ({
    collection: jest.fn(),
  })),
}));

// Firebase Functions Logger 모킹
jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

describe("Firestore Service - Timezone Handling", () => {
  const originalDate = global.Date;

  afterEach(() => {
    global.Date = originalDate;
    jest.restoreAllMocks();
  });

  describe("getTodayKey", () => {
    it("should return KST date format YYYY-MM-DD", () => {
      // UTC 2024-01-15 00:00:00 = KST 2024-01-15 09:00:00
      const mockDate = new Date("2024-01-15T00:00:00Z");
      jest.spyOn(global, "Date").mockImplementation(() => mockDate);

      const result = getTodayKey();

      // KST 기준 날짜 반환 확인
      expect(result).toMatch(/^\d{4}-\d{2}-\d{2}$/);
      expect(result).toBe("2024-01-15");
    });

    it("should handle KST date boundary correctly", () => {
      // UTC 2024-01-14 15:30:00 = KST 2024-01-15 00:30:00
      const mockDate = new Date("2024-01-14T15:30:00Z");
      jest.spyOn(global, "Date").mockImplementation(() => mockDate);

      const result = getTodayKey();

      // KST 기준으로 이미 15일
      expect(result).toBe("2024-01-15");
    });

    it("should return previous KST date before midnight", () => {
      // UTC 2024-01-14 14:30:00 = KST 2024-01-14 23:30:00
      const mockDate = new Date("2024-01-14T14:30:00Z");
      jest.spyOn(global, "Date").mockImplementation(() => mockDate);

      const result = getTodayKey();

      // KST 기준으로 아직 14일
      expect(result).toBe("2024-01-14");
    });
  });

  describe("getEveningMessage", () => {
    it("should return a valid evening message", () => {
      const message = getEveningMessage();

      expect(message).toHaveProperty("title");
      expect(message).toHaveProperty("body");
      expect(message.title.length).toBeGreaterThan(0);
      expect(message.body.length).toBeGreaterThan(0);
    });

    it("should return a message from DEFAULT_EVENING_MESSAGES", () => {
      const message = getEveningMessage();

      const matchingMessage = DEFAULT_EVENING_MESSAGES.find(
        (m) => m.title === message.title && m.body === message.body
      );

      expect(matchingMessage).toBeDefined();
    });

    it("should never expose an unresolved {name} placeholder", () => {
      // 회귀 방지: 서버 문구에 남은 {name}이 클라이언트에서 치환되지 않고
      // 푸시 알림에 리터럴로 노출된 버그 (spec.md REQ-073).
      // getEveningMessage()는 scheduledEveningNotification이 실제로 호출하는 경로다.
      const poolSize = DEFAULT_EVENING_MESSAGES.length;

      for (let index = 0; index < poolSize; index++) {
        jest.spyOn(Math, "random").mockReturnValue(index / poolSize);

        const message = getEveningMessage();

        expect(message.title).not.toContain("{name}");
        expect(message.body).not.toContain("{name}");
      }
    });
  });

  describe("DEFAULT_EVENING_MESSAGES", () => {
    it("should have evening messages", () => {
      expect(DEFAULT_EVENING_MESSAGES.length).toBeGreaterThan(0);
      expect(DEFAULT_EVENING_MESSAGES[0]).toHaveProperty("title");
      expect(DEFAULT_EVENING_MESSAGES[0]).toHaveProperty("body");
    });

    it("should have unique message titles", () => {
      const titles = DEFAULT_EVENING_MESSAGES.map((m) => m.title);
      const uniqueTitles = new Set(titles);

      expect(uniqueTitles.size).toBe(titles.length);
    });
  });

  describe("KST Hour Calculation Verification", () => {
    it("should correctly identify 9pm KST from UTC noon", () => {
      // UTC 12:00 = KST 21:00
      const utcNoon = new Date("2024-01-15T12:00:00Z");
      const formatter = new Intl.DateTimeFormat("en-US", {
        timeZone: "Asia/Seoul",
        hour: "numeric",
        hour12: false,
      });
      const kstHour = parseInt(formatter.format(utcNoon), 10);

      expect(kstHour).toBe(21);
    });

    it("should correctly identify evening notification time", () => {
      // 저녁 알림 시간: KST 21:00 = UTC 12:00
      const utcNoon = new Date("2024-01-15T12:00:00Z");
      const formatter = new Intl.DateTimeFormat("en-US", {
        timeZone: "Asia/Seoul",
        hour: "numeric",
        hour12: false,
      });
      const kstHour = parseInt(formatter.format(utcNoon), 10);

      // 21시는 저녁 알림 시간
      expect(kstHour).toBe(21);
    });
  });
});
