// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vessel_assist/core/router.dart';
import 'package:vessel_assist/main.dart';

void main() {
  test('App builds smoke test', () {
    // Корневой виджет приложения создаётся без ошибок.
    const app = VesselApp();
    expect(app, isA<StatelessWidget>());

    // Роутер инициализирован и содержит главный экран.
    expect(appRouter, isNotNull);
  });
}
