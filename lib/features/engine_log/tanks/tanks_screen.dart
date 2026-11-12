import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
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
  String _currentGroup = 'fuel'; // По умолчанию открыто топливо

  Widget _buildTabBtn(String group, String label) {
    return _TankTabButton(
      label: label,
      isActive: _currentGroup == group,
      onTap: () => setState(() => _currentGroup = group),
    );
  }

  void _addTank() {
    final nameCtrl = TextEditingController();
    final capCtrl = TextEditingController();
    String selectedType = _currentGroup == 'residue' ? 'sludge' : _currentGroup; // Берем текущую вкладку как тип
    
    showDialog(
      context: context,

      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardSolid,
          title: const Text('Add New Tank', style: TextStyle(color: text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tank Name')),
              const SizedBox(height: 10),
              TextField(controller: capCtrl, decoration: const InputDecoration(labelText: 'Capacity (m³)'), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                dropdownColor: cardSolid,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'fuel', child: Text('Fuel (Топливо)')),
                  DropdownMenuItem(value: 'lube', child: Text('Lube Oil (Масло)')),
                  DropdownMenuItem(value: 'sludge', child: Text('Sludge (Шлам)')),
                  DropdownMenuItem(value: 'bilge', child: Text('Bilge (Льяла)')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedType = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && capCtrl.text.isNotEmpty) {
                  final newTank = Tank(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text,
                    type: selectedType, // Передаем выбранный тип
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
  } // <--- ВОТ ЭТА СКОБКА БЫЛА ПОТЕРЯНА

  void _editTank(Tank tank) {
    final volCtrl = TextEditingController(text: tank.volume.toString());
    final densCtrl = TextEditingController(text: tank.density.toString());
    final tempCtrl = TextEditingController(text: tank.temp.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardSolid,
        title: Text(tank.name, style: const TextStyle(color: text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: volCtrl, decoration: const InputDecoration(labelText: 'Current Volume (m³)', helperText: 'Actual liquid volume'), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: densCtrl, decoration: const InputDecoration(labelText: 'Density (t/m³)', helperText: 'At 15°C (from BDN or lab)'), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: tempCtrl, decoration: const InputDecoration(labelText: 'Temperature (°C)', helperText: 'Current cargo temp'), keyboardType: TextInputType.number),
          ],
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
    final allData = _box.values.toList();
    
    // Фильтруем танки по текущей вкладке
    final tanks = allData.map((e) => Tank.fromMap(e)).where((t) {
      if (_currentGroup == 'residue') return t.type == 'sludge' || t.type == 'bilge';
      return t.type == _currentGroup;
    }).toList();

        return AppScaffold(
      title: 'Tank Status',
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
          // --- ВКЛАДКИ (TABS) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(child: _buildTabBtn('fuel', '⛽ Fuel')),
                const SizedBox(width: 8),
                Expanded(child: _buildTabBtn('lube', '🧴 Lube')),
                const SizedBox(width: 8),
                Expanded(child: _buildTabBtn('residue', '🛢️ Sludge/Bilge')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _addTank,
              icon: const Icon(Icons.add),
              label: const Text('ADD TANK'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ),
          Expanded(
            child: tanks.isEmpty
                ? const Center(child: Text('No tanks yet.', style: TextStyle(color: textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tanks.length,
                    itemBuilder: (context, index) {
                      final t = tanks[index];
                      final fillPercent = (t.volume / t.capacity * 100).clamp(0, 100);
                      final isHigh = fillPercent >= 85;

                      final vcf = VcfCalculator.getVcf(t.density);
                      final vol15 = t.volume - vcf * (t.temp - 15);
                      final mass = vol15 * t.density;
                      final freeTo85 = (t.capacity * 0.85) - t.volume;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardSolid,
                          border: Border.all(color: isHigh ? Colors.redAccent : border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(t.name, style: const TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit, color: accent, size: 20), onPressed: () => _editTank(t)),
                                    IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => _deleteTank(t)),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Vol: ${t.volume.toStringAsFixed(1)} m³', style: const TextStyle(color: textMuted)),
                                Text('Mass: ${mass.toStringAsFixed(2)} MT', style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Density: ${t.density} t/m³  |  Temp: ${t.temp} °C', style: const TextStyle(color: textMuted, fontSize: 12)),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: fillPercent / 100,
                              backgroundColor: border,
                              color: isHigh ? Colors.redAccent : accent,
                              minHeight: 6,
                            ),
                            const SizedBox(height: 12),
                            if (freeTo85 > 0)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'Free to 85%: ${freeTo85.toStringAsFixed(1)} m³ (~${(freeTo85 * t.density).toStringAsFixed(1)} MT)',
                                  style: const TextStyle(color: accent, fontSize: 12),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  '⚠️ No space to 85% limit',
                                  style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              )
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
// --- Вспомогательный виджет для красивых кнопок-вкладок ---
class _TankTabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TankTabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? accent.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(color: isActive ? accent : border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? accent : textMuted,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}