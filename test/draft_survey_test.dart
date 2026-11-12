import 'package:flutter_test/flutter_test.dart';
import 'package:vessel_assist/features/deck/draft_survey/draft_survey.dart';

void main() {
  const geometry = (
    lbp: 185.0,
    marks: (forward: -3.1, midship: -0.84, aft: 10.48),
    tableDensity: 1.025,
  );

  test(
    'Excel example reproduces both net displacements and cargo quantity',
    () {
      final initial = calculateSurvey(
        geometry: geometry,
        drafts: correctDrafts(
          geometry,
          const DraftReadings(
            (forward: 4.96, midship: 6.04, aft: 6.99),
            (forward: 4.97, midship: 6.05, aft: 7.0),
          ),
        )!,
        hydro: (
          displacement: 29490.47,
          tpc: 53.2,
          lcfForward: 5.137,
          mctcPlus: 648.93,
          mctcMinus: 618.22,
        ),
        waterDensity: 1.0195,
        listCorrection: 0,
        deductibles: 18137.9,
      );
      final finalSurvey = calculateSurvey(
        geometry: geometry,
        drafts: correctDrafts(
          geometry,
          const DraftReadings(
            (forward: 12.16, midship: 12.66, aft: 13.08),
            (forward: 12.17, midship: 12.67, aft: 13.09),
          ),
        )!,
        hydro: (
          displacement: 66837.22,
          tpc: 58.7,
          lcfForward: -2.652,
          mctcPlus: 850.99,
          mctcMinus: 834.51,
        ),
        waterDensity: 1.0185,
        listCorrection: 0,
        deductibles: 1796.7,
      );
      expect(initial.drafts.quarterMean, closeTo(6.03221386, 1e-7));
      expect(finalSurvey.drafts.quarterMean, closeTo(12.65656983, 1e-7));
      expect(initial.net, closeTo(10912.05344, 0.001));
      expect(finalSurvey.net, closeTo(64704.05580, 0.001));
      expect(
        cargoChange(CargoOperation.loading, initial, finalSurvey),
        closeTo(53792.00235, 0.001),
      );
      expect(
        cargoChange(CargoOperation.discharging, finalSurvey, initial),
        closeTo(53792.00235, 0.001),
      );
      expect(
        cargoChange(CargoOperation.discharging, initial, finalSurvey),
        lessThan(0),
      );
    },
  );

  test('UK P&I worked example normalizes LCF and matches displacement', () {
    const ship = (
      lbp: 181.8,
      marks: (forward: -2.94, midship: -1.44, aft: 7.30),
      tableDensity: 1.025,
    );
    final drafts = correctDrafts(
      ship,
      const DraftReadings(
        (forward: 4.61, midship: 4.93, aft: 5.58),
        (forward: 4.65, midship: 5.10, aft: 5.60),
      ),
    )!;
    final hydro = (
      displacement: 19894.37,
      tpc: 42.338,
      lcfForward: LcfReference.forwardOfAp.forwardOfMidship(95.231, ship.lbp),
      mctcPlus: 445.89,
      mctcMinus: 435.26,
    );
    final result = calculateSurvey(
      geometry: ship,
      drafts: drafts,
      hydro: hydro,
      waterDensity: 1.0185,
      listCorrection: 0,
      deductibles: 0,
    );
    expect(drafts.quarterMean, closeTo(5.0357, 0.0001));
    expect(result.firstTrim, closeTo(-102.61, 0.02));
    expect(result.secondTrim, closeTo(3.03, 0.02));
    expect(result.displacement, closeTo(19669.26, 0.05));
    final withList = calculateSurvey(
      geometry: ship,
      drafts: drafts,
      hydro: hydro,
      waterDensity: 1.0185,
      listCorrection: 10,
      deductibles: 0,
    );
    expect(
      withList.displacement - result.displacement,
      closeTo(10 * 1.0185 / 1.025, 0.0001),
    );
  });

  test('Draft geometry rejects marks in the wrong order', () {
    const invalid = (
      lbp: 185.0,
      marks: (forward: -200.0, midship: 0.0, aft: 0.0),
      tableDensity: 1.025,
    );
    const readings = DraftReadings(
      (forward: 5.0, midship: 5.0, aft: 5.0),
      (forward: 5.0, midship: 5.0, aft: 5.0),
    );
    expect(correctDrafts(invalid, readings), isNull);
  });
}
