import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vessel_assist/features/deck/port_distance/port_distance_screen.dart';
import 'package:vessel_assist/core/widgets/dms_coordinate_fields.dart';
import 'package:vessel_assist/features/deck/port_distance/route_map.dart';

void main() {
  testWidgets('Port Distance shows a map and updates time when speed changes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: PortDistanceScreen()));
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        await tester.pump();
      }
    });

    await tester.tap(find.text('Show my position'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Enter position manually'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    Finder field(int row, String label) => find.descendant(
      of: find.byType(DmsCoordinateFields).at(row),
      matching: find.widgetWithText(TextField, label),
    );
    await tester.enterText(field(0, 'Deg °'), '55');
    await tester.enterText(field(0, 'Min ′'), '60');
    await tester.enterText(field(0, 'Sec ″'), '10');
    await tester.enterText(field(1, 'Deg °'), '19');
    await tester.enterText(field(1, 'Min ′'), '28');
    await tester.enterText(field(1, 'Sec ″'), '30');
    final setPosition = find.widgetWithText(FilledButton, 'Set position');
    await tester.ensureVisible(setPosition);
    await tester.pump();
    expect(tester.widget<FilledButton>(setPosition).onPressed, isNull);
    await tester.enterText(field(0, 'Min ′'), '10');
    await tester.ensureVisible(setPosition);
    await tester.pump();
    await tester.tap(find.text('Set position'));
    await tester.pump();
    expect(
      find.text('My position · 55° 10′ 10″ N · 019° 28′ 30″ E'),
      findsOneWidget,
    );
    expect(find.byType(RouteMap), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.ensureVisible(fields.first);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'NLRTM');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.textContaining('(NLRTM)').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(fields.at(1), 'GRPIR');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.textContaining('(GRPIR)').last);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Calculate'));
    await tester.pump(const Duration(milliseconds: 300));
    final distance = find.textContaining('Sea distance · ≈ 2835.6 NM');
    expect(distance, findsOneWidget);
    expect(find.byType(RouteMap), findsOneWidget);
    expect(find.textContaining('Time at sea'), findsNothing);

    await tester.tap(find.text('Distance & time'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(fields.at(2), '12');
    await tester.pump(const Duration(milliseconds: 300));
    expect(distance, findsOneWidget);
    expect(find.text('Time at sea · ≈ 9 d 20 h 18 min'), findsOneWidget);

    await tester.enterText(fields.at(2), '10');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Time at sea · ≈ 11 d 19 h 33 min'), findsOneWidget);
    await tester.enterText(fields.at(2), '0');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Time at sea'), findsNothing);
    expect(find.text('Enter a valid speed greater than 0 kn.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
