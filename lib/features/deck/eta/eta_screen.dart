

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/models/eta_model.dart';
import '../../../domain/models/eco_speed_model.dart';

class EtaScreen extends StatefulWidget {
  const EtaScreen({super.key});

  @override
  State<EtaScreen> createState() => _EtaScreenState();
}

class _EtaScreenState extends State<EtaScreen> {
    final _form = GlobalKey<FormState>();
  final _distance = TextEditingController();
  final _speed = TextEditingController();
  final _ecoSpeed = TextEditingController();
  final _fullSpeed = TextEditingController();
  String _mode = 'eta'; // 'eta' | 'speed' | 'eco'
  int _departureOffset = 0, _arrivalOffset = 0;
  late DateTime _departure, _target;
  EtaResult? _result;
  EcoSpeedPlan? _ecoResult;
  String? _error;

  bool get _required => _mode == 'speed';
  bool get _isEco => _mode == 'eco';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _departure = DateTime.utc(now.year, now.month, now.day, now.hour, now.minute);
    _target = _departure.add(const Duration(days: 1));
  }

    @override
  void dispose() {
    _distance.dispose();
    _speed.dispose();
    _ecoSpeed.dispose();
    _fullSpeed.dispose();
    super.dispose();
  }

  double? _parse(String text) {
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    return v != null && v.isFinite ? v : null;
  }

    void _invalidate() {
    _result = null;
    _ecoResult = null;
    _error = null;
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: cardSolid,
        errorMaxLines: 3,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardSolid,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: child,
      );

  Widget _number(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: TextFormField(
          controller: c,
          decoration: _decoration(label),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(_invalidate),
          validator: (text) {
            final v = _parse(text ?? '');
            return v == null || v <= 0 ? 'Enter a positive finite number.' : null;
          },
        ),
      );

  Future<void> _pickTime(bool departure) async {
    final current = departure ? _departure : _target;
    final day = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (day == null || !mounted) return;
    final clock = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (clock == null || !mounted) return;
    final value = DateTime.utc(day.year, day.month, day.day, clock.hour, clock.minute);
    setState(() {
      if (departure) {
        _departure = value;
      } else {
        _target = value;
      }
      _invalidate();
    });
  }

  Widget _dateField(bool departure) {
    final offset = departure ? _departureOffset : _arrivalOffset;
    final time = departure ? _departure : _target;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () => _pickTime(departure),
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: _decoration('${departure ? 'Departure Time' : 'Target Arrival'} (${etaOffsetLabel(offset)})'),
          child: Row(
            children: [
              Expanded(child: Text(etaDateTime(time))),
              Icon(Icons.calendar_month_outlined, color: accent),
            ],
          ),
        ),
      ),
    );
  }

    Widget _zone(bool departure) {
    final current = departure ? _departureOffset : _arrivalOffset;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final picked = await showModalBottomSheet<int>(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => _OffsetSheet(
              title: departure ? 'Departure UTC Offset' : 'Arrival UTC Offset',
              selected: current,
            ),
          );
          if (picked == null) return;
          setState(() {
            if (departure) {
              _departureOffset = picked;
            } else {
              _arrivalOffset = picked;
            }
            _invalidate();
          });
        },
        child: InputDecorator(
          decoration: _decoration(departure ? 'Departure UTC Offset' : 'Arrival UTC Offset'),
          child: Row(
            children: [
              Icon(Icons.public, color: accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  etaOffsetLabel(current),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.expand_more, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }

    void _calculate() {
    if (!_form.currentState!.validate()) return;
    try {
      final start = portTimeToUtc(_departure, _departureOffset);
      if (_isEco) {
        final plan = EcoSpeedPlan.calculate(
          distance: _parse(_distance.text)!,
          ecoSpeed: _parse(_ecoSpeed.text)!,
          fullSpeed: _parse(_fullSpeed.text)!,
          departure: start,
          arrival: portTimeToUtc(_target, _arrivalOffset),
        );
        setState(() {
          _ecoResult = plan;
          _result = null;
          _error = null;
        });
        return;
      }
      final result = _required
          ? EtaResult.requiredSpeed(
              distanceNM: _parse(_distance.text)!,
              departureUTC: start,
              targetArrivalUTC: portTimeToUtc(_target, _arrivalOffset))
          : EtaResult.calculateEta(
              distanceNM: _parse(_distance.text)!,
              speedKnots: _parse(_speed.text)!,
              departureUTC: start);
      setState(() {
        _result = result;
        _ecoResult = null;
        _error = null;
      });
    } on FormatException catch (e) {
      setState(() {
        _result = null;
        _ecoResult = null;
        _error = e.message;
      });
    } on ArgumentError {
      setState(() {
        _result = null;
        _ecoResult = null;
        _error = 'Calculated date is outside the supported range.';
      });
    }
  }

  String _report(EtaResult r) {
    final localDeparture = utcToPortTime(r.departureUTC, _departureOffset);
    final localArrival = utcToPortTime(r.arrivalUTC, _arrivalOffset);
    final hours = r.duration.inMicroseconds / Duration.microsecondsPerHour;
    return 'ETA CALCULATOR\nMode: ${r.requiredSpeedMode ? 'Required Average Speed' : 'Calculate ETA'}\n'
        'Distance: ${r.distanceNM} NM\n'
        'Departure: ${etaDateTime(localDeparture)} ${etaOffsetLabel(_departureOffset)}\n'
        'Departure UTC: ${etaDateTime(r.departureUTC)}\n'
        '${r.requiredSpeedMode ? 'Target arrival' : 'ETA'}: ${etaDateTime(localArrival)} ${etaOffsetLabel(_arrivalOffset)}\n'
        'Arrival UTC: ${etaDateTime(r.arrivalUTC)}\n'
        'Time to go: ${etaDuration(r.duration)} (${hours.toStringAsFixed(8)} hours)\n'
        'Average speed over ground: ${r.averageSpeedKnots.toStringAsFixed(8)} kts\n'
        '${r.requiredSpeedMode ? 'Displayed required speed: ${r.requiredSpeedRounded.toStringAsFixed(2)} kts (rounded upward)\nFormula: ${r.distanceNM} / $hours = ${r.averageSpeedKnots} kts' : 'Formula: ${r.distanceNM} / ${r.averageSpeedKnots} = ${r.distanceNM / r.averageSpeedKnots} hours'}\n'
        'No stops or delays included. UTC offsets are entered manually and do not change automatically for DST.';
  }

  Future<void> _copy(EtaResult r) async {
    try {
      await Clipboard.setData(ClipboardData(text: _report(r)));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calculation copied.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not copy the calculation.')));
    }
  }

  Widget _resultCard(EtaResult r) {
    final localArrival = utcToPortTime(r.arrivalUTC, _arrivalOffset);
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            r.requiredSpeedMode ? 'REQUIRED SPEED' : 'ESTIMATED TIME OF ARRIVAL',
            style: const TextStyle(color: textMuted, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            r.requiredSpeedMode
                ? '${r.requiredSpeedRounded.toStringAsFixed(2)} kts'
                : etaDateTime(localArrival),
            style: TextStyle(color: accent, fontSize: 30, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            r.requiredSpeedMode
                ? 'Average speed over ground; rounded upward to 0.01 kt.'
                : etaOffsetLabel(_arrivalOffset),
            style: const TextStyle(color: textMuted),
          ),
          const SizedBox(height: 20),
          Text('Time to go: ${etaDuration(r.duration)}'),
          const SizedBox(height: 10),
          Text('Arrival UTC: ${etaDateTime(r.arrivalUTC)}'),
          if (r.requiredSpeedMode) ...[
            const SizedBox(height: 10),
            Text('Target arrival: ${etaDateTime(localArrival)} ${etaOffsetLabel(_arrivalOffset)}'),
            const SizedBox.shrink()
          ],
          const SizedBox(height: 16),
          Text(
            r.requiredSpeedMode
                ? 'Required speed = Distance / Available time'
                : 'Passage time = Distance / Average speed',
            style: const TextStyle(color: textMuted),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _copy(r),
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy Calculation'),
          ),
        ],
      ),
    );
  }

    Widget _ecoResultCard(EcoSpeedPlan p) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ECO / FULL SPEED PLAN', style: TextStyle(color: textMuted, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _ecoModeBlock('Eco Speed', p.ecoHours, p.ecoDistance, Icons.eco_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _ecoModeBlock('Full Speed', p.fullHours, p.fullDistance, Icons.speed)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Total: ${p.totalHours.toStringAsFixed(4)} h  •  ${(p.totalHours / 24).toStringAsFixed(4)} days'),
          const SizedBox(height: 8),
          Text('Target arrival: ${etaDateTime(_target)} ${etaOffsetLabel(_arrivalOffset)}'),
          const SizedBox(height: 12),
          const Text(
            'The result gives the total time in each mode. It does not prescribe which mode to use first.',
            style: TextStyle(color: textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _ecoModeBlock(String title, double hours, double distance, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text('${hours.toStringAsFixed(4)} h', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          Text('${(hours / 24).toStringAsFixed(4)} days', style: const TextStyle(color: textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Text('${distance.toStringAsFixed(2)} NM', style: const TextStyle(color: textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  @override
    Widget build(BuildContext context) => AppScaffold(
        title: 'ETA Calculator',
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                                                const Text('Passage Planning', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        const Text('Calculation Mode', style: TextStyle(color: textMuted, fontSize: 12, letterSpacing: 1)),
                        const SizedBox(height: 12),
                                                _ModeSelector(
                          selected: _mode,
                          onSelect: (v) {
                            setState(() {
                              _mode = v;
                              _invalidate();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _number(_distance, 'Distance / Remaining Distance (NM)'),
                        _dateField(true),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              final now = DateTime.now().toUtc();
                              final minute = DateTime.utc(now.year, now.month, now.day, now.hour, now.minute);
                              setState(() {
                                _departure = utcToPortTime(minute, _departureOffset);
                                _invalidate();
                              });
                            },
                            icon: const Icon(Icons.schedule),
                            label: const Text('Use Current Time'),
                          ),
                        ),
                                                const SizedBox(height: 12),
                        if (_isEco) ...[
                          _number(_ecoSpeed, 'Eco Speed (kts)'),
                          _number(_fullSpeed, 'Full Speed (kts)'),
                          _dateField(false),
                        ] else if (_required)
                          _dateField(false)
                        else
                          _number(_speed, 'Planned Speed (kts)'),
                        _card(
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            title: const Text('Port Time Zones'),
                            subtitle: Text(
                              'Departure: ${etaOffsetLabel(_departureOffset)} • Arrival: ${etaOffsetLabel(_arrivalOffset)}',
                              style: const TextStyle(color: textMuted),
                            ),
                            children: [
                              const SizedBox(height: 16),
                              _zone(true),
                              _zone(false),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Text(
                                  'Offsets apply to the entered port times. Set the offsets for the voyage dates; daylight-saving changes are not automatic.',
                                  style: TextStyle(color: textMuted, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _calculate,
                          icon: const Icon(Icons.calculate_outlined),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: bg,
                            padding: const EdgeInsets.all(20),
                          ),
                          label: Text(_isEco
                              ? 'Calculate Eco / Full Speed'
                              : _required
                                  ? 'Calculate Required Speed'
                                  : 'Calculate ETA'),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFFFFB4AB))),
                    ),
                                    if (_result != null) ...[
                    const SizedBox(height: 24),
                    _resultCard(_result!)
                  ],
                  if (_ecoResult != null) ...[
                    const SizedBox(height: 24),
                    _ecoResultCard(_ecoResult!)
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    'Use average speed over ground (SOG). No stops or delays are included.',
                    style: TextStyle(color: textMuted, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Сегментированный выбор режима расчёта — три карточки с иконками.
class _ModeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _ModeSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final items = <_ModeItem>[
      _ModeItem('eta', 'Calculate ETA', Icons.schedule),
      _ModeItem('speed', 'Required Speed', Icons.speed),
      _ModeItem('eco', 'Eco / Full', Icons.eco_outlined),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _ModeTile(
              item: items[i],
              active: selected == items[i].value,
              onTap: () => onSelect(items[i].value),
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeItem {
  final String value;
  final String label;
  final IconData icon;
  const _ModeItem(this.value, this.label, this.icon);
}

class _ModeTile extends StatelessWidget {
  final _ModeItem item;
  final bool active;
  final VoidCallback onTap;
  const _ModeTile({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: 0.14) : cardSolid,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? accent : border,
              width: active ? 1.5 : 1,
            ),
            boxShadow: active
                ? [BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 14, spreadRadius: 1)]
                : null,
          ),
          child: Column(
            children: [
              Icon(item.icon, color: active ? accent : textMuted, size: 26),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? accent : textMuted,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Нижняя панель выбора UTC-смещения — аккуратный список с выделением.
class _OffsetSheet extends StatefulWidget {
  final String title;
  final int selected;
  const _OffsetSheet({required this.title, required this.selected});

  @override
  State<_OffsetSheet> createState() => _OffsetSheetState();
}

class _OffsetSheetState extends State<_OffsetSheet> {
  late final ScrollController _controller;
  static const _step = 15;
  static const _min = -720;
  static const _max = 840;

  @override
  void initState() {
    super.initState();
    // Прокручиваем к текущему значению.
    final index = (widget.selected - _min) ~/ _step;
    _controller = ScrollController(initialScrollOffset: (index * 52.0) - 120);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = [for (var m = _min; m <= _max; m += _step) m];
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: BoxDecoration(
        color: cardSolid,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.public, color: accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Divider(color: border, height: 1),
          Flexible(
            child: ListView.builder(
              controller: _controller,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: values.length,
              itemBuilder: (context, i) {
                final v = values[i];
                final active = v == widget.selected;
                return InkWell(
                  onTap: () => Navigator.of(context).pop(v),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: active ? accent.withValues(alpha: 0.14) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? accent : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            etaOffsetLabel(v),
                            style: TextStyle(
                              color: active ? accent : text,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (active) Icon(Icons.check_circle, color: accent, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
