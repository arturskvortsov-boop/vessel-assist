import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/palette_state.dart';
import '../../../core/section_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/models/tank.dart';
import '../../../domain/calculators/vcf_calculator.dart';

class TanksScreen extends StatefulWidget {
  const TanksScreen({super.key});

  @override
  State<TanksScreen> createState() => _TanksScreenState();
}

class _TanksScreenState extends State<TanksScreen> {
  final _box = Hive.box('tanks');

  // Верхний уровень: fuel / lube / residue.
  String _group = 'fuel';
  // Подтип топлива: hfo / do.
  String _fuelType = 'hfo';

  bool get _isFuel => _group == 'fuel';

  /// Танки, отображаемые на текущей вкладке.
  List<Tank> _visibleTanks(List<Tank> all) {
    if (_group == 'fuel') {
      return all
          .where((t) => t.type == 'fuel' && (t.fuelType ?? 'hfo') == _fuelType)
          .toList();
    }
    if (_group == 'residue') {
      return all.where((t) => t.type == 'sludge' || t.type == 'bilge').toList();
    }
    return all.where((t) => t.type == _group).toList();
  }

  void _addTank() {
    final nameCtrl = TextEditingController();
    final capCtrl = TextEditingController();
    String selectedType = _group == 'residue' ? 'sludge' : _group;
    String selectedFuel = _fuelType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardSolid,
          title: const Text('Add New Tank', style: TextStyle(color: text)),
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
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  dropdownColor: cardSolid,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'fuel', child: Text('Fuel')),
                    DropdownMenuItem(value: 'lube', child: Text('Lube Oil')),
                    DropdownMenuItem(value: 'sludge', child: Text('Sludge')),
                    DropdownMenuItem(value: 'bilge', child: Text('Bilge')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                if (selectedType == 'fuel') ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedFuel,
                    dropdownColor: cardSolid,
                    decoration: const InputDecoration(labelText: 'Fuel Type'),
                    items: const [
                      DropdownMenuItem(value: 'hfo', child: Text('HFO (Heavy Fuel Oil)')),
                      DropdownMenuItem(value: 'do', child: Text('DO (Diesel Oil)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedFuel = val);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && capCtrl.text.isNotEmpty) {
                  final newTank = Tank(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text,
                    type: selectedType,
                    fuelType: selectedType == 'fuel' ? selectedFuel : null,
                    capacity: double.parse(capCtrl.text),
                  );
                  _box.put(newTank.id, newTank.toMap());
                  context.pop();
                  setState(() {});
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editTank(Tank tank) {
    final volCtrl = TextEditingController(text: tank.volume.toString());
    final densCtrl = TextEditingController(text: tank.density.toString());
    final tempCtrl = TextEditingController(text: tank.temp.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardSolid,
        title: Text(tank.name, style: const TextStyle(color: text)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: volCtrl,
                decoration: const InputDecoration(
                  labelText: 'Current Volume (m³)',
                  helperText: 'Actual liquid volume',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: densCtrl,
                decoration: const InputDecoration(
                  labelText: 'Density (t/m³)',
                  helperText: 'At 15°C (from BDN or lab)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tempCtrl,
                decoration: const InputDecoration(
                  labelText: 'Temperature (°C)',
                  helperText: 'Current cargo temp',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              tank.volume = double.tryParse(volCtrl.text) ?? tank.volume;
              tank.density = double.tryParse(densCtrl.text) ?? tank.density;
              tank.temp = double.tryParse(tempCtrl.text) ?? tank.temp;
              _box.put(tank.id, tank.toMap());
              context.pop();
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteTank(Tank tank) {
    _box.delete(tank.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    PaletteState.set(AppSection.engine);
    final palette = SectionTheme.of(context);
    final allData = _box.values.map((e) => Tank.fromMap(e)).toList();
    final tanks = _visibleTanks(allData);

    return AppScaffold(
      title: 'Tank Status',
      background: AppBackground.engineRoom,
      section: AppSection.engine,
      body: Column(
        children: [
          // --- ПОДСКАЗКА ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Enter Volume, Density, and Temp for each tank. The app automatically calculates mass (MT) and free space to 85%.',
              style: TextStyle(color: textMuted, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
          // --- ВКЛАДКИ ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _TankTabButton(
                    label: 'Fuel',
                    icon: Icons.local_gas_station,
                    isActive: _group == 'fuel',
                    onTap: () => setState(() => _group = 'fuel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TankTabButton(
                    label: 'Oil',
                    icon: Icons.opacity,
                    isActive: _group == 'lube',
                    onTap: () => setState(() => _group = 'lube'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TankTabButton(
                    label: 'Sludge/Bilge',
                    icon: Icons.water_drop,
                    isActive: _group == 'residue',
                    onTap: () => setState(() => _group = 'residue'),
                  ),
                ),
              ],
            ),
          ),
          // --- ПОД-ВКЛАДКИ HFO / DO (только для топлива) ---
          if (_isFuel)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _FuelSubTab(
                      label: 'HFO',
                      subtitle: 'Heavy Fuel Oil',
                      isActive: _fuelType == 'hfo',
                      onTap: () => setState(() => _fuelType = 'hfo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FuelSubTab(
                      label: 'DO',
                      subtitle: 'Diesel Oil',
                      isActive: _fuelType == 'do',
                      onTap: () => setState(() => _fuelType = 'do'),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _addTank,
              icon: const Icon(Icons.add),
              label: const Text('ADD TANK'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          Expanded(
            child: tanks.isEmpty
                ? const Center(
                    child: Text('No tanks yet.', style: TextStyle(color: textMuted)),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 760
                          ? 3
                          : constraints.maxWidth >= 480
                              ? 2
                              : 1;
                      const gap = 12.0;
                      final width =
                          (constraints.maxWidth - 32 - gap * (columns - 1)) / columns;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final t in tanks)
                              SizedBox(
                                width: width,
                                child: _TankCard(
                                  tank: t,
                                  accent: palette.accent,
                                  onEdit: () => _editTank(t),
                                  onDelete: () => _deleteTank(t),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Компактная карточка танка.
class _TankCard extends StatelessWidget {
  final Tank tank;
  final Color accent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TankCard({
    required this.tank,
    required this.accent,
    required this.onEdit,
    required this.onDelete,
  });

  String _lubeSubLabel(String? fuelType) => switch (fuelType) {
        'cylinder' => 'Cylinder Oil',
        'system' => 'System Oil',
        'dg' => 'DG Sump',
        _ => 'Lube Oil',
      };

  @override
  Widget build(BuildContext context) {
    final fillPercent = tank.capacity > 0
        ? (tank.volume / tank.capacity * 100).clamp(0.0, 100.0)
        : 0.0;
    final isFull = fillPercent >= 100;
    final isHigh = fillPercent >= 85;
    final color = isFull
        ? const Color(0xFFEF5350)
        : isHigh
            ? const Color(0xFFF59E0B)
            : accent;

    final gradient = isFull
        ? const [Color(0xFFEF5350), Color(0xFF991B1B)]
        : isHigh
            ? const [Color(0xFFFBBF24), Color(0xFFB45309)]
            : const [Color(0xFF31B6A5), Color(0xFF156D75)];

    final vcf = VcfCalculator.getVcf(tank.density);
    final vol15 = tank.volume - vcf * (tank.temp - 15);
    final mass = vol15 * tank.density;
    final freeTo85 = (tank.capacity * 0.85) - tank.volume;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardSolid,
        border: Border.all(color: isHigh ? color : border, width: isHigh ? 2 : 1),
        borderRadius: BorderRadius.circular(14),
      ),
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
                  style: const TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.edit, color: accent, size: 18),
                  onPressed: onEdit,
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${tank.volume.toStringAsFixed(1)} m³',
                style: const TextStyle(color: textMuted, fontSize: 12),
              ),
              Text(
                '${mass.toStringAsFixed(2)} MT',
                style: const TextStyle(
                  color: Color(0xFF4ADE80),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            tank.type == 'lube' && tank.fuelType != null
                ? '${_lubeSubLabel(tank.fuelType)} · ${tank.density} t/m³ · ${tank.temp} °C'
                : '${tank.density} t/m³ · ${tank.temp} °C',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: textMuted, fontSize: 11),
          ),
          const SizedBox(height: 10),

          // Вертикальный индикатор заполнения (как в Cargo Tanks).
          Container(
            height: 84,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: bg),
                  // Заливка по уровню.
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      widthFactor: 1,
                      heightFactor: (fillPercent / 100).clamp(0.0, 1.0),
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
                  // Линия лимита 85%.
                  Align(
                    alignment: const Alignment(0, 0.7), // 85% от низа
                    child: Container(
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  // Процент по центру.
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${fillPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isHigh ? color : text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (freeTo85 > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Free to 85%: ${freeTo85.toStringAsFixed(1)} m³ (~${(freeTo85 * tank.density).toStringAsFixed(1)} MT)',
                style: TextStyle(color: accent, fontSize: 11),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'No space to 85% limit',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Кнопка-вкладка верхнего уровня.
class _TankTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TankTabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = SectionTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? palette.accent.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(color: isActive ? palette.accent : border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isActive ? palette.accent : textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? palette.accent : textMuted,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Под-вкладка HFO / DO.
class _FuelSubTab extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const _FuelSubTab({
    required this.label,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = SectionTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? palette.accent.withValues(alpha: 0.12) : cardSolid,
          border: Border.all(color: isActive ? palette.accent : border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? palette.accent : text,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: textMuted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
