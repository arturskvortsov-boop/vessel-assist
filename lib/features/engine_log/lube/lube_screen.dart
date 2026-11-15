import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/palette_state.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/models/tank.dart';

class LubeScreen extends StatefulWidget {
  const LubeScreen({super.key});

  @override
  State<LubeScreen> createState() => _LubeScreenState();
}

class _LubeScreenState extends State<LubeScreen> {
  final _tanksBox = Hive.box('tanks');

  // Cylinder Oil Feed Rate.
  final _coPowerCtrl = TextEditingController();
  final _coRateCtrl = TextEditingController();
  final _coHoursCtrl = TextEditingController(text: '24');
  final _coDensCtrl = TextEditingController(text: '0.90');
  String? _coTankId;
  double? _coVolumeM3; // рассчитанный объём для списания
  String _cylResult = '';

  // System Oil Top-Up.
  final _soCurrentCtrl = TextEditingController();
  final _soTargetCtrl = TextEditingController();
  String? _soTankId;
  double? _soVolumeM3;
  String _sysResult = '';

  // DG Sump consumption.
  final _dgHoursCtrl = TextEditingController(text: '24');
  final _dgRateCtrl = TextEditingController();
  String? _dgTankId;
  double? _dgVolumeM3;
  String _dgResult = '';

  @override
  void dispose() {
    _coPowerCtrl.dispose();
    _coRateCtrl.dispose();
    _coHoursCtrl.dispose();
    _coDensCtrl.dispose();
    _soCurrentCtrl.dispose();
    _soTargetCtrl.dispose();
    _dgHoursCtrl.dispose();
    _dgRateCtrl.dispose();
    super.dispose();
  }

  double? _parse(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    return value != null && value.isFinite ? value : null;
  }

  /// Все масляные танки (type == 'lube').
  List<Tank> _lubeTanks() => _tanksBox.values
      .map((e) => Tank.fromMap(e))
      .where((t) => t.type == 'lube')
      .toList();

  /// DG Sump танки (lube + fuelType == 'dg').
  List<Tank> _dgTanks() => _lubeTanks().where((t) => t.fuelType == 'dg').toList();

  String _tankLabel(Tank t) {
    // Для DG-танков название уже задаётся пользователем (DG1 Sump Tk и т.д.),
    // поэтому суффикс не добавляем.
    final sub = switch (t.fuelType) {
      'cylinder' => ' · Cylinder',
      'system' => ' · System',
      _ => '',
    };
    return '${t.name}$sub (${t.volume.toStringAsFixed(1)} m³)';
  }

