import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:excel/excel.dart' as xl;
import 'package:file_saver/file_saver.dart' as fs;
import '../../../core/theme.dart';
import '../../../core/palette_state.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/models/cargo_tank.dart';

class CargoTanksScreen extends StatefulWidget {
  const CargoTanksScreen({super.key});

  @override
  State<CargoTanksScreen> createState() => _CargoTanksScreenState();
}

class _CargoTanksScreenState extends State<CargoTanksScreen> {
  final _box = Hive.box('cargo_tanks');

  Future<void> _edit([CargoTank? tank]) async {
    final result = await showDialog<CargoTank>(
      context: context,
      builder: (_) => TankEditorDialog(tank: tank),
    );
    if (result == null || !mounted) return;
    _box.put(result.id, result.toMap());
  }

  Future<void> _delete(CargoTank tank) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardSolid,
        title: const Text('Delete tank?'),
        content: Text('Delete "${tank.name}" and its current inventory data?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete Tank')),
        ],
      ),
    );
    if (confirmed == true) {
      _box.delete(tank.id);
    }
  }

    Widget _tankCard(CargoTank tank) {
    final fill = tank.fillPercentage;
    final isFull = fill >= 100;
    final isHigh = fill > 85;
    // Цвет по порогам: обычный → высокий (>85%) → полный (100%).
    final tankColor = isFull
        ? const Color(0xFFEF5350)
        : isHigh
            ? const Color(0xFFF59E0B)
            : accent;
    final gradient = isFull
        ? const [Color(0xFFEF5350), Color(0xFF991B1B)]
        : isHigh
            ? const [Color(0xFFFBBF24), Color(0xFFB45309)]
            : const [Color(0xFF31B6A5), Color(0xFF156D75)];

    return Material(
      color: cardSolid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isHigh ? tankColor : border, width: isHigh ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tank.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: text),
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    tooltip: 'Tank settings',
                    iconSize: 18,
                    onSelected: (value) => value == 'edit' ? _edit(tank) : _delete(tank),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit Tank')),
                      PopupMenuItem(value: 'delete', child: Text('Delete Tank')),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              tank.fuelType,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: textMuted, fontSize: 12),
            ),
            const SizedBox(height: 10),

            // Компактный индикатор уровня.
            Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tankColor, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: bg),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        widthFactor: 1,
                        heightFactor: (fill / 100).clamp(0.0, 1.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: gradient,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          '${fill.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isHigh ? tankColor : text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            Text(
              '${tank.volumeM3.toStringAsFixed(2)} m³ on board',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text),
            ),
            const SizedBox(height: 2),
            Text(
              'Cap ${tank.capacityM3.toStringAsFixed(2)} m³ · ${tank.densityMtPerM3.toStringAsFixed(3)} MT/m³',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: textMuted, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Text(
              '${tank.massMT.toStringAsFixed(3)} MT',
              style: TextStyle(color: isHigh ? tankColor : accent, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: OutlinedButton.icon(
                onPressed: () => _edit(tank),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Update', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    PaletteState.set(AppSection.bridge);
        return AppScaffold(
      title: 'Cargo Tanks',
      body: ValueListenableBuilder(
        valueListenable: _box.listenable(),
        builder: (context, Box box, _) {
          final tanks = box.values.map((e) => CargoTank.fromMap(e as Map)).toList();
          final totalMass = tanks.fold<double>(0, (sum, tank) => sum + tank.massMT);
          final totalVolume = tanks.fold<double>(0, (sum, tank) => sum + tank.volumeM3);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _edit(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Tank'),
                            style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: bg, minimumSize: const Size(0, 50)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: tanks.isEmpty ? null : () => _exportExcel(tanks, totalMass, totalVolume),
                            icon: const Icon(Icons.download),
                            label: const Text('Export Excel'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Total Water on Board: ${totalMass.toStringAsFixed(2)} MT', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: text)),
                    Text('${tanks.length} tanks • ${totalVolume.toStringAsFixed(2)} m³', style: const TextStyle(color: textMuted)),
                    const SizedBox(height: 24),
                    
                    if (tanks.isEmpty)
                      const Padding(padding: EdgeInsets.all(32), child: Text('No tanks yet. Select Add Tank to create your first tank.', textAlign: TextAlign.center, style: TextStyle(color: textMuted)))
                    else
                                            LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 760
                              ? 3
                              : constraints.maxWidth >= 480
                                  ? 2
                                  : 1;
                          const gap = 12.0;
                          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final tank in tanks)
                                SizedBox(width: width, child: _tankCard(tank)),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportExcel(List<CargoTank> tanks, double totalMass, double totalVolume) async {
    try {
      final book = xl.Excel.createExcel();
      final sheet = book['Tanks'];
      book.setDefaultSheet('Tanks');
      book.delete('Sheet1');

      sheet.appendRow([
        xl.TextCellValue('Tank Name'), xl.TextCellValue('Contents'), xl.TextCellValue('Capacity (m³)'),
        xl.TextCellValue('Volume (m³)'), xl.TextCellValue('Density (MT/m³)'), xl.TextCellValue('Mass (MT)'),
        xl.TextCellValue('Filling (%)'), xl.TextCellValue('Last Updated')
      ]);

      for (final tank in tanks) {
        sheet.appendRow([
          xl.TextCellValue(tank.name), xl.TextCellValue(tank.fuelType), xl.DoubleCellValue(tank.capacityM3),
          xl.DoubleCellValue(tank.volumeM3), xl.DoubleCellValue(tank.densityMtPerM3), xl.DoubleCellValue(tank.massMT),
          xl.DoubleCellValue(tank.fillPercentage), xl.TextCellValue(tank.updatedAt)
        ]);
      }

      sheet.appendRow([
        xl.TextCellValue('TOTAL'), xl.TextCellValue(''), 
        xl.DoubleCellValue(tanks.fold(0, (s, t) => s + t.capacityM3)),
        xl.DoubleCellValue(totalVolume),
        xl.TextCellValue(''), xl.DoubleCellValue(totalMass),
        xl.TextCellValue(''), xl.TextCellValue('')
      ]);

      final bytes = book.encode();
      
      if (bytes == null) {
        throw StateError('Excel encoding failed');
      }
      
      final now = DateTime.now().toUtc();
      final name = 'cargo_tanks_${now.toIso8601String().split('T').first}';
      const mime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      
      // Используем только saveFile для всех платформ
      await fs.FileSaver.instance.saveFile(
        name: name, 
        bytes: Uint8List.fromList(bytes), 
        ext: 'xlsx', 
        mimeType: fs.MimeType.custom, 
        customMimeType: mime
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel file saved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }
}

class TankEditorDialog extends StatefulWidget {
  final CargoTank? tank;
  const TankEditorDialog({super.key, this.tank});

  @override
  State<TankEditorDialog> createState() => _TankEditorDialogState();
}

class _TankEditorDialogState extends State<TankEditorDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _type;
  late final TextEditingController _capacity;
  late final TextEditingController _volume;
  late final TextEditingController _density;

  @override
  void initState() {
    super.initState();
    final tank = widget.tank;
    _name = TextEditingController(text: tank?.name ?? '');
    _type = TextEditingController(text: tank?.fuelType ?? '');
    _capacity = TextEditingController(text: tank?.capacityM3.toString() ?? '');
    _volume = TextEditingController(text: tank?.volumeM3.toString() ?? '0');
    _density = TextEditingController(text: tank?.densityMtPerM3.toString() ?? '1.025');
  }

  @override
  void dispose() {
    _name.dispose(); _type.dispose(); _capacity.dispose(); _volume.dispose(); _density.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController controller, String label, String? Function(String?) validator, {bool numeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label, 
          errorMaxLines: 2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (_) => setState(() {}),
        validator: validator,
      ),
    );
  }

  String? _positive(String? text) {
    final val = double.tryParse((text ?? '').replaceAll(',', '.'));
    return val == null || val <= 0 ? 'Enter a valid number > 0' : null;
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final now = DateTime.now().toUtc();
    Navigator.pop(context, CargoTank(
      id: widget.tank?.id ?? 'cargo_${now.microsecondsSinceEpoch}',
      name: _name.text.trim(),
      fuelType: _type.text.trim(),
      capacityM3: double.tryParse(_capacity.text.replaceAll(',', '.')) ?? 0,
      volumeM3: double.tryParse(_volume.text.replaceAll(',', '.')) ?? 0,
      densityMtPerM3: double.tryParse(_density.text.replaceAll(',', '.')) ?? 1.025,
      updatedAt: now.toIso8601String(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final volume = double.tryParse(_volume.text.replaceAll(',', '.')) ?? 0;
    final density = double.tryParse(_density.text.replaceAll(',', '.')) ?? 0;
    final capacity = double.tryParse(_capacity.text.replaceAll(',', '.')) ?? 0;
    final mass = volume * density;
    final fill = capacity > 0 ? (volume / capacity * 100) : 0;

    return AlertDialog(
      backgroundColor: cardSolid,
      title: Text(widget.tank == null ? 'Add Cargo Tank' : 'Edit Cargo Tank'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_name, 'Tank Name', (v) => (v ?? '').isEmpty ? 'Required' : null),
                _field(_type, 'Contents (e.g. MGO, Ballast)', (v) => (v ?? '').isEmpty ? 'Required' : null),
                _field(_capacity, 'Capacity (m³)', _positive, numeric: true),
                _field(_volume, 'Current Volume (m³)', (v) {
                  final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (val == null || val < 0) return 'Enter valid volume';
                  if (val > capacity) return 'Exceeds capacity!';
                  return null;
                }, numeric: true),
                _field(_density, 'Density (MT/m³)', _positive, numeric: true),
                const SizedBox(height: 10),
                Text('Calculated Mass: ${mass.toStringAsFixed(3)} MT', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                Text('Filling: ${fill.toStringAsFixed(1)}%', style: const TextStyle(color: textMuted)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save Tank')),
      ],
    );
  }
}
