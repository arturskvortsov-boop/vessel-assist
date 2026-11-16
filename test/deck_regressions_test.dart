import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vessel_assist/domain/models/safety_depth_model.dart';
import 'package:vessel_assist/features/deck/port_distance/sea_routes.dart';
import 'package:vessel_assist/features/deck/ukc/ukc_screen.dart';

void main() {
  testWidgets('UKC blocks pasted text but accepts signed decimal tide', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: UkcScreen()));
    Finder field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
    final tide = field('Tide / Water Level (m)');
    await tester.scrollUntilVisible(
      tide,
      400,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(tide, '-0,5');
    expect(tester.widget<TextField>(tide).controller!.text, '-0,5');
    await tester.enterText(tide, 'bad value');
    expect(tester.widget<TextField>(tide).controller!.text, '-0,5');
    expect(tester.takeException(), isNull);
  });

  test('Safety Depth accepts table Cb and justified CATZOC D allowance', () {
    const vessel = VesselSafetySettings(
      name: 'Test vessel',
      lengthBP: 150,
      breadth: 25,
      cbMethod: tableCbMethod,
    );
    const input = SafetyDepthInput(
      foreDraft: 8,
      aftDraft: 8,
      displacementMT: 0,
      waterDensity: 1.025,
      chartedDepth: 15,
      speedThroughWater: 10,
      heelDegrees: 0,
      densityCorrection: 0,
      catzoc: 'D',
      tableCb: 0.75,
      manualDepthAllowance: 1.25,
      depthAllowanceBasis: 'Test allowance',
    );
    final result = SafetyDepthResult.calculate(vessel, input);
    expect(result.blockCoefficient, 0.75);
    expect(result.chartAllowance, 1.25);
  });

  test('Distinct ports can connect through a shared route node', () {
    final network = SeaNetwork.fromGeoJson(
      '{"features":[{"geometry":{"type":"LineString","coordinates":[[1,1],[2,1]]}}]}',
    );
    final departure = manualPortPoint('1,1 1')!;
    final arrival = manualPortPoint('0.9 1')!;
    final route = network.shortestRoute(departure, arrival);
    expect(route!.points, [departure, (lat: 1.0, lon: 1.0), arrival]);
    expect(route.miles, closeTo(12, 0.02));
    expect(manualPortPoint('91 0'), isNull);
  });
}
