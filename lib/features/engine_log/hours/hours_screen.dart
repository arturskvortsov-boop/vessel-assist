import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../domain/models/engine_hour.dart';
import '../../../core/widgets/animated_counter.dart';
import '../../../core/widgets/app_scaffold.dart';

class HoursScreen extends StatefulWidget {
  const HoursScreen({super.key});

  @override
  State<HoursScreen> createState() => _HoursScreenState();
}

class _HoursScreenState extends State<HoursScreen> {
  final _box = Hive.box('engine_hours');

  void _addEquipment() {
    final nameCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '0');
    String group = 'Group 1';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardSolid,
          title: const Text('Add Equipment', style: TextStyle(color: text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Equipment Name (e.g. ME, AE #1)')),
              const SizedBox(height: 10),
              TextField(controller: hoursCtrl, decoration: const InputDecoration(labelText: 'Initial Hours'), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: group,
                dropdownColor: cardSolid,
                decoration: const InputDecoration(labelText: 'Group'),
                items: const [
                  DropdownMenuItem(value: 'Group 1', child: Text('Group 1')),
                  DropdownMenuItem(value: 'Group 2', child: Text('Group 2')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) => setDialogState(() => group = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final newEq = EngineHour(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text,
                    group: group,
                    currentHours: double.tryParse(hoursCtrl.text.replaceAll(',', '.')) ?? 0.0,
                    history: [],
                  );
                  _box.put(newEq.id, newEq.toMap());
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            )
          ],
        ),
      ),
    );
  }

  void _updateHours(EngineHour eq) {
    final newHoursCtrl = TextEditingController(text: eq.currentHours.toString());
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardSolid,
        title: Text('Update ${eq.name}', style: const TextStyle(color: text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current: ${eq.currentHours.toStringAsFixed(1)} h', style: const TextStyle(color: textMuted)),
            const SizedBox(height: 10),
            TextField(
              controller: newHoursCtrl, 
              decoration: const InputDecoration(labelText: 'New Total Hours'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newHours = double.tryParse(newHoursCtrl.text.replaceAll(',', '.')) ?? eq.currentHours;
              if (newHours >= eq.currentHours) {
                final today = DateTime.now().toString().split(' ')[0];
                final updatedHistory = List<Map<String, dynamic>>.from(eq.history);
                updatedHistory.add({'date': today, 'hours': newHours});
                
                final updatedEq = EngineHour(
                  id: eq.id,
                  name: eq.name,
                  group: eq.group,
                  currentHours: newHours,
                  history: updatedHistory,
                );
                
                _box.put(eq.id, updatedEq.toMap());
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New hours cannot be less than current!')));
              }
            },
            child: const Text('Update'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
        return AppScaffold(
      title: 'Engine Hours',
      background: AppBackground.engineRoom,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Track running hours of machinery. Tap "Update" to log new readings. The app calculates the difference automatically.',
                  style: TextStyle(color: textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addEquipment,
                  icon: const Icon(Icons.add),
                  label: const Text('ADD EQUIPMENT'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (context, Box box, _) {
                final items = box.values.map((e) => EngineHour.fromMap(e)).toList();
                if (items.isEmpty) return const Center(child: Text('No equipment added yet.', style: TextStyle(color: textMuted)));

                Map<String, List<EngineHour>> grouped = {};
                for (var item in items) {
                  if (!grouped.containsKey(item.group)) grouped[item.group] = [];
                  grouped[item.group]!.add(item);
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(entry.key, style: const TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: entry.value.map((eq) {
                            double delta = 0;
                            if (eq.history.length >= 2) {
                              delta = eq.history.last['hours'] - eq.history[eq.history.length - 2]['hours'];
                            } else if (eq.history.isNotEmpty) {
                              delta = eq.currentHours - (eq.history.first['hours'] ?? 0);
                            }

                            return SizedBox(
                              width: (MediaQuery.of(context).size.width - 44) / 2,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: cardSolid, border: Border.all(color: border), borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(eq.name, style: const TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                                          onPressed: () => _box.delete(eq.id),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    AnimatedCounter(
                                      value: eq.currentHours, 
                                      style: const TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'monospace'), 
                                      decimals: 1, 
                                      suffix: ' h'
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (delta > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                            child: Text('+${delta.toStringAsFixed(1)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                          )
                                        else
                                          const SizedBox(),
                                        ElevatedButton(
                                          onPressed: () => _updateHours(eq),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                            minimumSize: const Size(0, 24),
                                            backgroundColor: accent.withValues(alpha: 0.2), 
                                            foregroundColor: accent, 
                                            elevation: 0
                                          ),
                                          child: const Text('UPD', style: TextStyle(fontSize: 10)),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}