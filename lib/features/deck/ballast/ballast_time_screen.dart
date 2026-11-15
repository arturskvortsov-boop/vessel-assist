import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/palette_state.dart';
import '../../../core/widgets/app_scaffold.dart';

class BallastTimeScreen extends StatefulWidget {
  const BallastTimeScreen({super.key});
  @override
  State<BallastTimeScreen> createState() => _BallastTimeScreenState();
}

class _BallastTimeScreenState extends State<BallastTimeScreen> {
  final _form = GlobalKey<FormState>();
  final _volume = TextEditingController();
  final _rate = TextEditingController();
  late DateTime _start;
  DateTime? _finish;
  double? _exactMinutes;
  int? _roundedMinutes;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _start = DateTime.utc(now.year, now.month, now.day, now.hour, now.minute);
  }

  @override
  void dispose() {
    _volume.dispose();
    _rate.dispose();
    super.dispose();
  }

  double? _parse(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    return value != null && value.isFinite ? value : null;
  }

  void _clear() {
    setState(() {
      _finish = null;
      _exactMinutes = null;
      _roundedMinutes = null;
    });
  }

  String _two(int value) => value.toString().padLeft(2, '0');
  String _date(DateTime value) =>
      '${value.year}-${_two(value.month)}-${_two(value.day)}';
  String _time(DateTime value) => '${_two(value.hour)}:${_two(value.minute)}';

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(_start.year, _start.month, _start.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
      helpText: 'START DATE (UTC)',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _start.hour, minute: _start.minute),
      helpText: 'START TIME (UTC)',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      _start = DateTime.utc(date.year, date.month, date.day, time.hour, time.minute);
      _finish = null;
      _exactMinutes = null;
      _roundedMinutes = null;
    });
  }

  void _calculate() {
    if (!_form.currentState!.validate()) return;
    final minutes = _parse(_volume.text)! / _parse(_rate.text)! * 60;
    try {
      if (!minutes.isFinite || minutes > 1000000000) {
        throw const FormatException('Calculation range exceeded');
      }
      final rounded = minutes.round();
      final finish = _start.add(Duration(minutes: rounded));
      setState(() {
        _exactMinutes = minutes;
        _roundedMinutes = rounded;
        _finish = finish;
      });
    } catch (_) {
      _clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Values exceed the supported calculation range.'),
      ));
    }
  }

    Widget _field(TextEditingController controller, String label,
      String unit, {bool allowZero = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onChanged: (_) => _clear(),
        validator: (text) {
          final value = _parse(text ?? '');
          if (value == null) return 'Enter a finite number.';
          if (allowZero ? value < 0 : value <= 0) {
            return allowZero ? 'Value must be zero or greater.'
                : 'Value must be greater than zero.';
          }
          return null;
        },
      ),
    );
  }

  /// Карточка-секция с заголовком и иконкой.
  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

    @override
  Widget build(BuildContext context) {
    PaletteState.set(AppSection.bridge);
    final minutes = _roundedMinutes;
    final duration = minutes == null
        ? '—'
        : '${minutes ~/ 1440} d  ${_two((minutes % 1440) ~/ 60)} h  '
            '${_two(minutes % 60)} min';
    return AppScaffold(
      title: 'Ballast Time',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Заголовок.
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accent.withValues(alpha: 0.3)),
                      ),
                      child: Icon(Icons.water_outlined, color: accent, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ballast Time Calculator',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text('Estimated pumping duration and completion time.',
                              style: TextStyle(color: textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/deck/ballast_sequence', extra: _start),
                  icon: const Icon(Icons.format_list_numbered, size: 18),
                  label: const Text('Ballast Sequence'),
                ),
                const SizedBox(height: 16),

                // Ввод.
                Form(
                  key: _form,
                  child: _section('Input', Icons.edit_outlined, [
                    _field(_volume, 'Volume to Pump', 'm³', allowZero: true),
                    _field(_rate, 'Total Effective Pump Rate', 'm³/h'),
                    const Text('START DATE & TIME (UTC)',
                        style: TextStyle(color: textMuted, fontSize: 12, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickStart,
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: Text('${_date(_start)}  ${_time(_start)} UTC'),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _calculate,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: bg,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('Calculate'),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // Результат.
                _section('Result', Icons.timer_outlined, [
                  const Text('ESTIMATED DURATION',
                      style: TextStyle(color: textMuted, letterSpacing: 1.4, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(duration,
                      style: TextStyle(
                          color: accent, fontSize: 26, fontWeight: FontWeight.w700)),
                  if (_exactMinutes != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Calculated: ${_exactMinutes!.toStringAsFixed(2)} min. '
                      'Schedule rounded to the nearest minute.',
                      style: const TextStyle(color: textMuted, height: 1.5, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text('ESTIMATED COMPLETION (UTC)',
                      style: TextStyle(color: textMuted, letterSpacing: 1.4, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(
                    _finish == null
                        ? '—'
                        : '${_date(_finish!)}  ${_time(_finish!)} UTC',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Assumes a constant effective pump rate. '
                    'Include the combined effective rate when using multiple pumps. '
                    'Stripping, interruptions and changing flow are not included.',
                    style: TextStyle(color: textMuted, fontSize: 12, height: 1.5),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
