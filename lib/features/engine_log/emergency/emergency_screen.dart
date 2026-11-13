import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/section_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/models/emergency_contact.dart';
import '../../../domain/models/emergency_procedure.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _contactsBox = Hive.box('emergency_contacts');
  final _proceduresBox = Hive.box('emergency_procedures');

  @override
  void initState() {
    super.initState();
    // Если база процедур пуста, заполняем базовыми шаблонами и докладами по рации
    if (_proceduresBox.isEmpty) {
      _proceduresBox.addAll([
        {
          'id': '1',
          'title': '🔥 FIRE IN ENGINE ROOM',
          'steps': '1. Sound the general alarm.\n2. All emergency squad members arrived in engine room.\n3. Power in the fire zone disconnected.\n4. Stop M/E and generators (if safe).\n5. Activate fixed firefighting system after confirming no personnel.\n6. Close all doors, vents, and skylights.'
        },
        {
          'id': '2',
          'title': '⚡ BLACKOUT',
          'steps': '1. Check Emergency Generator started and connected.\n2. Notify Bridge.\n3. Investigate cause (overload, trip, fuel issue).\n4. Restore power step-by-step (avoid large loads immediately).'
        },
        {
          'id': '3',
          'title': '🌊 FLOODING',
          'steps': '1. General alarm.\n2. Locate the leak (sounding, visual).\n3. Start emergency bilge pump.\n4. Close watertight doors.\n5. Inform Master.'
        },
        {
          'id': '4',
          'title': '📻 RADIO: Fire in E/R (Доклад на мостик)',
          'steps': 'Bridge, Bridge, this is Engine Room.\nWe have a FIRE in [Location, e.g., Generator #2].\nEmergency squad is mustering.\nPower to the affected area is [ON/OFF].\nStanding by for your instructions. Over.'
        },
        {
          'id': '5',
          'title': '📻 RADIO: Flooding in E/R (Доклад на мостик)',
          'steps': 'Bridge, Bridge, this is Engine Room.\nWe have FLOODING in [Location].\nEmergency bilge pump is [READY/STARTED].\nWatertight doors are [CLOSED/OPEN].\nRequest instructions. Over.'
        },
        {
          'id': '6',
          'title': '📻 RADIO: Squad Muster (Внутренняя связь)',
          'steps': 'Emergency squad, Emergency squad, this is Chief Engineer.\nMuster at [Location, e.g., ECR].\nPrepare firefighting equipment / emergency pump.\nReport when ready. Over.'
        },
      ]);
    }
  }

  // Метод добавления новой процедуры/скрипта
  void _addProcedure() {
    final titleCtrl = TextEditingController();
    final stepsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardSolid,
        title: const Text('Add Procedure / Script', style: TextStyle(color: text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: stepsCtrl, decoration: const InputDecoration(labelText: 'Steps / Script'), maxLines: 6),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                final proc = EmergencyProcedure(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleCtrl.text,
                  steps: stepsCtrl.text,
                );
                _proceduresBox.put(proc.id, proc.toMap());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // Метод редактирования существующей процедуры
  void _editProcedure(EmergencyProcedure p) {
    final titleCtrl = TextEditingController(text: p.title);
    final stepsCtrl = TextEditingController(text: p.steps);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardSolid,
        title: const Text('Edit Procedure', style: TextStyle(color: text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: stepsCtrl, decoration: const InputDecoration(labelText: 'Steps / Script'), maxLines: 6),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                _proceduresBox.put(p.id, {
                  'id': p.id,
                  'title': titleCtrl.text,
                  'steps': stepsCtrl.text,
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _addContact() {
    final roleCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardSolid,
        title: const Text('Add Contact', style: TextStyle(color: text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role (e.g. Superintendent)')),
            const SizedBox(height: 8),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (roleCtrl.text.isNotEmpty) {
                final contact = EmergencyContact(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  role: roleCtrl.text,
                  name: nameCtrl.text,
                  phone: phoneCtrl.text,
                );
                _contactsBox.put(contact.id, contact.toMap());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
        return AppScaffold(
      title: 'Emergency',
      background: AppBackground.engineRoom,
      section: AppSection.engine,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: Colors.redAccent, labelColor: Colors.redAccent, unselectedLabelColor: textMuted,
              tabs: [Tab(text: 'PROCEDURES'), Tab(text: 'CONTACTS')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildProceduresTab(),
                  _buildContactsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProceduresTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Emergency procedures and internal radio scripts (E/R to Bridge or Squad). Tap to expand, edit, or add your own.', style: TextStyle(color: textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addProcedure,
                      icon: const Icon(Icons.add),
                      label: const Text('PROCEDURE'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50), backgroundColor: Colors.redAccent.withValues(alpha: 0.2), foregroundColor: Colors.redAccent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Быстрое создание пустого скрипта для рации
                        final newId = DateTime.now().millisecondsSinceEpoch.toString();
                        _proceduresBox.put(newId, {
                          'id': newId,
                          'title': '📻 RADIO: New E/R Report',
                          'steps': 'Bridge / Squad, this is [Name/Rank].\n[Your message, e.g., Main Engine stopped].\nOver.',
                        });
                      },
                      icon: const Icon(Icons.mic),
                      label: const Text('RADIO SCRIPT'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50), backgroundColor: accent.withValues(alpha: 0.2), foregroundColor: accent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: _proceduresBox.listenable(),
            builder: (context, Box box, _) {
              final procs = box.values.map((e) => EmergencyProcedure.fromMap(e)).toList();
              if (procs.isEmpty) return const Center(child: Text('No procedures.', style: TextStyle(color: textMuted)));

              // Разделяем на Дриллы и Радио-скрипты по иконке 📻
              final drills = procs.where((p) => !p.title.contains('📻 RADIO')).toList();
              final radioScripts = procs.where((p) => p.title.contains('📻 RADIO')).toList();

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (drills.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('DRILLS & PROCEDURES', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                    ...drills.map((p) => _buildProcCard(p, box)),
                  ],
                  if (radioScripts.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                      child: Text('RADIO SCRIPTS (E/R)', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                    ...radioScripts.map((p) => _buildProcCard(p, box)),
                  ]
                ],
              );
            },
          ),
        )
      ],
    );
  }

  // Вынесенная карточка процедуры
  Widget _buildProcCard(EmergencyProcedure p, Box box) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: cardSolid, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
      child: ExpansionTile(
        iconColor: Colors.redAccent,
        collapsedIconColor: textMuted,
        title: Text(p.title, style: const TextStyle(color: text, fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: border),
                Text(p.steps, style: const TextStyle(color: textMuted, height: 1.5)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: accent),
                      onPressed: () => _editProcedure(p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => box.delete(p.id),
                    ),
                  ]
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContactsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _addContact,
            icon: const Icon(Icons.person_add),
            label: const Text('ADD CONTACT'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: _contactsBox.listenable(),
            builder: (context, Box box, _) {
              final contacts = box.values.map((e) => EmergencyContact.fromMap(e)).toList();
              if (contacts.isEmpty) return const Center(child: Text('No contacts saved.', style: TextStyle(color: textMuted)));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final c = contacts[index];
                  return Card(
                    color: cardSolid,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.phone, color: Colors.greenAccent),
                      title: Text(c.role, style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                      subtitle: Text('${c.name}\n${c.phone}', style: const TextStyle(color: text)),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () => box.delete(c.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}
