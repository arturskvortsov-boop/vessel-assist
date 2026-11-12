import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'landmark_bearing.dart';
import 'star_compass_form.dart';

class CompassErrorScreen extends StatefulWidget {
  const CompassErrorScreen({super.key});

  @override
  State<CompassErrorScreen> createState() => _CompassErrorScreenState();
}

class _CompassErrorScreenState extends State<CompassErrorScreen> {
  final _fields = <String, TextEditingController>{};
  final _form = GlobalKey<FormState>();
  bool _byStar = true;
  bool _coordinates = false;
  bool _variationWest = false;
  String? _result;
  String? _entry;

  TextEditingController _controller(String key) =>
      _fields.putIfAbsent(key, TextEditingController.new);

  String _value(String key) => _controller(key).text.trim();

  double? _number(String key) =>
      double.tryParse(_value(key).replaceAll(',', '.'));

  void _clearResult() {
    if (_result != null) {
      setState(() {
        _result = null;
        _entry = null;
      });
    }
  }

  Widget _field(
    String key,
    String label, {
    double? min,
    double? max,
    bool optional = false,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _controller(key),
      decoration: InputDecoration(labelText: label, hintText: hint),
      keyboardType: min == null
          ? TextInputType.text
          : TextInputType.numberWithOptions(decimal: true, signed: min < 0),
      onChanged: (_) => _clearResult(),
      validator: (_) {
        if (_value(key).isEmpty) return optional ? null : 'Required';
        if (min == null) return null;
        final value = _number(key);
        return value == null || !value.isFinite || value < min || value > max!
            ? 'Enter a value from $min to $max'
            : null;
      },
    ),
  );

  String _bearing(double value) {
    final tenths = (value * 10).round() % 3600;
    return '${(tenths ~/ 10).toString().padLeft(3, '0')}.${tenths % 10}°';
  }

  String _error(double value) {
    final tenths = (value.abs() * 10).round();
    if (tenths == 0) return '0.0°';
    if (tenths == 1800) return '180.0°';
    return '${(tenths / 10).toStringAsFixed(1)}° ${value > 0 ? 'E' : 'W'}';
  }

  void _calculate() {
    if (!_form.currentState!.validate()) return;
    final truth = _coordinates
        ? landmarkAzimuth(
            _number('lat')!,
            _number('lon')!,
            _number('targetLat')!,
            _number('targetLon')!,
          )
        : _number('true');
    if (truth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A bearing is undefined for these positions.'),
        ),
      );
      return;
    }
    final gyro = _number('gyro');
    final compass = _number('compass');
    if (gyro == null && compass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one observed bearing.')),
      );
      return;
    }
    final magneticError = compass == null ? null : compassError(truth, compass);
    final variation = _number('variation');
    final signedVariation = variation == null
        ? null
        : variation * (_variationWest ? -1 : 1);
    final result = [
      if (gyro != null) 'Gyro error ${_error(compassError(truth, gyro))}',
      if (magneticError != null) 'Compass error ${_error(magneticError)}',
      if (magneticError != null && signedVariation != null)
        'Deviation ${_error(compassError(magneticError, signedVariation))}',
    ].join('\n');
    final entry = [
      if (_value('utc').isNotEmpty) '${_value('utc')} UTC',
      'Landmark: ${_value('landmark')}',
      if (_coordinates) 'Ship position: ${_number('lat')}°, ${_number('lon')}°',
      if (_coordinates)
        'Landmark position: ${_number('targetLat')}°, ${_number('targetLon')}°',
      if (_value('heading').isNotEmpty)
        'Ship heading: ${_bearing(_number('heading')!)}',
      'True bearing: ${_bearing(truth)}',
      if (gyro != null) 'Gyro bearing: ${_bearing(gyro)}',
      if (compass != null) 'Compass bearing: ${_bearing(compass)}',
      if (signedVariation != null) 'Variation: ${_error(signedVariation)}',
      result,
    ].join('\n');
    setState(() {
      _result = result;
      _entry = entry;
    });
  }

  Future<void> _copy() async {
    final entry = _entry;
    if (entry == null) return;
    await Clipboard.setData(ClipboardData(text: entry));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Log entry copied')));
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Compass Error Calculator')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('By Star')),
              ButtonSegment(value: false, label: Text('By Landmark')),
            ],
            selected: {_byStar},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              FocusScope.of(context).unfocus();
              setState(() => _byStar = selection.single);
            },
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _byStar ? 1 : 0,
            sizing: StackFit.expand,
            children: [
              _landmarkForm(context),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: const StarCompassForm(),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _landmarkForm(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(
                'landmark',
                'Landmark name',
                hint: 'Lighthouse, beacon or leading mark',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Calculate true bearing from coordinates'),
                value: _coordinates,
                onChanged: (value) {
                  _clearResult();
                  setState(() => _coordinates = value);
                },
              ),
              if (_coordinates) ...[
                const Text(
                  'Use charted coordinates in decimal degrees. North and east are positive.',
                ),
                const SizedBox(height: 10),
                _field('lat', 'Ship latitude', min: -90, max: 90),
                _field('lon', 'Ship longitude', min: -180, max: 180),
                _field('targetLat', 'Landmark latitude', min: -90, max: 90),
                _field('targetLon', 'Landmark longitude', min: -180, max: 180),
              ] else
                _field('true', 'Charted true bearing (°)', min: 0, max: 360),
              _field(
                'gyro',
                'Observed gyro bearing (°)',
                min: 0,
                max: 360,
                optional: true,
              ),
              _field(
                'compass',
                'Observed magnetic compass bearing (°)',
                min: 0,
                max: 360,
                optional: true,
              ),
              _field(
                'variation',
                'Local variation (°, optional)',
                min: 0,
                max: 180,
                optional: true,
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('East')),
                  ButtonSegment(value: true, label: Text('West')),
                ],
                selected: {_variationWest},
                onSelectionChanged: (value) {
                  _clearResult();
                  setState(() => _variationWest = value.single);
                },
              ),
              const SizedBox(height: 12),
              _field(
                'utc',
                'Observation date and time UTC (optional)',
                optional: true,
                hint: 'YYYY-MM-DD HH:MM:SS',
              ),
              _field(
                'heading',
                'Ship heading (°), optional',
                min: 0,
                max: 360,
                optional: true,
              ),
              FilledButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 16),
                Text(_result!, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ExpansionTile(
                  title: const Text('Calculation details'),
                  expandedAlignment: Alignment.centerLeft,
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [SelectableText(_entry!)],
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _copy,
                  child: const Text('Copy log entry'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
