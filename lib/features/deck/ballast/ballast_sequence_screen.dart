import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/palette_state.dart';
import '../../../core/widgets/app_scaffold.dart';

class BallastSequenceScreen extends StatefulWidget {
  const BallastSequenceScreen({super.key, required this.start});
  final DateTime start;

  @override
  State<BallastSequenceScreen> createState() => _BallastSequenceScreenState();
}

class _Operation {
  String name = '';
  String volume = '';
  String rate = '';
  bool parallel = false;
}

class _BallastSequenceScreenState extends State<BallastSequenceScreen> {
  final _form = GlobalKey<FormState>();
  final _operations = [_Operation()];
  List<({String name, DateTime start, DateTime finish})>? _schedule;
  DateTime? _finish;
  String? _error;

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  void _change(VoidCallback change) {
    setState(() {
      change();
      _schedule = null;
      _finish = null;
      _error = null;
    });
  }

  void _calculate() {
    if (!_form.currentState!.validate()) return;
    final schedule = <({String name, DateTime start, DateTime finish})>[];
    var stageStart = widget.start;
    var stageFinish = stageStart;
    for (final (index, operation) in _operations.indexed) {
      if (index > 0 && !operation.parallel) stageStart = stageFinish;
      final seconds =
          _number(operation.volume)! / _number(operation.rate)! * 3600;
      if (!seconds.isFinite || seconds > 60000000000) {
        setState(
          () =>
              _error = 'Operation ${index + 1} exceeds the calculation range.',
        );
        return;
      }
      final finish = stageStart.add(Duration(seconds: seconds.ceil()));
      if (finish.isAfter(stageFinish)) stageFinish = finish;
      schedule.add((
        name: operation.name.trim().isEmpty
            ? 'Operation ${index + 1}'
            : operation.name.trim(),
        start: stageStart,
        finish: finish,
      ));
    }
    setState(() {
      _schedule = schedule;
      _finish = stageFinish;
      _error = null;
    });
  }

  String _utc(DateTime value) =>
      '${value.toUtc().toIso8601String().replaceFirst('T', ' ').substring(0, 19)} UTC';

  Widget _numericField(
    String label,
    String unit,
    ValueChanged<String> onChanged,
  ) {
    return TextFormField(
      decoration: InputDecoration(labelText: label, suffixText: unit),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) => _change(() => onChanged(value)),
      validator: (value) {
        final number = _number(value ?? '');
        return number == null || !number.isFinite || number <= 0
            ? 'Enter a number greater than zero.'
            : null;
      },
    );
  }

    Widget _card({required Widget child, Color? borderColor}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardSolid,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor ?? border),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    PaletteState.set(AppSection.bridge);
    final schedule = _schedule;
    return AppScaffold(
      title: 'Ballast Sequence',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Инфо-карточка.
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 18, color: accent),
                          const SizedBox(width: 8),
                          Text(
                            'Plan start',
                            style: TextStyle(
                              color: accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _utc(widget.start),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Set the start time in Ballast Time. Parallel operations share a start time; '
                        'the next stage waits for all of them. Enter the effective rate for each '
                        'operation when running together. Use the ship’s approved sequence.',
                        style: TextStyle(color: textMuted, fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final (index, operation) in _operations.indexed) ...[
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Operation ${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (_operations.length > 1)
                              IconButton(
                                tooltip: 'Remove operation',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _change(() {
                                  final startsStage = !operation.parallel;
                                  _operations.removeAt(index);
                                  if (startsStage && index < _operations.length) {
                                    _operations[index].parallel = false;
                                  }
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Operation name (optional)',
                          ),
                          onChanged: (value) =>
                              _change(() => operation.name = value),
                        ),
                        const SizedBox(height: 12),
                        _numericField(
                          'Volume to pump',
                          'm³',
                          (value) => operation.volume = value,
                        ),
                        const SizedBox(height: 12),
                        _numericField(
                          'Effective pump rate',
                          'm³/h',
                          (value) => operation.rate = value,
                        ),
                        if (index > 0)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Start with previous operation'),
                            value: operation.parallel,
                            onChanged: (value) => _change(
                              () => operation.parallel = value ?? false,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _change(() => _operations.add(_Operation())),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add operation'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate_outlined),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: bg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  label: const Text('Calculate sequence'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                if (schedule != null) ...[
                  const SizedBox(height: 16),
                  _card(
                    borderColor: accent.withValues(alpha: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flag_outlined, size: 18, color: accent),
                            const SizedBox(width: 8),
                            Text(
                              'Plan finish',
                              style: TextStyle(
                                color: accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _utc(_finish!),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        for (final operation in schedule)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  operation.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_utc(operation.start)} → ${_utc(operation.finish)}',
                                  style: const TextStyle(color: textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}