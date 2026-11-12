import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'unit_converter_model.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  final _input = TextEditingController();
  String _category = unitCategories.keys.first;
  int _from = 0;
  int _to = 1;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String _format(double value) {
    if (value == 0) return '0';
    final parts = value.toStringAsPrecision(12).split('e');
    final number = parts.first.contains('.')
        ? parts.first.replaceFirst(RegExp(r'\.?0+$'), '')
        : parts.first;
    return parts.length == 2 ? '${number}e${parts.last}' : number;
  }

  Widget _unitField(
    String label,
    List<Unit> units,
    int selected,
    ValueChanged<int> change,
  ) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          isDense: true,
          value: selected,
          items: [
            for (final (index, unit) in units.indexed)
              DropdownMenuItem(
                value: index,
                child: Text(unit.label, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => change(value));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final units = unitCategories[_category]!;
    final input = _input.text.trim();
    final value = double.tryParse(input.replaceAll(',', '.'));
    final converted = value != null && value.isFinite
        ? units[_from].convertTo(value, units[_to])
        : null;
    final result = converted != null && converted.isFinite
        ? _format(converted)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Unit Converter')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Quantity'),
                items: [
                  for (final category in unitCategories.keys)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (category) {
                  if (category == null) return;
                  setState(() {
                    _category = category;
                    _from = 0;
                    _to = 1;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _input,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Value',
                  errorText:
                      input.isNotEmpty && (value == null || !value.isFinite)
                      ? 'Enter a finite number.'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _unitField('From', units, _from, (value) => _from = value),
              Center(
                child: IconButton(
                  tooltip: 'Swap units',
                  onPressed: () => setState(() {
                    final previousFrom = _from;
                    _from = _to;
                    _to = previousFrom;
                  }),
                  icon: const Icon(Icons.swap_vert),
                ),
              ),
              _unitField('To', units, _to, (value) => _to = value),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: SelectableText(
                    result ?? (converted == null ? '—' : 'Result out of range'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  subtitle: Text(units[_to].label),
                  trailing: IconButton(
                    tooltip: 'Copy result',
                    onPressed: result == null
                        ? null
                        : () async {
                            await Clipboard.setData(
                              ClipboardData(text: result),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Result copied')),
                              );
                            }
                          },
                    icon: const Icon(Icons.copy_outlined),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
