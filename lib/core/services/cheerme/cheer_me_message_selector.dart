import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';

import 'cheer_me_types.dart';
import 'cheer_me_weight.dart';

/// Cheer Me message selection with **separated** RNG semantics:
/// - Deterministic path: SHA1 seed → stable modulo (queue planning)
/// - Legacy path: [Random] (public `selectMessage` API / tests)
class CheerMeMessageSelector {
  CheerMeMessageSelector._();

  // ── Time category ──────────────────────────────────────────────

  /// morning(5-11), afternoon(12-17), evening(18-23, 0-4)
  static String timeCategory(int hour) {
    if (hour >= 5 && hour <= 11) return 'morning';
    if (hour >= 12 && hour <= 17) return 'afternoon';
    return 'evening';
  }

  // ── Deterministic (seeded) selection for queue planning ────────

  static CheerMeSelection selectForSchedule(
    NotificationSettings settings,
    List<SelfEncouragementMessage> messages, {
    required tz.TZDateTime scheduledDate,
    required String signature,
    required int sequentialCursor,
    double? recentEmotionScore,
  }) {
    switch (settings.rotationMode) {
      case MessageRotationMode.random:
        return selectDeterministicRandom(
          messages,
          seed: 'random_${signature}_${scheduledDate.toIso8601String()}',
        );
      case MessageRotationMode.sequential:
        final index = NotificationSettings.currentIndex(
          sequentialCursor,
          messages.length,
        );
        return CheerMeSelection(index: index, message: messages[index]);
      case MessageRotationMode.emotionAware:
        return selectDeterministicEmotionAware(
          messages,
          recentEmotionScore,
          seed: 'emotion_${signature}_${scheduledDate.toIso8601String()}',
        );
      case MessageRotationMode.timeAware:
        return selectDeterministicTimeAware(
          messages,
          scheduledDate,
          seed: 'time_${signature}_${scheduledDate.toIso8601String()}',
        );
    }
  }

  static CheerMeSelection selectDeterministicRandom(
    List<SelfEncouragementMessage> messages, {
    required String seed,
  }) {
    final index = stableModulo(seed, messages.length);
    return CheerMeSelection(index: index, message: messages[index]);
  }

  static CheerMeSelection selectDeterministicTimeAware(
    List<SelfEncouragementMessage> messages,
    DateTime scheduledDate, {
    required String seed,
  }) {
    final category = timeCategory(scheduledDate.hour);
    final filtered = <CheerMeIndexedMessage>[];

    for (var i = 0; i < messages.length; i++) {
      if (messages[i].timeCategory == category) {
        filtered.add(CheerMeIndexedMessage(index: i, message: messages[i]));
      }
    }

    final pool = filtered.isEmpty
        ? [
            for (var i = 0; i < messages.length; i++)
              CheerMeIndexedMessage(index: i, message: messages[i]),
          ]
        : filtered;

    final selected = pool[stableModulo(seed, pool.length)];
    return CheerMeSelection(index: selected.index, message: selected.message);
  }

  static CheerMeSelection selectDeterministicEmotionAware(
    List<SelfEncouragementMessage> messages,
    double? recentEmotionScore, {
    required String seed,
  }) {
    if (recentEmotionScore == null) {
      return selectDeterministicRandom(messages, seed: seed);
    }

    final weights = CheerMeWeight.forMessages(
      writtenEmotionScores: [
        for (final msg in messages) msg.writtenEmotionScore,
      ],
      recentEmotionScore: recentEmotionScore,
    );
    final totalWeight = CheerMeWeight.total(weights);
    final pick = stableModulo(seed, totalWeight);
    final index = CheerMeWeight.indexFromWeightedPick(weights, pick);
    return CheerMeSelection(index: index, message: messages[index]);
  }

  // ── Legacy Random() selection (public test API semantics) ──────

  /// Legacy API: uses non-deterministic [Random]. Do not seed this path.
  static SelfEncouragementMessage? selectMessage(
    NotificationSettings settings,
    List<SelfEncouragementMessage> messages, {
    double? recentEmotionScore,
    DateTime? now,
    Random? random,
  }) {
    if (messages.isEmpty) return null;
    final rng = random ?? Random();

    switch (settings.rotationMode) {
      case MessageRotationMode.random:
        return messages[rng.nextInt(messages.length)];
      case MessageRotationMode.sequential:
        final index = NotificationSettings.currentIndex(
          settings.lastDisplayedIndex,
          messages.length,
        );
        return messages[index];
      case MessageRotationMode.emotionAware:
        return _selectEmotionAwareRandom(
          messages,
          recentEmotionScore,
          rng: rng,
        );
      case MessageRotationMode.timeAware:
        return _selectTimeAwareRandom(messages, now, rng: rng);
    }
  }

  static SelfEncouragementMessage _selectTimeAwareRandom(
    List<SelfEncouragementMessage> messages,
    DateTime? now, {
    required Random rng,
  }) {
    final hour = (now ?? DateTime.now()).hour;
    final category = timeCategory(hour);
    final filtered = messages
        .where((message) => message.timeCategory == category)
        .toList();
    final pool = filtered.isEmpty ? messages : filtered;
    return pool[rng.nextInt(pool.length)];
  }

  static SelfEncouragementMessage _selectEmotionAwareRandom(
    List<SelfEncouragementMessage> messages,
    double? recentEmotionScore, {
    required Random rng,
  }) {
    if (recentEmotionScore == null) {
      return messages[rng.nextInt(messages.length)];
    }

    final weights = CheerMeWeight.forMessages(
      writtenEmotionScores: [
        for (final msg in messages) msg.writtenEmotionScore,
      ],
      recentEmotionScore: recentEmotionScore,
    );
    final totalWeight = CheerMeWeight.total(weights);
    final pick = rng.nextInt(totalWeight);
    final index = CheerMeWeight.indexFromWeightedPick(weights, pick);
    return messages[index];
  }

  // ── Stable seed helpers ────────────────────────────────────────

  static int stableModulo(String seed, int length) {
    if (length <= 1) return 0;
    final digest = sha1.convert(utf8.encode(seed)).bytes;
    var value = 0;
    for (final byte in digest.take(4)) {
      value = (value << 8) + byte;
    }
    return value % length;
  }
}
