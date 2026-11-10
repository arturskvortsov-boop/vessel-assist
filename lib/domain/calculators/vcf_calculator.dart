class VcfCalculator {
  static const List<Map<String, dynamic>> _densityTable = [
    {'min': 0.810, 'max': 0.813, 'vcf': 0.00091},
    {'min': 0.814, 'max': 0.817, 'vcf': 0.00090},
    {'min': 0.818, 'max': 0.823, 'vcf': 0.00088},
    {'min': 0.824, 'max': 0.828, 'vcf': 0.00087},
    {'min': 0.829, 'max': 0.833, 'vcf': 0.00086},
    {'min': 0.834, 'max': 0.838, 'vcf': 0.00085},
    {'min': 0.839, 'max': 0.848, 'vcf': 0.00084},
    {'min': 0.849, 'max': 0.854, 'vcf': 0.00083},
    {'min': 0.855, 'max': 0.859, 'vcf': 0.00082},
    {'min': 0.860, 'max': 0.876, 'vcf': 0.00081},
    {'min': 0.877, 'max': 0.882, 'vcf': 0.00080},
    {'min': 0.883, 'max': 0.893, 'vcf': 0.00079},
    {'min': 0.894, 'max': 0.902, 'vcf': 0.00078},
    {'min': 0.903, 'max': 0.912, 'vcf': 0.00077},
    {'min': 0.913, 'max': 0.925, 'vcf': 0.00075},
    {'min': 0.926, 'max': 0.937, 'vcf': 0.00074},
    {'min': 0.938, 'max': 0.955, 'vcf': 0.00072},
    {'min': 0.956, 'max': 0.970, 'vcf': 0.00071},
    {'min': 0.971, 'max': 0.982, 'vcf': 0.00070},
    {'min': 0.983, 'max': 0.997, 'vcf': 0.00068},
    {'min': 0.998, 'max': 1.015, 'vcf': 0.00067},
    {'min': 1.016, 'max': 1.020, 'vcf': 0.00066},
    {'min': 1.021, 'max': 1.030, 'vcf': 0.00065}
  ];

  static double getVcf(double density) {
    for (var row in _densityTable) {
      if (density >= row['min'] && density <= row['max']) {
        return row['vcf'];
      }
    }
    return 0.00065; // Значение по умолчанию, если плотность вне диапазона
  }
}