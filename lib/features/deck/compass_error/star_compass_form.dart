import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/dms_coordinate.dart';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import 'landmark_bearing.dart';
import 'star_azimuth.dart';

class StarCompassForm extends StatefulWidget {
  const StarCompassForm({super.key});

  @override
  State<StarCompassForm> createState() => _StarCompassFormState();
}

class _StarCompassFormState extends State<StarCompassForm> {
  final _latitude = DmsCoordinate('N', 'S', 90);
  final _longitude = DmsCoordinate('E', 'W', 180);
  final _date = TextEditingController();
  final _time = TextEditingController();
  final _gyro = TextEditingController();
  final _compass = TextEditingController();
  final _heading = TextEditingController();
  final _variation = TextEditingController();
  final _utcFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _timeFormat = DateFormat('HH:mm:ss');
  StarSky? _sky;
  StarSight? _star;
  List<StarSight> _stars = [];
  bool _locating = false;
  bool _west = false;
  String? _fix;
  String? _entry;
  String? _error;

  double? _number(TextEditingController controller) {
    final value = double.tryParse(controller.text.trim().replaceAll(',', '.'));
    return value != null && value.isFinite ? value : null;
  }

  DateTime? _utc() {
    final date = _date.text.trim();
    final time = _time.text.trim();
    final match = RegExp(r'^(\d{2}):(\d{2})(?::(\d{2}))?$').firstMatch(time);
    if (match == null || !RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(date)) {
      return null;
    }
    try {
      final normalizedTime = match[3] == null ? '$time:00' : time;
      return DateFormat('dd.MM.yyyy HH:mm:ss')
          .parseStrict('$date $normalizedTime', true);
    } on FormatException {
      return null;
    }
  }

  void _today() {
    final now = DateTime.now().toUtc();
    setState(() {
      _date.text = _dateFormat.format(now);
      _time.text = _timeFormat.format(now);
      _invalidateSky();
    });
  }

  void _invalidateSky() {
    _sky = null;
    _star = null;
    _stars = [];
    _entry = null;
    _error = null;
  }

