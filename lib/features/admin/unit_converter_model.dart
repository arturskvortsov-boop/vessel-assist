import 'dart:math' as math;

class Unit {
  const Unit(this.label, this.scale, [this.offset = 0]);

  final String label;
  final double scale;
  final double offset;

  double convertTo(double value, Unit target) {
    if (identical(this, target)) return value;
    return (value * scale + offset - target.offset) / target.scale;
  }
}

const unitCategories = <String, List<Unit>>{
  'Length & distance': [
    Unit('Metre (m)', 1),
    Unit('Kilometre (km)', 1000),
    Unit('Centimetre (cm)', 0.01),
    Unit('Millimetre (mm)', 0.001),
    Unit('Nautical mile (NM)', 1852),
    Unit('Statute mile (mi)', 1609.344),
    Unit('Yard (yd)', 0.9144),
    Unit('Foot (ft)', 0.3048),
    Unit('Inch (in)', 0.0254),
    Unit('Fathom (fm)', 1.8288),
    Unit('Cable (0.1 NM)', 185.2),
  ],
  'Speed': [
    Unit('Knot (kn)', 0.5144444444444445),
    Unit('Metre per second (m/s)', 1),
    Unit('Kilometre per hour (km/h)', 0.2777777777777778),
    Unit('Mile per hour (mph)', 0.44704),
    Unit('Foot per second (ft/s)', 0.3048),
  ],
  'Mass': [
    Unit('Metric tonne (t, MT)', 1000),
    Unit('Kilogram (kg)', 1),
    Unit('Gram (g)', 0.001),
    Unit('Milligram (mg)', 0.000001),
    Unit('Pound (lb)', 0.45359237),
    Unit('Ounce (oz)', 0.028349523125),
    Unit('US short ton', 907.18474),
    Unit('UK long ton', 1016.0469088),
  ],
  'Volume': [
    Unit('Cubic metre (m³)', 1),
    Unit('Litre (L)', 0.001),
    Unit('Millilitre (mL)', 0.000001),
    Unit('Cubic foot (ft³)', 0.028316846592),
    Unit('US gallon', 0.003785411784),
    Unit('Imperial gallon', 0.00454609),
    Unit('Oil barrel (bbl)', 0.158987294928),
  ],
  'Density': [
    Unit('Kilogram per cubic metre (kg/m³)', 1),
    Unit('Tonne per cubic metre (t/m³)', 1000),
    Unit('Gram per cubic centimetre (g/cm³)', 1000),
    Unit('Kilogram per litre (kg/L)', 1000),
    Unit('Pound per cubic foot (lb/ft³)', 16.01846337396014),
  ],
  'Temperature': [
    Unit('Celsius (°C)', 1),
    Unit('Fahrenheit (°F)', 5 / 9, -32 * (5 / 9)),
    Unit('Kelvin (K)', 1, -273.15),
  ],
  'Pressure': [
    Unit('Bar', 100000),
    Unit('Millibar (mbar)', 100),
    Unit('Pascal (Pa)', 1),
    Unit('Hectopascal (hPa)', 100),
    Unit('Kilopascal (kPa)', 1000),
    Unit('Megapascal (MPa)', 1000000),
    Unit('Pound per square inch (psi)', 6894.757293168),
    Unit('Standard atmosphere (atm)', 101325),
    Unit('Kilogram-force per square centimetre (kgf/cm²)', 98066.5),
  ],
  'Volumetric flow': [
    Unit('Cubic metre per hour (m³/h)', 1),
    Unit('Cubic metre per day (m³/day)', 0.041666666666666664),
    Unit('Litre per minute (L/min)', 0.06),
    Unit('Litre per second (L/s)', 3.6),
    Unit('US gallon per minute (US gal/min)', 0.22712470704),
    Unit('Imperial gallon per minute (imp gal/min)', 0.2727654),
  ],
  'Mass flow': [
    Unit('Tonne per day (t/day)', 41.666666666666664),
    Unit('Tonne per hour (t/h)', 1000),
    Unit('Kilogram per hour (kg/h)', 1),
    Unit('Kilogram per day (kg/day)', 0.041666666666666664),
    Unit('Kilogram per second (kg/s)', 3600),
    Unit('Gram per second (g/s)', 3.6),
  ],
  'Specific consumption': [
    Unit('Gram per kilowatt-hour (g/kWh)', 1),
    Unit('Kilogram per megawatt-hour (kg/MWh)', 1),
    Unit('Kilogram per kilowatt-hour (kg/kWh)', 1000),
    Unit('Gram per megajoule (g/MJ)', 3.6),
  ],
  'Kinematic viscosity': [
    Unit('Centistokes (cSt)', 1),
    Unit('Stokes (St)', 100),
    Unit('Square millimetre per second (mm²/s)', 1),
    Unit('Square metre per second (m²/s)', 1000000),
  ],
  'Dynamic viscosity': [
    Unit('Centipoise (cP)', 1),
    Unit('Poise (P)', 100),
    Unit('Millipascal-second (mPa·s)', 1),
    Unit('Pascal-second (Pa·s)', 1000),
  ],
  'Power': [
    Unit('Kilowatt (kW)', 1000),
    Unit('Watt (W)', 1),
    Unit('Megawatt (MW)', 1000000),
    Unit('Mechanical horsepower (hp)', 745.6998715822702),
    Unit('Metric horsepower (PS)', 735.49875),
  ],
  'Energy': [
    Unit('Kilowatt-hour (kWh)', 3600000),
    Unit('Megawatt-hour (MWh)', 3600000000),
    Unit('Watt-hour (Wh)', 3600),
    Unit('Joule (J)', 1),
    Unit('Kilojoule (kJ)', 1000),
    Unit('Megajoule (MJ)', 1000000),
  ],
  'Time': [
    Unit('Hour (h)', 3600),
    Unit('Minute (min)', 60),
    Unit('Second (s)', 1),
    Unit('Millisecond (ms)', 0.001),
    Unit('Day (24 h)', 86400),
    Unit('Week (7 days)', 604800),
  ],
  'Area': [
    Unit('Square metre (m²)', 1),
    Unit('Square kilometre (km²)', 1000000),
    Unit('Square centimetre (cm²)', 0.0001),
    Unit('Square foot (ft²)', 0.09290304),
    Unit('Hectare (ha)', 10000),
    Unit('Acre', 4046.8564224),
  ],
  'Angle': [
    Unit('Degree (°)', 1),
    Unit('Radian (rad)', 180 / math.pi),
    Unit('Arcminute (′)', 0.016666666666666666),
    Unit('Arcsecond (″)', 0.0002777777777777778),
    Unit('Revolution', 360),
  ],
  'Rotational speed': [
    Unit('Revolutions per minute (rpm)', 1),
    Unit('Revolutions per second (r/s)', 60),
    Unit('Radians per second (rad/s)', 30 / math.pi),
  ],
  'Force': [
    Unit('Newton (N)', 1),
    Unit('Kilonewton (kN)', 1000),
    Unit('Kilogram-force (kgf)', 9.80665),
    Unit('Tonne-force (tf)', 9806.65),
  ],
  'Torque': [
    Unit('Newton-metre (N·m)', 1),
    Unit('Kilonewton-metre (kN·m)', 1000),
    Unit('Tonne-force metre (tf·m)', 9806.65),
  ],
  'Moment to change trim (MCTC)': [
    Unit('Tonne-metre per centimetre (t·m/cm)', 1),
    Unit('Tonne-metre per metre (t·m/m)', 0.01),
    Unit('Kilonewton-metre per centimetre (kN·m/cm)', 1 / 9.80665),
  ],
  'Mass per immersion (TPC)': [
    Unit('Tonne per centimetre (t/cm)', 1),
    Unit('Tonne per metre (t/m)', 0.01),
    Unit('Kilogram per centimetre (kg/cm)', 0.001),
    Unit('Kilogram per millimetre (kg/mm)', 0.01),
  ],
  'Ratio & concentration': [
    Unit('Percent (%)', 0.01),
    Unit('Parts per million (ppm)', 0.000001),
    Unit('Parts per billion (ppb)', 1e-9),
    Unit('Parts per thousand (‰)', 0.001),
    Unit('Fraction', 1),
  ],
  'Data size': [
    Unit('Byte (B)', 1),
    Unit('Kilobyte (kB)', 1000),
    Unit('Megabyte (MB)', 1000000),
    Unit('Gigabyte (GB)', 1000000000),
    Unit('Kibibyte (KiB)', 1024),
    Unit('Mebibyte (MiB)', 1048576),
    Unit('Gibibyte (GiB)', 1073741824),
  ],
  'Acceleration': [
    Unit('Metre per second squared (m/s²)', 1),
    Unit('Standard gravity (g₀)', 9.80665),
    Unit('Foot per second squared (ft/s²)', 0.3048),
  ],
  'Frequency': [
    Unit('Hertz (Hz)', 1),
    Unit('Kilohertz (kHz)', 1000),
    Unit('Megahertz (MHz)', 1000000),
    Unit('Gigahertz (GHz)', 1000000000),
  ],
  'Electric current': [
    Unit('Ampere (A)', 1),
    Unit('Milliampere (mA)', 0.001),
    Unit('Kiloampere (kA)', 1000),
  ],
  'Voltage': [
    Unit('Volt (V)', 1),
    Unit('Millivolt (mV)', 0.001),
    Unit('Kilovolt (kV)', 1000),
  ],
  'Resistance': [
    Unit('Ohm (Ω)', 1),
    Unit('Milliohm (mΩ)', 0.001),
    Unit('Kilohm (kΩ)', 1000),
    Unit('Megohm (MΩ)', 1000000),
  ],
};
