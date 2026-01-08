import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/diary_screen.dart';
import '../screens/main_screen.dart';

enum _NotificationDestination {
  diaryList,
  newDiary,
  statistics,
  settings,
}

class NotificationActionHandler {
  NotificationActionHandler._();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static ProviderContainer? _container;
  static bool _mainReady = false;
  static final List<_NotificationDestination> _pending = [];

  static void configure({
    required GlobalKey<NavigatorState> navigatorKey,
    required ProviderContainer container,
  }) {
    _navigatorKey = navigatorKey;
    _container = container;
  }

  static void markMainReady() {
    _mainReady = true;
    flushPending();
  }

  static void handlePayload(String? payload) {
    final destination = _parsePayload(payload);
    _queueOrHandle(destination);
  }

  static void handleRemoteData(Map<String, dynamic> data) {
    final destination = _parseData(data);
    _queueOrHandle(destination);
  }

  static void flushPending() {
    if (!_mainReady || _navigatorKey?.currentState == null) return;
    if (_pending.isEmpty) return;
    final pendingActions = List<_NotificationDestination>.from(_pending);
    _pending.clear();
    for (final action in pendingActions) {
      _apply(action);
    }
  }

  static void _queueOrHandle(_NotificationDestination destination) {
    if (!_mainReady || _navigatorKey?.currentState == null) {
      _pending.add(destination);
      return;
    }
    _apply(destination);
  }

  static _NotificationDestination _parsePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return _NotificationDestination.diaryList;
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return _parseData(decoded);
      }
    } catch (_) {}
    return _NotificationDestination.diaryList;
  }

  static _NotificationDestination _parseData(Map<String, dynamic> data) {
    final rawType = data['type'] ??
        data['screen'] ??
        data['tab'] ??
        data['action'];
    final value = rawType?.toString().toLowerCase();

    switch (value) {
      case 'reminder':
      case 'new_diary':
      case 'write':
        return _NotificationDestination.newDiary;
      case 'statistics':
      case 'stats':
        return _NotificationDestination.statistics;
      case 'settings':
        return _NotificationDestination.settings;
      case 'diary':
      case 'home':
      case 'diary_list':
        return _NotificationDestination.diaryList;
    }

    final tabIndex = int.tryParse(value ?? '');
    if (tabIndex == 1) {
      return _NotificationDestination.statistics;
    }
    if (tabIndex == 2) {
      return _NotificationDestination.settings;
    }
    return _NotificationDestination.diaryList;
  }

  static void _apply(_NotificationDestination destination) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      _pending.add(destination);
      return;
    }

    navigator.popUntil((route) => route.isFirst);
    final tabIndex = _tabIndexFor(destination);
    _container?.read(selectedTabIndexProvider.notifier).state = tabIndex;

    if (destination == _NotificationDestination.newDiary) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const DiaryScreen()),
      );
    }
  }

  static int _tabIndexFor(_NotificationDestination destination) {
    switch (destination) {
      case _NotificationDestination.statistics:
        return 1;
      case _NotificationDestination.settings:
        return 2;
      case _NotificationDestination.diaryList:
      case _NotificationDestination.newDiary:
        return 0;
    }
  }
}
