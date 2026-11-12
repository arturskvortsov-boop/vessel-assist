import 'package:flutter/widgets.dart';

class DmsCoordinate {
  DmsCoordinate(this.positive, this.negative, this.limit)
    : hemisphere = positive;

  final String positive, negative;
  final int limit;
  String hemisphere;
  final degrees = TextEditingController();
  final minutes = TextEditingController();
  final seconds = TextEditingController();

  List<TextEditingController> get controllers => [degrees, minutes, seconds];

  double? get decimal {
    final deg = int.tryParse(degrees.text.trim());
    final min = int.tryParse(minutes.text.trim());
    final sec = double.tryParse(seconds.text.trim().replaceAll(',', '.'));
    if (deg == null ||
        deg < 0 ||
        deg > limit ||
        min == null ||
        min < 0 ||
        min >= 60 ||
        sec == null ||
        !sec.isFinite ||
        sec < 0 ||
        sec >= 60 ||
        (deg == limit && (min != 0 || sec != 0))) {
      return null;
    }
    final value = deg + min / 60 + sec / 3600;
    return hemisphere == negative ? -value : value;
  }

  void setDecimal(double value) {
    // Round before splitting so the seconds field never rounds up to 60.
    final hundredths = (value.abs() * 360000).round();
    degrees.text = (hundredths ~/ 360000).toString();
    minutes.text = (hundredths ~/ 6000 % 60).toString();
    seconds.text = (hundredths % 6000 / 100).toStringAsFixed(2);
    hemisphere = value < 0 ? negative : positive;
  }
}
