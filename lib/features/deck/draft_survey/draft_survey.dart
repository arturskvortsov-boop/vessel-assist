typedef DraftStations = ({double forward, double midship, double aft});
typedef DraftGeometry = ({
  double lbp,
  DraftStations marks,
  double tableDensity,
});

class DraftReadings {
  final DraftStations port;
  final DraftStations starboard;

  const DraftReadings(this.port, this.starboard);

  DraftStations get means => (
    forward: (port.forward + starboard.forward) / 2,
    midship: (port.midship + starboard.midship) / 2,
    aft: (port.aft + starboard.aft) / 2,
  );
}

class CorrectedDrafts {
  final DraftStations observed;
  final DraftStations corrected;

  const CorrectedDrafts(this.observed, this.corrected);

  double get trimByStern => corrected.aft - corrected.forward;
  double get quarterMean =>
      (corrected.forward + 6 * corrected.midship + corrected.aft) / 8;
  double get deflection =>
      (corrected.forward + corrected.aft) / 2 - corrected.midship;
}

CorrectedDrafts? correctDrafts(DraftGeometry geometry, DraftReadings readings) {
  final (:lbp, :marks, tableDensity: _) = geometry;
  // Mark offsets are positive forward of their respective reference station.
  final forwardMark = lbp + marks.forward;
  final midshipMark = lbp / 2 + marks.midship;
  final aftMark = marks.aft;
  if (!(forwardMark > midshipMark && midshipMark > aftMark)) return null;

  final means = readings.means;
  final slope = (means.aft - means.forward) / (forwardMark - aftMark);
  final corrected = (
    forward: means.forward + marks.forward * slope,
    midship: means.midship + marks.midship * slope,
    aft: means.aft + marks.aft * slope,
  );
  if ([
    corrected.forward,
    corrected.midship,
    corrected.aft,
  ].any((value) => !value.isFinite || value <= 0)) {
    return null;
  }
  return CorrectedDrafts(means, corrected);
}

enum LcfReference {
  forwardOfMidships('Forward of midships'),
  aftOfMidships('Aft of midships'),
  forwardOfAp('Forward of aft perpendicular'),
  aftOfAp('Aft of aft perpendicular');

  const LcfReference(this.label);
  final String label;

  double forwardOfMidship(double distance, double lbp) => switch (this) {
    LcfReference.forwardOfMidships => distance,
    LcfReference.aftOfMidships => -distance,
    LcfReference.forwardOfAp => distance - lbp / 2,
    LcfReference.aftOfAp => -distance - lbp / 2,
  };
}

typedef Hydrostatics = ({
  double displacement,
  double tpc,
  double lcfForward,
  double mctcPlus,
  double mctcMinus,
});

class SurveyResult {
  final CorrectedDrafts drafts;
  final double firstTrim;
  final double secondTrim;
  final double listCorrection;
  final double displacementAtTableDensity;
  final double displacement;
  final double deductibles;

  const SurveyResult({
    required this.drafts,
    required this.firstTrim,
    required this.secondTrim,
    required this.listCorrection,
    required this.displacementAtTableDensity,
    required this.displacement,
    required this.deductibles,
  });

  double get net => displacement - deductibles;
}

SurveyResult calculateSurvey({
  required DraftGeometry geometry,
  required CorrectedDrafts drafts,
  required Hydrostatics hydro,
  required double waterDensity,
  required double listCorrection,
  required double deductibles,
}) {
  final trim = drafts.trimByStern;
  final first = -hydro.lcfForward * trim * hydro.tpc * 100 / geometry.lbp;
  final second =
      50 * trim * trim * (hydro.mctcPlus - hydro.mctcMinus) / geometry.lbp;
  final tableDisplacement =
      hydro.displacement + first + second + listCorrection;
  return SurveyResult(
    drafts: drafts,
    firstTrim: first,
    secondTrim: second,
    listCorrection: listCorrection,
    displacementAtTableDensity: tableDisplacement,
    displacement: tableDisplacement * waterDensity / geometry.tableDensity,
    deductibles: deductibles,
  );
}

enum CargoOperation { loading, discharging }

double cargoChange(
  CargoOperation operation,
  SurveyResult initial,
  SurveyResult finalSurvey,
) => operation == CargoOperation.loading
    ? finalSurvey.net - initial.net
    : initial.net - finalSurvey.net;
