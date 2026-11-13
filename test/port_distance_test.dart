import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vessel_assist/features/deck/port_distance/port_distance_screen.dart';
import 'package:vessel_assist/features/deck/port_distance/route_map.dart';

void main() {
  testWidgets('Port Distance shows a map and updates time when speed changes', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: PortDistanceScreen()));
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        await tester.pump();
      }
    });

    final fields = find.byType(TextField);
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
