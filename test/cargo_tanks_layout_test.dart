import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:vessel_assist/features/deck/cargo/cargo_tanks_screen.dart';

void main() {
  late Box<dynamic> box;
  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp(
      'vessel-tank-layout-',
    );
    Hive.init(directory.path);
    box = await Hive.openBox('cargo_tanks');
    for (var i = 0; i < 4; i++) {
      await box.put('$i', {
        'id': '$i',
        'name': 'Ballast tank with a long name $i',
        'fuelType': 'Ballast water',
        'capacityM3': 2000.0,
        'volumeM3': 1800.0,
        'densityMtPerM3': 1.025,
        'updatedAt': '2026-11-18',
      });
    }
  });
  tearDownAll(() {
    box.close();
  });

  for (final scenario in [
    (size: const Size(320, 568), scale: 1.0),
    (size: const Size(393, 852), scale: 1.0),
    (size: const Size(393, 852), scale: 2.0),
    (size: const Size(852, 393), scale: 1.0),
    (size: const Size(1024, 1366), scale: 1.0),
  ]) {
    testWidgets(
      'Cargo Tanks fits ${scenario.size} with text scale ${scenario.scale}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = scenario.size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scenario.scale),
                padding: const EdgeInsets.only(top: 44, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
              ),
              child: child!,
            ),
            home: const CargoTanksScreen(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        final add = find.widgetWithText(FilledButton, 'Add Tank');
        final titleBottom = tester.getBottomLeft(find.text('Cargo Tanks')).dy;
        expect(tester.getTopLeft(add).dy - titleBottom, lessThan(65));
        final scroll = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.text('Ballast tank with a long name 3'),
          300,
          scrollable: scroll,
        );
        await tester.drag(scroll, const Offset(0, -2000));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final update = find.widgetWithText(OutlinedButton, 'Update').last;
        final search = find.byTooltip('Search');
        expect(
          tester.getRect(update).overlaps(tester.getRect(search)),
          isFalse,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
