import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/palette_state.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/models/note.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _box = Hive.box('notes');
  String _filter = 'All';

  void _addNote() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String category = 'General';
    bool isPinned = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardSolid,
          title: const Text('New Note', style: TextStyle(color: text)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 8),
                TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Note body'), maxLines: 4),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  dropdownColor: cardSolid,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'Inspector', child: Text('🔍 Inspector / PSC')),
                    DropdownMenuItem(value: 'Superintendent', child: Text('👔 Superintendent')),
                    DropdownMenuItem(value: 'Phone Prep', child: Text('📞 Phone Prep')),
                    DropdownMenuItem(value: 'Task', child: Text('✅ Task')),
                    DropdownMenuItem(value: 'General', child: Text('📝 General')),
                  ],
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
                SwitchListTile(
                  title: Text('Pin to top', style: TextStyle(color: accent, fontSize: 14)),
                  value: isPinned,
                  activeThumbColor: accent,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setDialogState(() => isPinned = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty || bodyCtrl.text.isNotEmpty) {
                  final n = Note(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleCtrl.text,
                    body: bodyCtrl.text,
                    category: category,
                    isPinned: isPinned,
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                  );
                  _box.put(n.id, n.toMap());
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

  String _getIcon(String category) {
    switch (category) {
      case 'Inspector': return '🔍';
      case 'Superintendent': return '👔';
      case 'Phone Prep': return '📞';
      case 'Task': return '✅';
      default: return '📝';
    }
  }

  @override
  Widget build(BuildContext context) {
    PaletteState.set(AppSection.engine);
        return AppScaffold(
      title: 'Notes',
      background: AppBackground.engineRoom,
      section: AppSection.engine,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filter,
                    dropdownColor: cardSolid,
                    decoration: const InputDecoration(labelText: 'Filter'),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Notes')),
                      DropdownMenuItem(value: 'Pinned', child: Text('📌 Pinned')),
                      DropdownMenuItem(value: 'Inspector', child: Text('🔍 Inspector')),
                      DropdownMenuItem(value: 'Superintendent', child: Text('👔 Superintendent')),
                      DropdownMenuItem(value: 'Phone Prep', child: Text('📞 Phone Prep')),
                      DropdownMenuItem(value: 'Task', child: Text('✅ Task')),
                      DropdownMenuItem(value: 'General', child: Text('📝 General')),
                    ],
                    onChanged: (val) => setState(() => _filter = val!),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addNote,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 56)),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (context, Box box, _) {
                var items = box.values.map((e) => Note.fromMap(e)).toList();

                if (_filter == 'Pinned') {
                  items = items.where((n) => n.isPinned).toList();
                } else if (_filter != 'All') {
                  items = items.where((n) => n.category == _filter).toList();
                }

                // Сначала закрепленные, потом по времени
                items.sort((a, b) {
                  if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
                  return b.timestamp.compareTo(a.timestamp);
                });

                if (items.isEmpty) return const Center(child: Text('No notes yet.', style: TextStyle(color: textMuted)));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final n = items[index];
                    final dateStr = DateTime.fromMillisecondsSinceEpoch(n.timestamp).toString().split(' ')[0];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardSolid,
                        border: Border.all(color: n.isPinned ? accent : border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${_getIcon(n.category)} ', style: const TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  n.title.isEmpty ? '(no title)' : n.title,
                                  style: const TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              if (n.isPinned) Icon(Icons.push_pin, color: accent, size: 16),
                            ],
                          ),
                          if (n.body.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(n.body, style: const TextStyle(color: textMuted, fontSize: 12, height: 1.4)),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${n.category} • $dateStr', style: const TextStyle(color: textMuted, fontSize: 10)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(n.isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: accent, size: 18),
                                    onPressed: () {
                                      n.isPinned = !n.isPinned;
                                      box.put(n.id, n.toMap());
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                    onPressed: () => box.delete(n.id),
                                  ),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
