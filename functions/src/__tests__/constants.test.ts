/**
 * 마음케어 메시지 상수 불변식 테스트
 *
 * 회귀 방지 대상:
 * 서버 템플릿에 남아 있던 "{name}님, ..." 플레이스홀더가 클라이언트에서 치환되지 않고
 * 푸시 알림에 리터럴로 그대로 노출된 버그.
 *
 * 마음케어는 FCM 토픽 브로드캐스트라 서버가 수신자 이름을 알 수 없고,
 * 클라이언트는 감정 데이터가 없으면 서버 제목/본문을 그대로 표시한다
 * (fcm_service.dart buildPersonalizedMessage). 따라서 서버 문구에 플레이스홀더가
 * 남아 있으면 곧바로 사용자에게 노출된다. spec.md REQ-073 참조.
 */

import {
  MESSAGES_BY_SLOT,
  DEFAULT_EVENING_MESSAGES,
  getMessageByTimeSlot,
  TimeSlot,
} from "../config/constants";

const SLOTS: TimeSlot[] = ["morning", "afternoon", "evening", "night"];

/** {name}, {userName} 등 모든 중괄호 플레이스홀더 (미래 변형까지 차단) */
const PLACEHOLDER_PATTERN = /\{[a-zA-Z_][a-zA-Z0-9_]*\}/;

/** 실제로 사용자에게 노출됐던 문구 — 재도입 금지 */
const REGRESSED_TITLES = [
  "{name}님, 좋은 아침이에요",
  "{name}님, 잠시 쉬어가요",
  "{name}님, 오늘 하루는 어떠셨나요?",
  "{name}님, 오늘도 수고했어요",
];

describe("마음케어 메시지 플레이스홀더 불변식", () => {
  describe("MESSAGES_BY_SLOT", () => {
    it.each(SLOTS)("%s 슬롯의 모든 title/body에 플레이스홀더가 없어야 한다", (slot) => {
      for (const message of MESSAGES_BY_SLOT[slot]) {
        expect(message.title).not.toMatch(PLACEHOLDER_PATTERN);
        expect(message.body).not.toMatch(PLACEHOLDER_PATTERN);
      }
    });

    it.each(SLOTS)("%s 슬롯에 {name} 리터럴이 없어야 한다", (slot) => {
      for (const message of MESSAGES_BY_SLOT[slot]) {
        expect(message.title).not.toContain("{name}");
        expect(message.body).not.toContain("{name}");
      }
    });

    it("과거 노출됐던 제목이 재도입되지 않아야 한다", () => {
      const allTitles = SLOTS.flatMap((slot) =>
        MESSAGES_BY_SLOT[slot].map((message) => message.title)
      );

      for (const regressed of REGRESSED_TITLES) {
        expect(allTitles).not.toContain(regressed);
      }
    });

    it("모든 슬롯에 메시지가 하나 이상 있어야 한다", () => {
      for (const slot of SLOTS) {
        expect(MESSAGES_BY_SLOT[slot].length).toBeGreaterThan(0);
      }
    });

    it.each(SLOTS)("%s 슬롯의 제목은 중복되지 않아야 한다", (slot) => {
      const titles = MESSAGES_BY_SLOT[slot].map((message) => message.title);

      expect(new Set(titles).size).toBe(titles.length);
    });
  });

  describe("getMessageByTimeSlot (실제 발송 경로)", () => {
    afterEach(() => {
      jest.restoreAllMocks();
    });

    it.each(SLOTS)("%s 슬롯은 어떤 인덱스가 뽑혀도 플레이스홀더가 없어야 한다", (slot) => {
      const poolSize = MESSAGES_BY_SLOT[slot].length;

      // 랜덤 인덱스를 전수 순회 — 확률적으로 새는 문구까지 잡는다
      for (let index = 0; index < poolSize; index++) {
        jest.spyOn(Math, "random").mockReturnValue(index / poolSize);

        const message = getMessageByTimeSlot(slot);

        expect(message.title).not.toMatch(PLACEHOLDER_PATTERN);
        expect(message.body).not.toMatch(PLACEHOLDER_PATTERN);
      }
    });

    it.each(SLOTS)("%s 슬롯의 모든 인덱스를 실제로 순회해야 한다", (slot) => {
      const poolSize = MESSAGES_BY_SLOT[slot].length;
      const selected = new Set<string>();

      for (let index = 0; index < poolSize; index++) {
        jest.spyOn(Math, "random").mockReturnValue(index / poolSize);
        selected.add(getMessageByTimeSlot(slot).title);
      }

      // 전수 순회가 실제로 pool 전체를 덮었는지 확인 (위 테스트의 공허한 통과 방지)
      expect(selected.size).toBe(poolSize);
    });
  });

  describe("DEFAULT_EVENING_MESSAGES (현재 유일한 라이브 슬롯)", () => {
    it("evening 슬롯과 동일한 배열이어야 한다", () => {
      expect(DEFAULT_EVENING_MESSAGES).toBe(MESSAGES_BY_SLOT.evening);
    });

    it("모든 title/body에 플레이스홀더가 없어야 한다", () => {
      for (const message of DEFAULT_EVENING_MESSAGES) {
        expect(message.title).not.toMatch(PLACEHOLDER_PATTERN);
        expect(message.body).not.toMatch(PLACEHOLDER_PATTERN);
      }
    });
  });
});