  void _notice(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _useGps() async {
    setState(() => _locating = true);
    try {
      if (!kIsWeb) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            _notice('Allow location access or enter coordinates manually.');
          }
          return;
        }
      }
      final fix = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      setState(() {
        _invalidateSky();
        _latitude.setDecimal(fix.latitude);
        _longitude.setDecimal(fix.longitude);
        _fix =
            'Device position · ±${fix.accuracy.round()} m · '
            '${_utcFormat.format(fix.timestamp.toUtc())} UTC';
      });
    } catch (_) {
      if (mounted) {
        _notice(
          'Position unavailable. Check permissions or enter coordinates manually.',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _find() {
    final utc = _utc();
    final lat = _latitude.decimal;
    final lon = _longitude.decimal;
    if (utc == null ||
        utc.year < 2000 ||
        utc.year > 2050 ||
        lat == null ||
        lat.abs() >= 90 ||
        lon == null ||
        lon.abs() > 180) {
      if (lat == null || lon == null || lat.abs() >= 90) {
        _notice('Check the degrees, minutes, seconds and hemisphere.');
      } else {
        _notice(
          'Enter a valid UTC date (DD.MM.YYYY, 2000–2050) and time (HH:MM or HH:MM:SS).',
        );
      }
      return;
    }
    final sky = StarSky(utc, lat, lon);
    setState(() {
      _invalidateSky();
      _sky = sky;
      _stars = sky.aboveHorizon;
    });
  }

  String _bearing(double degrees) {
    final tenths = (degrees * 10).round() % 3600;
    return '${(tenths ~/ 10).toString().padLeft(3, '0')}.${tenths % 10}°';
  }

  String _direction(double degrees) {
    final absolute = degrees.abs().toStringAsFixed(1);
    return switch (absolute) {
      '0.0' || '180.0' => '$absolute°',
      _ => '$absolute° ${degrees > 0 ? 'E' : 'W'}',
    };
  }

  String _details(StarSight sight) => [
    'GHA Aries ${_bearing(sight.ghaAries)}',
    'SHA ${_bearing(sight.sha)} · GHA ${_bearing(sight.gha)}',
    'Dec ${sight.declination.abs().toStringAsFixed(2)}° ${sight.declination < 0 ? 'S' : 'N'}',
    'LHA ${_bearing(sight.lha)}',
    'Hc ${sight.altitude.toStringAsFixed(2)}° · Zn ${_bearing(sight.azimuth)} T',
  ].join('\n');

  void _calculate() {
    final sky = _sky;
    final star = _star;
    final gyro = _number(_gyro);
    final compass = _number(_compass);
    final heading = _number(_heading);
    final variation = _number(_variation);
    if (sky == null ||
        star == null ||
        heading == null ||
        heading < 0 ||
        heading > 360 ||
        (gyro == null && compass == null) ||
        !_validBearing(_gyro, gyro) ||
        !_validBearing(_compass, compass)) {
      _notice('Enter the heading and at least one observed bearing (0–360°).');
      return;
    }
    if (_variation.text.trim().isNotEmpty &&
        (variation == null || variation < 0 || variation > 180)) {
      _notice('Enter variation from 0 to 180°.');
      return;
    }
    final magneticError = compass == null
        ? null
        : compassError(star.azimuth, compass);
    final signedVariation = variation == null
        ? null
        : variation * (_west ? -1 : 1);
    final result = [
      if (gyro != null)
        'Gyro error ${_direction(compassError(star.azimuth, gyro))}',
      if (magneticError != null) 'Compass error ${_direction(magneticError)}',
      if (magneticError != null && signedVariation != null)
        'Deviation ${_direction(compassError(magneticError, signedVariation))}',
    ].join('\n');
    setState(() {
      _error = result;
      _entry = [
        '${_utcFormat.format(_utc()!)} UTC',
        'Position: ${sky.latitude.toStringAsFixed(6)}°, ${sky.longitude.toStringAsFixed(6)}° (N/E positive)',
        'Star: ${star.star.name}',
        'Ship heading: ${_bearing(heading)}',
        'True bearing: ${_bearing(star.azimuth)} T',
        if (gyro != null) 'Gyro bearing: ${_bearing(gyro)}',
        if (compass != null) 'Compass bearing: ${_bearing(compass)}',
        if (signedVariation != null)
          'Variation: ${_direction(signedVariation)}',
        result,
        _details(star),
      ].join('\n');
    });
  }

  bool _validBearing(TextEditingController field, double? value) =>
      field.text.trim().isEmpty ||
      (value != null && value >= 0 && value <= 360);

  void _clearEntry() => setState(() {
    _entry = null;
    _error = null;
  });

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    ValueChanged<String>? changed,
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: changed ?? (_) => _clearEntry(),
    ),
  );

  Widget _coordinateFields(String label, DmsCoordinate coordinate) {
    void positionChanged() => setState(() {
      _fix = null;
      _invalidateSky();
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (controller, unit) in [
              (coordinate.degrees, 'Deg °'),
              (coordinate.minutes, 'Min ′'),
              (coordinate.seconds, 'Sec ″'),
            ]) ...[
              Expanded(
                child: _field(
                  controller,
                  unit,
                  numeric: true,
                  changed: (_) => positionChanged(),
                ),
              ),
              const SizedBox(width: 8),
            ],
            SizedBox(
              width: 68,
              child: DropdownButtonFormField<String>(
                key: ValueKey(coordinate.hemisphere),
                initialValue: coordinate.hemisphere,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                isExpanded: true,
                items: [
                  for (final direction in [
                    coordinate.positive,
                    coordinate.negative,
                  ])
                    DropdownMenuItem(value: direction, child: Text(direction)),
                ],
                onChanged: (direction) {
                  if (direction == null) return;
                  coordinate.hemisphere = direction;
                  positionChanged();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final controller in [
      ..._latitude.controllers,
      ..._longitude.controllers,
      _date,
      _time,
      _gyro,
      _compass,
      _heading,
      _variation,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sky = _sky;
    final star = _star;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _coordinateFields('Latitude', _latitude),
        _coordinateFields('Longitude', _longitude),
        OutlinedButton.icon(
          onPressed: _locating ? null : _useGps,
          icon: const Icon(Icons.my_location),
          label: Text(_locating ? 'Getting position…' : 'Use GPS'),
        ),
        if (_fix != null) Text(_fix!),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                _date,
                'Date (UTC)',
                hint: 'DD.MM.YYYY',
                changed: (_) => setState(_invalidateSky),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _field(
                _time,
                'Time (UTC)',
                hint: 'HH:MM:SS',
                changed: (_) => setState(_invalidateSky),
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: _today,
          icon: const Icon(Icons.today_outlined),
          label: const Text('Today'),
        ),
        FilledButton(onPressed: _find, child: const Text('Find stars')),
        if (sky != null) ...[
          const SizedBox(height: 8),
          Text(
            'Sun altitude ≈ ${sky.sunAltitude.toStringAsFixed(1)}°. '
            '${sky.sunAltitude > -6 ? 'Bright sky may hide stars.' : 'Confirm the star visually.'}',
          ),
          if (_stars.isEmpty) const Text('No catalog stars above the horizon.'),
          if (_stars.isNotEmpty)
            DropdownButtonFormField<StarSight>(
              key: ObjectKey(sky),
              initialValue: star,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Star above horizon',
              ),
              items: [
                for (final sight in _stars)
                  DropdownMenuItem(
                    value: sight,
                    enabled: sight.altitude < 85,
                    child: Text(
                      '${sight.star.name} · ${_bearing(sight.azimuth)} T',
                    ),
                  ),
              ],
              onChanged: (value) {
                _star = value;
                _clearEntry();
              },
            ),
          if (_stars.any((sight) => sight.altitude >= 85))
            const Text(
              'Azimuth is sensitive near the zenith. Select a star below 85°.',
            ),
        ],
        if (star != null) ...[
          if (_entry == null)
            ExpansionTile(
              title: const Text('Star data'),
              children: [SelectableText(_details(star))],
            ),
          const SizedBox(height: 12),
          _field(_heading, 'Ship heading (°)', numeric: true),
          _field(_gyro, 'Observed gyro bearing (°)', numeric: true),
          _field(
            _compass,
            'Observed magnetic compass bearing (°)',
            numeric: true,
          ),
          _field(_variation, 'Local variation (°, optional)', numeric: true),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('East')),
              ButtonSegment(value: true, label: Text('West')),
            ],
            selected: {_west},
            onSelectionChanged: (value) {
              _west = value.single;
              _clearEntry();
            },
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _calculate, child: const Text('Calculate')),
        ],
        if (_entry != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: Theme.of(context).textTheme.titleLarge),
          const Text(
            'Estimated astronomical azimuth. Verify before recording.',
          ),
          ExpansionTile(
            title: const Text('Calculation details'),
            expandedAlignment: Alignment.centerLeft,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [SelectableText(_entry!)],
          ),
          OutlinedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _entry!));
              if (mounted) _notice('Log entry copied');
            },
            child: const Text('Copy log entry'),
          ),
        ],
      ],
    );
  }
}
