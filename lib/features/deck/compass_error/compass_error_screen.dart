import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_scaffold.dart';
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
    Widget build(BuildContext context) => AppScaffold(
    title: 'Compass Error Calculator',
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _MethodSelector(
            byStar: _byStar,
            onChanged: (value) {
              FocusScope.of(context).unfocus();
              setState(() => _byStar = value);
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Section(
                title: 'Landmark',
                icon: Icons.terrain,
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
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    _field('lat', 'Ship latitude', min: -90, max: 90),
                    _field('lon', 'Ship longitude', min: -180, max: 180),
                    _field('targetLat', 'Landmark latitude', min: -90, max: 90),
                    _field('targetLon', 'Landmark longitude', min: -180, max: 180),
                  ] else
                    _field('true', 'Charted true bearing (°)', min: 0, max: 360),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Observed bearings',
                icon: Icons.explore,
                children: [
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
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Variation',
                icon: Icons.swap_horiz,
                children: [
                  _field(
                    'variation',
                    'Local variation (°, optional)',
                    min: 0,
                    max: 180,
                    optional: true,
                  ),
                  const SizedBox(height: 4),
                  _EastWestSelector(
                    west: _variationWest,
                    onChanged: (value) {
                      _clearResult();
                      setState(() => _variationWest = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Observation',
                icon: Icons.schedule,
                children: [
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
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_outlined),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                label: const Text('Calculate'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 20),
                _ResultCard(
                  result: _result!,
                  entry: _entry!,
                  onCopy: _copy,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Сегментированный выбор метода: By Star / By Landmark.
class _MethodSelector extends StatelessWidget {
  final bool byStar;
  final ValueChanged<bool> onChanged;
  const _MethodSelector({required this.byStar, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MethodTile(
            label: 'By Star',
            icon: Icons.star_outline,
            active: byStar,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MethodTile(
            label: 'By Landmark',
            icon: Icons.terrain,
            active: !byStar,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _MethodTile({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: 0.14) : cardSolid,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? accent : border,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: active ? accent : textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? accent : textMuted,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка-секция с заголовком и иконкой.
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardSolid,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

/// Стилизованный переключатель East / West.
class _EastWestSelector extends StatelessWidget {
  final bool west;
  final ValueChanged<bool> onChanged;
  const _EastWestSelector({required this.west, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SideTile(
            label: 'East',
            active: !west,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SideTile(
            label: 'West',
            active: west,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _SideTile extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SideTile({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? accent : border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? accent : textMuted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Карточка результата с деталями и копированием.
class _ResultCard extends StatelessWidget {
  final String result;
  final String entry;
  final VoidCallback onCopy;
  const _ResultCard({
    required this.result,
    required this.entry,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'RESULT',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.5),
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 8),
            title: const Text('Calculation details'),
            expandedAlignment: Alignment.centerLeft,
            children: [SelectableText(entry)],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy log entry'),
          ),
        ],
      ),
    );
  }
}
