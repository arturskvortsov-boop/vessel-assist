import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:vessel_assist/features/deck/organizer/organizer_platform_native.dart';

void main() {
  late Directory directory;
  late Box<String> box;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('vessel-reminders-');
    Hive.init(directory.path);
    box = await Hive.openBox<String>('deck_organizer');
  });

  tearDownAll(() {
    box.close();
  });

  testWidgets('Reminders contains all marked notes and excludes documents', (
    tester,
  ) async {
    Map<String, dynamic> record(
      String title, {
      bool document = false,
      bool remind = false,
      String date = '',
    }) => {
      'title': title,
      'body': '',
      'number': '',
      'document': document,
      'expiry': '2020-01-01',
      'lead': 30,
      'updated': 1,
      'remind': remind,
      'remindDate': date,
    };
    await tester.runAsync(() async {
      await box.put(
        'deck_organizer_records_v1',
        jsonEncode([
          record('Future reminder', remind: true, date: '2199-01-01'),
          record('Past reminder', remind: true, date: '2020-01-01'),
          record('Plain note'),
          record('Expired document', document: true),
        ]),
      );
    });
    await tester.pumpWidget(const MaterialApp(home: DeckOrganizerScreen()));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.tap(find.text('Reminders (2)'));
    await tester.pump();
    expect(find.text('Future reminder'), findsOneWidget);
    expect(find.text('Past reminder'), findsOneWidget);
    expect(find.text('Plain note'), findsNothing);
    expect(find.text('Expired document'), findsNothing);
    await tester.tap(find.text('Open / Edit').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remind me'));
    await tester.tap(find.text('Save'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Reminders (1)'), findsOneWidget);
    final saved = jsonDecode(box.get('deck_organizer_records_v1')!) as List;
    expect(saved.where((record) => record['document'] == true).length, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
