import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

enum _Delivery { accepted, rejected, retry }

class SupportOutbox {
  SupportOutbox(this._box, this._settings, this._appVersion);

  static SupportOutbox? current;
  static const _lastAnalyticsSent = 'analytics_last_sent_utc';
  static const _analyticsBatch = 'pending_analytics_batch_v1';
  static const _feedbackUrl = String.fromEnvironment(
    'VESSEL_FEEDBACK_URL',
    defaultValue: 'https://script.google.com/macros/s/AKfycbyhRlPmmW2HdGGDh9txV9A9-2FJqUai1jOwC21eUlxg6a5Sl4kkYrZ3Gq6Xv6lqVobi/exec',
  );
  static const _analyticsUrl = String.fromEnvironment(
    'VESSEL_ANALYTICS_URL',
    defaultValue: 'https://script.google.com/macros/s/AKfycbyB69DtAssqFrYB4VvsHOcZ1q_Rkg7vQP2eC6GNYAMXMNKB6-F7KQ3yyqYjVG0jOen_/exec',
  );

  final Box<dynamic> _box;
  final Box<dynamic> _settings;
  final String _appVersion;
  final _random = Random.secure();
  final updates = ValueNotifier<int>(0);
  bool _sending = false;
  String? _lastScreen;
  DateTime? lastFeedbackSent;

  static Future<void> initialize() async {
    final box = await Hive.openBox('support_outbox_v1');
    String version = 'unknown';
    try {
      final info = await PackageInfo.fromPlatform().timeout(
        const Duration(seconds: 2),
      );
      version = '${info.version}+${info.buildNumber}';
    } catch (_) {
      // Support remains available on platforms without build metadata.
    }
    final outbox = current = SupportOutbox(box, Hive.box('settings'), version);
    Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(outbox.flush()),
    );
    unawaited(outbox.flush());
  }

  bool get feedbackConfigured => _endpoint(_feedbackUrl) != null;
  int get pendingFeedback =>
      _box.keys.where((key) => key.toString().startsWith('feedback:')).length;

  Iterable<String> get rejectedFeedback => _box.keys
      .where((key) => key.toString().startsWith('rejected_feedback:'))
      .map((key) => _box.get(key).toString());

  Uri? _endpoint(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? uri
        : null;
  }

  Future<void> feedback({
    required String type,
    required String message,
    String? email,
    String? section,
  }) => _enqueue('feedback', {
    'type': type,
    'message': message,
    'reply_to': ?email,
    'section': ?section,
  });

  Future<void> record(String event, {String? screen}) async {
    if (event == 'screen_view') {
      if (screen == _lastScreen) return;
      _lastScreen = screen;
    }
    try {
      final keys = _box.keys
          .where((key) => key.toString().startsWith('analytics:'))
          .toList();
      if (keys.length >= 500) {
        await _box.deleteAll(keys.take(keys.length - 499));
      }
      await _enqueue('analytics', {'event': event, 'screen': ?screen});
    } catch (_) {
      // Analytics must never interrupt application use.
    }
  }

  Future<void> _enqueue(String channel, Map<String, String> fields) async {
    final id = List.generate(
      16,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _box.put(
      '$channel:$id',
      jsonEncode({
        'id': id,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'app_version': _appVersion,
        ...fields,
      }),
    );
    if (channel == 'feedback') {
      updates.value++;
      unawaited(flush());
    }
  }

  Future<void> flush() async {
    if (_sending) return;
    _sending = true;
    try {
      await _flushFeedback();
      await _flushAnalytics();
    } finally {
      _sending = false;
    }
  }

  Future<void> _flushFeedback() async {
    final target = _endpoint(_feedbackUrl);
    if (target == null) return;
    final keys = _box.keys
        .where((key) => key.toString().startsWith('feedback:'))
        .toList();
    for (final key in keys) {
      final body = _box.get(key);
      if (body is! String) continue;
      try {
        final id = key.toString().split(':').last;
        final result = await _post(target, body, id);
        if (result == _Delivery.retry) continue;
        if (result == _Delivery.rejected) {
          final request = jsonDecode(body) as Map<String, dynamic>;
          await _box.put('rejected_feedback:$id', request['message'] ?? body);
        }
        await _box.delete(key);
        if (result == _Delivery.accepted) lastFeedbackSent = DateTime.now();
        updates.value++;
      } catch (_) {
        return;
      }
    }
  }

  Future<void> _flushAnalytics() async {
    final target = _endpoint(_analyticsUrl);
    if (target == null) return;
    final lastSent = _settings.get(_lastAnalyticsSent);
    final now = DateTime.now().toUtc();
    if (lastSent is int &&
        now.difference(
              DateTime.fromMillisecondsSinceEpoch(lastSent, isUtc: true),
            ) <
            const Duration(days: 1)) {
      return;
    }

    try {
      final stored = _box.get(_analyticsBatch);
      final Map<String, dynamic> batch;
      if (stored is String) {
        batch = jsonDecode(stored) as Map<String, dynamic>;
      } else {
        final events = [
          for (final key in _box.keys)
            if (key.toString().startsWith('analytics:') &&
                _box.get(key) is String)
              jsonDecode(_box.get(key) as String) as Map<String, dynamic>,
        ];
        if (events.isEmpty) return;
        batch = {'id': events.first['id'], 'events': events.take(500).toList()};
        await _box.put(_analyticsBatch, jsonEncode(batch));
      }

      final result = await _post(
        target,
        jsonEncode(batch),
        batch['id'] as String,
      );
      if (result == _Delivery.retry) return;
      final events = batch['events'] as List;
      await _box.deleteAll([
        for (final event in events) 'analytics:${event['id']}',
      ]);
      await _box.delete(_analyticsBatch);
      if (result == _Delivery.accepted) {
        await _settings.put(
          _lastAnalyticsSent,
          DateTime.now().toUtc().millisecondsSinceEpoch,
        );
      }
    } catch (_) {
      // Keep the pending batch for retry when connectivity returns.
    }
  }

  Future<_Delivery> _post(Uri target, String body, String id) async {
    final response = await http
        .post(
          target,
          headers: {'Content-Type': 'text/plain; charset=utf-8'},
          body: body,
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return _Delivery.retry;
    }
    final receipt = jsonDecode(response.body);
    if (receipt is! Map) return _Delivery.retry;
    if (receipt['accepted'] == true && receipt['id'] == id) {
      return _Delivery.accepted;
    }
    if (receipt['accepted'] == false &&
        receipt['rejected'] == true &&
        (receipt['id'] == null || receipt['id'] == id)) {
      return _Delivery.rejected;
    }
    return _Delivery.retry;
  }
}
