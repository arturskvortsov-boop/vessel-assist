import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vessel_assist/core/support_outbox.dart';

void main() {
  late Directory directory;
  late Box<dynamic> queue;
  late Box<dynamic> settings;
  const id = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('vessel-outbox-test-');
    Hive.init(directory.path);
    queue = await Hive.openBox('queue');
    settings = await Hive.openBox('settings');
    await queue.put(
      'feedback:$id',
      jsonEncode({'id': id, 'type': 'bug', 'message': 'Delivery test'}),
    );
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'POST redirect retrieves receipt with GET and clears delivered request',
    () async {
      final methods = <String>[];
      final client = MockClient((request) async {
        methods.add(request.method);
        if (request.method == 'POST') {
          return http.Response(
            '',
            302,
            headers: {
              'location':
                  'https://script.googleusercontent.com/macros/echo?test=1',
            },
          );
        }
        expect(request.url.host, 'script.googleusercontent.com');
        return http.Response(jsonEncode({'accepted': true, 'id': id}), 200);
      });
      final outbox = SupportOutbox(queue, settings, 'test', client: client);
      await outbox.flush();
      expect(methods, ['POST', 'GET']);
      expect(outbox.pendingFeedback, 0);
      expect(outbox.lastFeedbackSent, isNotNull);
      expect(outbox.updates.value, 1);
      outbox.updates.dispose();
      client.close();
    },
  );

  test(
    'Unconfirmed delivery stays queued and retry uses the same ID',
    () async {
      var available = false;
      final ids = <String>[];
      final client = MockClient((request) async {
        ids.add(jsonDecode(request.body)['id'] as String);
        if (!available) return http.Response('Unavailable', 503);
        return http.Response(jsonEncode({'accepted': true, 'id': id}), 200);
      });
      final outbox = SupportOutbox(queue, settings, 'test', client: client);
      await outbox.flush();
      expect(outbox.pendingFeedback, 1);
      expect(outbox.lastFeedbackSent, isNull);
      available = true;
      await outbox.flush();
      expect(outbox.pendingFeedback, 0);
      expect(ids, [id, id]);
      outbox.updates.dispose();
      client.close();
    },
  );

  test('A different receipt ID cannot mark a request as delivered', () async {
    final client = MockClient(
      (_) async =>
          http.Response(jsonEncode({'accepted': true, 'id': 'other'}), 200),
    );
    final outbox = SupportOutbox(queue, settings, 'test', client: client);
    await outbox.flush();
    expect(outbox.pendingFeedback, 1);
    expect(outbox.lastFeedbackSent, isNull);
    outbox.updates.dispose();
    client.close();
  });
}
