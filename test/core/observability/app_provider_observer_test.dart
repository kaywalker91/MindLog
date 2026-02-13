import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/observability/app_provider_observer.dart';

void main() {
  group('AppProviderObserver', () {
    test('constructor should not throw', () {
      expect(() => AppProviderObserver(), returnsNormally);
    });

    test('didAddProvider should execute without error', () {
      final container = ProviderContainer(observers: [AppProviderObserver()]);
      addTearDown(container.dispose);

      final provider = StateProvider<int>((ref) => 0);
      container.read(provider);

      // Observer callback executed without crash
      expect(container.read(provider), 0);
    });

    test('didUpdateProvider should execute without error', () {
      final container = ProviderContainer(observers: [AppProviderObserver()]);
      addTearDown(container.dispose);

      final provider = StateProvider<int>((ref) => 0);
      container.read(provider);
      container.read(provider.notifier).state = 42;

      expect(container.read(provider), 42);
    });

    test('didDisposeProvider should execute without error', () {
      final container = ProviderContainer(observers: [AppProviderObserver()]);

      final provider = StateProvider<int>((ref) => 0);
      container.read(provider);

      // dispose triggers didDisposeProvider — no crash expected
      container.dispose();
    });

    test('providerDidFail should execute without error', () {
      final container = ProviderContainer(observers: [AppProviderObserver()]);
      addTearDown(container.dispose);

      final failingProvider = Provider<int>((ref) {
        throw StateError('Test error');
      });

      // Reading triggers providerDidFail callback
      expect(() => container.read(failingProvider), throwsA(isA<StateError>()));
    });

    test('assert blocks should call debugPrint in debug mode', () {
      final logs = <String>[];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      final container = ProviderContainer(observers: [AppProviderObserver()]);

      final provider = StateProvider<int>((ref) => 0);
      // didAddProvider → debugPrint
      container.read(provider);
      // didUpdateProvider → debugPrint
      container.read(provider.notifier).state = 1;
      // didDisposeProvider → debugPrint
      container.dispose();

      debugPrint = originalDebugPrint;

      // In debug/test mode, assert blocks execute → debugPrint called
      expect(logs, isNotEmpty);
      expect(logs.any((l) => l.contains('[Provider]')), isTrue);
      expect(logs.any((l) => l.contains('Created')), isTrue);
      expect(logs.any((l) => l.contains('Updated')), isTrue);
      expect(logs.any((l) => l.contains('Disposed')), isTrue);
    });
  });
}