  /// Списывает объём (м³) с выбранного танка.
  void _applyConsumption(String? tankId, double? volumeM3) {
    if (tankId == null || volumeM3 == null || volumeM3 <= 0) {
      _notice('Select a tank and calculate first.');
      return;
    }
    final raw = _tanksBox.get(tankId);
    if (raw == null) {
      _notice('Tank not found.');
      return;
    }
    final tank = Tank.fromMap(raw);
    final newVolume = (tank.volume - volumeM3).clamp(0.0, tank.capacity);
    tank.volume = newVolume;
    _tanksBox.put(tank.id, tank.toMap());
    setState(() {});
    _notice(
      'Deducted ${volumeM3.toStringAsFixed(2)} m³ from ${tank.name}. '
      'New ROB: ${newVolume.toStringAsFixed(2)} m³.',
    );
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _calcCyl() {
    final power = _parse(_coPowerCtrl.text) ?? 0;
    final rate = _parse(_coRateCtrl.text) ?? 0;
    final hours = _parse(_coHoursCtrl.text) ?? 24;
    final dens = _parse(_coDensCtrl.text) ?? 0.90;

    if (power <= 0 || rate <= 0) {
      setState(() {
        _cylResult = 'Enter valid Power and Rate';
        _coVolumeM3 = null;
      });
      return;
    }

    final kgPerDay = (power * rate * hours) / 1000;
    final litersPerDay = kgPerDay / dens;
    final m3 = litersPerDay / 1000;

    setState(() {
      _coVolumeM3 = m3;
      _cylResult = 'Total Consumption: ${kgPerDay.toStringAsFixed(2)} kg\n'
          'Approx. Volume: ${litersPerDay.toStringAsFixed(1)} L '
          '(${m3.toStringAsFixed(3)} m³)';
    });
  }

  void _calcSys() {
    final current = _parse(_soCurrentCtrl.text) ?? 0;
    final target = _parse(_soTargetCtrl.text) ?? 0;

    if (target <= current) {
      setState(() {
        _sysResult = 'Target must be greater than current';
        _soVolumeM3 = null;
      });
      return;
    }

    final diff = target - current;
    setState(() {
      _soVolumeM3 = diff;
      _sysResult = 'Required Top-Up: ${diff.toStringAsFixed(2)} m³';
    });
  }

  void _calcDg() {
    final hours = _parse(_dgHoursCtrl.text) ?? 24;
    final rate = _parse(_dgRateCtrl.text) ?? 0; // L/h

    if (rate <= 0) {
      setState(() {
        _dgResult = 'Enter a valid consumption rate';
        _dgVolumeM3 = null;
      });
      return;
    }

    final liters = rate * hours;
    final m3 = liters / 1000;
    setState(() {
      _dgVolumeM3 = m3;
      _dgResult = 'Consumption: ${liters.toStringAsFixed(1)} L '
          '(${m3.toStringAsFixed(3)} m³)';
    });
  }

  // --- DG Sump Tanks management ---

  void _addDgTank() {
    final nameCtrl = TextEditingController();
    final capCtrl = TextEditingController();
    final volCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardSolid,
        title: const Text('Add DG Sump Tank', style: TextStyle(color: text)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tank Name',
                  hintText: 'e.g. DG1 Sump Tk',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: capCtrl,
                decoration: const InputDecoration(labelText: 'Capacity (m³)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: volCtrl,
                decoration: const InputDecoration(labelText: 'Current Volume (m³)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final cap = _parse(capCtrl.text) ?? 0;
              final vol = _parse(volCtrl.text) ?? 0;
              if (name.isEmpty || cap <= 0) return;
              final tank = Tank(
                id: 'dg_${DateTime.now().microsecondsSinceEpoch}',
                name: name,
                type: 'lube',
                fuelType: 'dg',
                capacity: cap,
                volume: vol.clamp(0.0, cap),
              );
              _tanksBox.put(tank.id, tank.toMap());
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editDgTank(Tank tank) {
    final nameCtrl = TextEditingController(text: tank.name);
    final capCtrl = TextEditingController(text: tank.capacity.toString());
    final volCtrl = TextEditingController(text: tank.volume.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardSolid,
        title: Text(tank.name, style: const TextStyle(color: text)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tank Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: capCtrl,
                decoration: const InputDecoration(labelText: 'Capacity (m³)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: volCtrl,
                decoration: const InputDecoration(labelText: 'Current Volume (m³)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final cap = _parse(capCtrl.text) ?? tank.capacity;
              final vol = _parse(volCtrl.text) ?? tank.volume;
              final updated = Tank(
                id: tank.id,
                name: nameCtrl.text.trim().isEmpty ? tank.name : nameCtrl.text.trim(),
                type: 'lube',
                fuelType: 'dg',
                capacity: cap,
                volume: vol.clamp(0.0, cap),
                density: tank.density,
                temp: tank.temp,
              );
              _tanksBox.put(updated.id, updated.toMap());
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteDgTank(Tank tank) {
    _tanksBox.delete(tank.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    PaletteState.set(AppSection.engine);
    return AppScaffold(
      title: 'Lube Oil',
      background: AppBackground.engineRoom,
      section: AppSection.engine,
      body: ValueListenableBuilder(
        valueListenable: _tanksBox.listenable(),
        builder: (context, _, _) {
          final lubeTanks = _lubeTanks();
          final dgTanks = _dgTanks();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _calcCard(
                title: 'Cylinder Oil Feed Rate',
                subtitle:
                    'Daily consumption from engine power (kW) and feed rate (g/kWh).',
                fields: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _coPowerCtrl,
                          decoration: const InputDecoration(labelText: 'Power (kW)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _coRateCtrl,
                          decoration: const InputDecoration(labelText: 'Rate (g/kWh)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _coHoursCtrl,
                          decoration: const InputDecoration(labelText: 'Hours'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _coDensCtrl,
                          decoration: const InputDecoration(labelText: 'Density (kg/L)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
                tankId: _coTankId,
                tanks: lubeTanks,
                onTankChanged: (id) => setState(() => _coTankId = id),
                onCalculate: _calcCyl,
                result: _cylResult,
                onApply: _coVolumeM3 == null
                    ? null
                    : () => _applyConsumption(_coTankId, _coVolumeM3),
              ),
              const SizedBox(height: 16),
              _calcCard(
                title: 'System Oil Top-Up',
                subtitle:
                    'Oil to add to reach the target level in the sump tank.',
                fields: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _soCurrentCtrl,
                          decoration: const InputDecoration(labelText: 'Current (m³)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _soTargetCtrl,
                          decoration: const InputDecoration(labelText: 'Target (m³)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
                tankId: _soTankId,
                tanks: lubeTanks,
                onTankChanged: (id) => setState(() => _soTankId = id),
                onCalculate: _calcSys,
                result: _sysResult,
                applyLabel: 'Add to tank',
                onApply: _soVolumeM3 == null
                    ? null
                    : () => _applyTopUp(_soTankId, _soVolumeM3),
              ),
              const SizedBox(height: 16),
              _calcCard(
                title: 'DG Sump Consumption',
                subtitle:
                    'Diesel generator lube oil consumption from rate (L/h) and hours.',
                fields: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dgRateCtrl,
                          decoration: const InputDecoration(labelText: 'Rate (L/h)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _dgHoursCtrl,
                          decoration: const InputDecoration(labelText: 'Hours'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
                tankId: _dgTankId,
                tanks: dgTanks.isEmpty ? lubeTanks : dgTanks,
                onTankChanged: (id) => setState(() => _dgTankId = id),
                onCalculate: _calcDg,
                result: _dgResult,
                onApply: _dgVolumeM3 == null
                    ? null
                    : () => _applyConsumption(_dgTankId, _dgVolumeM3),
              ),
              const SizedBox(height: 24),
              _dgTanksSection(dgTanks),
            ],
          );
        },
      ),
    );
  }

  /// Доливка масла в танк (увеличивает объём).
  void _applyTopUp(String? tankId, double? volumeM3) {
    if (tankId == null || volumeM3 == null || volumeM3 <= 0) {
      _notice('Select a tank and calculate first.');
      return;
    }
    final raw = _tanksBox.get(tankId);
    if (raw == null) {
      _notice('Tank not found.');
      return;
    }
    final tank = Tank.fromMap(raw);
    final newVolume = (tank.volume + volumeM3).clamp(0.0, tank.capacity);
    tank.volume = newVolume;
    _tanksBox.put(tank.id, tank.toMap());
    setState(() {});
    _notice(
      'Added ${volumeM3.toStringAsFixed(2)} m³ to ${tank.name}. '
      'New ROB: ${newVolume.toStringAsFixed(2)} m³.',
    );
  }

  Widget _calcCard({
    required String title,
    required String subtitle,
    required List<Widget> fields,
    required String? tankId,
    required List<Tank> tanks,
    required ValueChanged<String?> onTankChanged,
    required VoidCallback onCalculate,
    required String result,
    required VoidCallback? onApply,
    String applyLabel = 'Apply consumption',
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardSolid,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  color: textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          ...fields,
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: tanks.any((t) => t.id == tankId) ? tankId : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Deduct from tank'),
            items: [
              for (final t in tanks)
                DropdownMenuItem(
                  value: t.id,
                  child: Text(_tankLabel(t), overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: onTankChanged,
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onCalculate, child: const Text('CALCULATE')),
          if (result.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(result,
                style: const TextStyle(
                    color: Color(0xFF4ADE80), fontFamily: 'monospace')),
          ],
          if (onApply != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.remove_circle_outline, size: 18),
              label: Text(applyLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dgTanksSection(List<Tank> dgTanks) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardSolid,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, size: 18, color: accent),
              const SizedBox(width: 8),
              Text('DG Sump Tanks',
                  style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Add 3 or 4 DG sump tanks as fitted on your vessel. Volume only — density is not required.',
            style: TextStyle(color: textMuted, fontSize: 11, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          if (dgTanks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No DG sump tanks yet.',
                  style: TextStyle(color: textMuted)),
            )
          else
            for (final t in dgTanks)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name,
                              style: const TextStyle(
                                  color: text, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            '${t.volume.toStringAsFixed(1)} / ${t.capacity.toStringAsFixed(1)} m³',
                            style: const TextStyle(color: textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.edit, color: accent, size: 18),
                      onPressed: () => _editDgTank(t),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                      onPressed: () => _deleteDgTank(t),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addDgTank,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add DG Sump Tank'),
          ),
        ],
      ),
    );
  }
}
