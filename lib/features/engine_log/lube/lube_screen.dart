import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_scaffold.dart';

class LubeScreen extends StatefulWidget {
  const LubeScreen({super.key});

  @override
  State<LubeScreen> createState() => _LubeScreenState();
}

class _LubeScreenState extends State<LubeScreen> {
  final _robBox = Hive.box('lube_rob');

  // Контроллеры для цилиндрового масла
  final _coPowerCtrl = TextEditingController();
  final _coRateCtrl = TextEditingController();
  final _coHoursCtrl = TextEditingController(text: '24');
  final _coDensCtrl = TextEditingController(text: '0.90');
  String _cylResult = '';

  // Контроллеры для доливки
  final _soCurrentCtrl = TextEditingController();
  final _soTargetCtrl = TextEditingController();
  String _sysResult = '';

  // Контроллеры для ROB
  final _newLubeTypeCtrl = TextEditingController();
  final _newLubeRobCtrl = TextEditingController();
  final _newLubeMinCtrl = TextEditingController();

  void _calcCyl() {
    final power = double.tryParse(_coPowerCtrl.text.replaceAll(',', '.')) ?? 0;
    final rate = double.tryParse(_coRateCtrl.text.replaceAll(',', '.')) ?? 0;
    final hours = double.tryParse(_coHoursCtrl.text.replaceAll(',', '.')) ?? 24;
    final dens = double.tryParse(_coDensCtrl.text.replaceAll(',', '.')) ?? 0.90;

    if (power <= 0 || rate <= 0) {
      setState(() => _cylResult = 'Enter valid Power and Rate');
      return;
    }

    final kgPerDay = (power * rate * hours) / 1000;
    final litersPerDay = kgPerDay / dens;

    setState(() {
      _cylResult = 'Total Consumption: ${kgPerDay.toStringAsFixed(2)} kg\n'
          'Approx. Volume: ${litersPerDay.toStringAsFixed(1)} Liters';
    });
  }

  void _calcSys() {
    final current = double.tryParse(_soCurrentCtrl.text.replaceAll(',', '.')) ?? 0;
    final target = double.tryParse(_soTargetCtrl.text.replaceAll(',', '.')) ?? 0;

    if (target <= current) {
      setState(() => _sysResult = 'Target must be greater than current');
      return;
    }

    final diff = target - current;
    setState(() {
      _sysResult = 'Required Top-Up: ${diff.toStringAsFixed(2)} m³';
    });
  }

  void _addRob() {
    if (_newLubeTypeCtrl.text.isEmpty) return;
    
    final rob = double.tryParse(_newLubeRobCtrl.text.replaceAll(',', '.')) ?? 0;
    final min = double.tryParse(_newLubeMinCtrl.text.replaceAll(',', '.')) ?? 0;
    
    // Сохраняем как Map: { "type": "Cylinder Oil", "rob": 10.5, "min": 2.0 }
    _robBox.put(_newLubeTypeCtrl.text, {'rob': rob, 'min': min});
    
    setState(() {
      _newLubeTypeCtrl.clear();
      _newLubeRobCtrl.clear();
      _newLubeMinCtrl.clear();
    });
  }

  void _editRob(String key, double currentRob, double currentMin) {
    final robCtrl = TextEditingController(text: currentRob.toString());
    final minCtrl = TextEditingController(text: currentMin.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardSolid,
        title: Text(key, style: const TextStyle(color: text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: robCtrl, decoration: const InputDecoration(labelText: 'New ROB (m³)'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: minCtrl, decoration: const InputDecoration(labelText: 'New Min ROB (m³)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newRob = double.tryParse(robCtrl.text.replaceAll(',', '.')) ?? currentRob;
              final newMin = double.tryParse(minCtrl.text.replaceAll(',', '.')) ?? currentMin;
              _robBox.put(key, {'rob': newRob, 'min': newMin});
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final robKeys = _robBox.keys.toList();

        return AppScaffold(
      title: 'Lube Oil',
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: accent,
              labelColor: accent,
              unselectedLabelColor: textMuted,
              tabs: [Tab(text: 'CALCULATORS'), Tab(text: 'ROB TRACKER')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCalculatorsTab(),
                  _buildRobTab(robKeys),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Калькулятор цилиндрового масла
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardSolid, border: Border.all(color: border), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cylinder Oil Feed Rate', style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Calculates daily consumption based on engine power (kW) and recommended feed rate (g/kWh).', style: TextStyle(color: textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _coPowerCtrl, decoration: const InputDecoration(labelText: 'Power (kW)'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _coRateCtrl, decoration: const InputDecoration(labelText: 'Rate (g/kWh)'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _coHoursCtrl, decoration: const InputDecoration(labelText: 'Hours'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _coDensCtrl, decoration: const InputDecoration(labelText: 'Density (kg/L)'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _calcCyl, child: const Text('CALCULATE')),
              if (_cylResult.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_cylResult, style: const TextStyle(color: Color(0xFF4ADE80), fontFamily: 'monospace')),
              ]
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Калькулятор доливки
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardSolid, border: Border.all(color: border), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('System Oil Top-Up', style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Calculates how much oil to add to reach the target level in the sump tank.', style: TextStyle(color: textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _soCurrentCtrl, decoration: const InputDecoration(labelText: 'Current Level (m³)'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _soTargetCtrl, decoration: const InputDecoration(labelText: 'Target Level (m³)'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _calcSys, child: const Text('CALCULATE')),
              if (_sysResult.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_sysResult, style: const TextStyle(color: Color(0xFF4ADE80), fontFamily: 'monospace')),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRobTab(List<dynamic> keys) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('Track remaining oil on board. Tap any item below to update its quantity.', style: TextStyle(color: textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              TextField(controller: _newLubeTypeCtrl, decoration: const InputDecoration(labelText: 'Oil Type (e.g. Cylinder Oil)')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _newLubeRobCtrl, decoration: const InputDecoration(labelText: 'Current ROB (m³)'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _newLubeMinCtrl, decoration: const InputDecoration(labelText: 'Min ROB (m³)'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _addRob,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('ADD / UPDATE ROB'),
              ),
            ],
          ),
        ),
        const Divider(color: border),
        Expanded(
          child: keys.isEmpty 
            ? const Center(child: Text('No data yet.', style: TextStyle(color: textMuted)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  final key = keys[index];
                  final data = _robBox.get(key);
                  final rob = (data['rob'] as num).toDouble();
                  final min = (data['min'] as num).toDouble();
                  final isLow = rob < min;

                  return InkWell(
                    onTap: () => _editRob(key.toString(), rob, min),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardSolid,
                        border: Border.all(color: isLow ? Colors.redAccent : border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(key.toString(), style: const TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('ROB: $rob m³  |  Min: $min m³', style: TextStyle(color: isLow ? Colors.redAccent : textMuted, fontWeight: isLow ? FontWeight.bold : FontWeight.normal)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.edit, color: accent, size: 20),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                onPressed: () {
                                  _robBox.delete(key);
                                  setState(() {});
                                },
                              ),
                            ]
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
        )
      ],
    );
  }
}