import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/section_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/models/punch_item.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final _checklistBox = Hive.box('delivery_checklist');
  final _punchBox = Hive.box('punch_list');

  @override
  void initState() {
    super.initState();
    if (_checklistBox.isEmpty) {
      _checklistBox.addAll([
        {'section': 'Dock Trial', 'text': 'Main Engine', 'checked': false, 'note': ''},
        {'section': 'Dock Trial', 'text': 'Aux Engines (1/2/3)', 'checked': false, 'note': ''},
        {'section': 'Dock Trial', 'text': 'Boiler', 'checked': false, 'note': ''},
        {'section': 'Dock Trial', 'text': 'Steering Gear', 'checked': false, 'note': ''},
        {'section': 'Dock Trial', 'text': 'Fire Pumps', 'checked': false, 'note': ''},
        {'section': 'Dock Trial', 'text': 'Emergency Generator', 'checked': false, 'note': ''},
        {'section': 'Dock Trial', 'text': 'Purifiers', 'checked': false, 'note': ''},
        {'section': 'Dock Trial', 'text': 'Incinerator', 'checked': false, 'note': ''},
        {'section': 'Dock Trial', 'text': 'Sewage Treatment', 'checked': false, 'note': ''},
        {'section': 'Dock Trial', 'text': 'Fresh Water Generator', 'checked': false, 'note': ''},
        {'section': 'Dock Trial', 'text': 'Bilge System', 'checked': false, 'note': ''},
        {'section': 'Dock Trial', 'text': 'Ballast System', 'checked': false, 'note': ''},
        {'section': 'Sea Trial', 'text': 'MCR Full Speed Run', 'checked': false, 'note': ''},
        {'section': 'Sea Trial', 'text': 'Fuel Consumption Measurement', 'checked': false, 'note': ''},
        {'section': 'Sea Trial', 'text': 'Manoeuvring Tests', 'checked': false, 'note': ''},
        {'section': 'Sea Trial', 'text': 'Anchoring Test', 'checked': false, 'note': ''},
        {'section': 'Sea Trial', 'text': 'Crash Stop', 'checked': false, 'note': ''},
        {'section': 'Sea Trial', 'text': 'Autopilot', 'checked': false, 'note': ''},
        {'section': 'Sea Trial', 'text': 'Steering Changeover', 'checked': false, 'note': ''},
        {'section': 'Sea Trial', 'text': 'Emergency Steering', 'checked': false, 'note': ''},
        {'section': 'Sea Trial', 'text': 'Blackout Recovery', 'checked': false, 'note': ''},
        {'section': 'Documents', 'text': 'IOPP Certificate', 'checked': false, 'note': ''},
        {'section': 'Documents', 'text': 'ORB', 'checked': false, 'note': ''},
        {'section': 'Documents', 'text': 'BWRB', 'checked': false, 'note': ''},
        {'section': 'Documents', 'text': 'Garbage Record Book', 'checked': false, 'note': ''},
        {'section': 'Documents', 'text': 'ISM (SMC + DOC)', 'checked': false, 'note': ''},
        {'section': 'Documents', 'text': 'ISPS Certificate', 'checked': false, 'note': ''},
        {'section': 'Documents', 'text': 'MLC Certificate', 'checked': false, 'note': ''},
        {'section': 'Documents', 'text': 'Class Certs (Hull/Machinery)', 'checked': false, 'note': ''},
        {'section': 'Documents', 'text': 'Load Line', 'checked': false, 'note': ''},
        {'section': 'Documents', 'text': 'Tonnage Certificate', 'checked': false, 'note': ''},
        {'section': 'Documents', 'text': 'Safety Equipment Certificate', 'checked': false, 'note': ''},
        {'section': 'Documents', 'text': 'IHM', 'checked': false, 'note': ''},
        {'section': 'Documents', 'text': 'CoF', 'checked': false, 'note': ''},
      ]);
    }
  }

  void _addChecklistItem() {
    final textCtrl = TextEditingController();
    String section = 'Dock Trial';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardSolid,
          title: const Text('Add Checklist Item', style: TextStyle(color: text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: textCtrl, decoration: const InputDecoration(labelText: 'Item description')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: section,
                dropdownColor: cardSolid,
                decoration: const InputDecoration(labelText: 'Section'),
                items: const [
                  DropdownMenuItem(value: 'Dock Trial', child: Text('Dock Trial')),
                  DropdownMenuItem(value: 'Sea Trial', child: Text('Sea Trial')),
                  DropdownMenuItem(value: 'Documents', child: Text('Documents')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) => setDialogState(() => section = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (textCtrl.text.isNotEmpty) {
                  _checklistBox.add({'section': section, 'text': textCtrl.text, 'checked': false, 'note': ''});
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

  void _addPunchItem() {
    final itemCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final respCtrl = TextEditingController();
    String severity = 'Minor';
    String status = 'Open';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardSolid,
          title: const Text('Add Defect', style: TextStyle(color: text)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: itemCtrl, decoration: const InputDecoration(labelText: 'Item (What)')),
                const SizedBox(height: 8),
                TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location (Where)')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: severity,
                        dropdownColor: cardSolid,
                        decoration: const InputDecoration(labelText: 'Severity'),
                        items: const [
                          DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                          DropdownMenuItem(value: 'Major', child: Text('Major')),
                          DropdownMenuItem(value: 'Minor', child: Text('Minor')),
                        ],
                        onChanged: (val) => setDialogState(() => severity = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        dropdownColor: cardSolid,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'Open', child: Text('Open')),
                          DropdownMenuItem(value: 'Fixed', child: Text('Fixed')),
                          DropdownMenuItem(value: 'Accepted', child: Text('Accepted')),
                        ],
                        onChanged: (val) => setDialogState(() => status = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: respCtrl, decoration: const InputDecoration(labelText: 'Responsible (Who fixes)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (itemCtrl.text.isNotEmpty) {
                  final p = PunchItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    item: itemCtrl.text,
                    location: locCtrl.text,
                    description: descCtrl.text,
                    severity: severity,
                    status: status,
                    responsible: respCtrl.text,
                  );
                  _punchBox.put(p.id, p.toMap());
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
        return AppScaffold(
      title: 'Delivery & Acceptance',
      background: AppBackground.engineRoom,
      section: AppSection.engine,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              indicatorColor: accent, labelColor: accent, unselectedLabelColor: textMuted,
              tabs: [Tab(text: 'CHECKLIST'), Tab(text: 'PUNCH LIST')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildChecklistTab(),
                  _buildPunchListTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistTab() {
    return ValueListenableBuilder(
      valueListenable: _checklistBox.listenable(),
      builder: (context, Box box, _) {
        final items = box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        final sections = ['Dock Trial', 'Sea Trial', 'Documents', 'Other'];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tick completed items and add comments if needed.', style: TextStyle(color: textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _addChecklistItem,
                    icon: const Icon(Icons.add),
                    label: const Text('ADD ITEM'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: sections.map((section) {
                  final sectionItems = items.where((i) => i['section'] == section).toList();
                  if (sectionItems.isEmpty) return const SizedBox.shrink();
                  
                  final done = sectionItems.where((i) => i['checked'] == true).length;

                  return ExpansionTile(
                    key: ValueKey(section), // Стабильный ключ
                    maintainState: true, // Не сбрасывать состояние
                    initiallyExpanded: false, // Закрыты по умолчанию
                    title: Text('$section ($done/${sectionItems.length})', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                    children: sectionItems.map((item) {
                      final itemKey = box.keys.firstWhere((k) => box.get(k)['text'] == item['text'] && box.get(k)['section'] == section);
                      return _ChecklistRow(
                        key: ValueKey(itemKey.toString()), // Стабильный ключ для строки
                        itemKey: itemKey,
                        item: item,
                        box: box,
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPunchListTab() {
    return ValueListenableBuilder(
      valueListenable: _punchBox.listenable(),
      builder: (context, Box box, _) {
        final items = box.values.map((e) => PunchItem.fromMap(e)).toList();
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Record all defects found during acceptance. Critical items must be fixed before delivery.', style: TextStyle(color: textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _addPunchItem,
                    icon: const Icon(Icons.add),
                    label: const Text('ADD DEFECT'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.redAccent.withValues(alpha: 0.2), foregroundColor: Colors.redAccent),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty 
                ? const Center(child: Text('No defects recorded.', style: TextStyle(color: textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final p = items[index];
                      Color sevColor = textMuted;
                      if (p.severity == 'Critical') sevColor = Colors.redAccent;
                      if (p.severity == 'Major') sevColor = Colors.orangeAccent;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardSolid, 
                          border: Border.all(color: p.severity == 'Critical' ? Colors.redAccent : border), 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(p.item, style: const TextStyle(color: text, fontWeight: FontWeight.bold))),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                  onPressed: () => box.delete(p.id),
                                )
                              ],
                            ),
                            Text('${p.location} • ${p.responsible}', style: const TextStyle(color: textMuted, fontSize: 11)),
                            if (p.description.isNotEmpty) Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(p.description, style: const TextStyle(color: text, fontSize: 12)),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: sevColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text(p.severity, style: TextStyle(color: sevColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Text(p.status, style: const TextStyle(color: textMuted, fontSize: 11)),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
            )
          ],
        );
      },
    );
  }
}

// --- ВИДЖЕТ СТРОКИ С КОММЕНТАРИЕМ ---
class _ChecklistRow extends StatefulWidget {
  final dynamic itemKey;
  final Map<String, dynamic> item;
  final Box box;

  const _ChecklistRow({super.key, required this.itemKey, required this.item, required this.box});

  @override
  State<_ChecklistRow> createState() => _ChecklistRowState();
}

class _ChecklistRowState extends State<_ChecklistRow> {
  late TextEditingController _noteCtrl;
  bool _showNote = false;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.item['note'] ?? '');
    _showNote = (widget.item['note'] ?? '').isNotEmpty;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _updateBox({bool? checked, String? note}) {
    final current = Map<String, dynamic>.from(widget.box.get(widget.itemKey));
    if (checked != null) current['checked'] = checked;
    if (note != null) current['note'] = note;
    widget.box.put(widget.itemKey, current);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CheckboxListTile(
          value: widget.item['checked'] ?? false,
          activeColor: accent,
          checkColor: bg,
          title: Text(
            widget.item['text'] ?? '',
            style: TextStyle(
              color: widget.item['checked'] == true ? textMuted : text,
              decoration: widget.item['checked'] == true ? TextDecoration.lineThrough : null,
              fontSize: 13,
            ),
          ),
          onChanged: (val) => _updateBox(checked: val),
          secondary: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _showNote ? Icons.comment : Icons.comment_outlined,
                  color: _showNote ? accent : textMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _showNote = !_showNote),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                onPressed: () => widget.box.delete(widget.itemKey),
              ),
            ],
          ),
        ),
        if (_showNote)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note / Comment',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 12, color: text),
              onChanged: (val) => _updateBox(note: val),
              autofocus: true,
            ),
          ),
      ],
    );
  }
}
