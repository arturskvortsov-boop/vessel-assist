import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:vessel_assist/features/deck/draft_survey/draft_survey_screen.dart';

void main() {
  setUpAll(() {
    // В тестах нет сети — не пытаемся скачивать шрифты Google Fonts.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Draft Survey focuses a mark and restores the saved input', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('draft-survey-test-');
    Hive.init(directory.path);
    final box = await tester.runAsync(
      () => Hive.openBox<dynamic>('deck_draft_survey'),
    );
    try {
      await tester.pumpWidget(const MaterialApp(home: DraftSurveyScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Initial'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Starboard'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(TextButton, 'AFT'));
      await tester.pump(const Duration(milliseconds: 300));
      final field = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'AFT STBD',
      );
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
      await tester.enterText(field, '7,00');
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Save survey'));
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (box!.get('current') == null &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      expect(box!.get('current')['fields']['0draft5'], '7,00');

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const MaterialApp(home: DraftSurveyScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Initial'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<TextField>(field).controller!.text, '7,00');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await Hive.deleteBoxFromDisk('deck_draft_survey');
        await directory.delete();
      });
    }
  });
}
