import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/models/spare_part.dart';

class SparesScreen extends StatefulWidget {
  const SparesScreen({super.key});

  @override
  State<SparesScreen> createState() => _SparesScreenState();
}

class _SparesScreenState extends State<SparesScreen> {
  final _box = Hive.box('spares');
  String _filter = 'All';

  void _addItem() {
    final nameCtrl = TextEditingController();
    final makerCtrl = TextEditingController();
    final partCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final onBoardCtrl = TextEditingController(text: '0');
    final minCtrl = TextEditingController(text: '1');
    final orderedCtrl = TextEditingController(text: '0');
    String category = 'Spare';
    bool isCritical = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardSolid,
          title: const Text('Add Item', style: TextStyle(color: text)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name (e.g. Fuel Injector)')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: makerCtrl, decoration: const InputDecoration(labelText: 'Maker'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: partCtrl, decoration: const InputDecoration(labelText: 'Part No.'))),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location (e.g. Store 1, Shelf B)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  dropdownColor: cardSolid,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'Spare', child: Text('Spare')),
                    DropdownMenuItem(value: 'Store', child: Text('Store (Расходники)')),
                    DropdownMenuItem(value: 'Lube', child: Text('Lube (Масла)')),
                    DropdownMenuItem(value: 'Chemical', child: Text('Chemical (Химия)')),
                  ],
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: onBoardCtrl, decoration: const InputDecoration(labelText: 'On Board', isDense: true), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: minCtrl, decoration: const InputDecoration(labelText: 'Min Qty', isDense: true), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: orderedCtrl, decoration: const InputDecoration(labelText: 'Ordered Qty', isDense: true), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Critical Spare?', style: TextStyle(color: Colors.orangeAccent, fontSize: 14)),
                  value: isCritical,
                  activeThumbColor: Colors.orangeAccent,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setDialogState(() => isCritical = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final newItem = SparePart(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text,
                    maker: makerCtrl.text,
                    partNo: partCtrl.text,
                    location: locCtrl.text,
                    category: category,
                    onBoard: double.tryParse(onBoardCtrl.text.replaceAll(',', '.')) ?? 0,
                    minQty: double.tryParse(minCtrl.text.replaceAll(',', '.')) ?? 1,
                    ordered: double.tryParse(orderedCtrl.text.replaceAll(',', '.')) ?? 0,
                    isCritical: isCritical,
                  );
                  _box.put(newItem.id, newItem.toMap());
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

  void _editItem(SparePart item) {
    final onBoardCtrl = TextEditingController(text: item.onBoard.toString());
    final orderedCtrl = TextEditingController(text: item.ordered.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardSolid,
        title: Text(item.name, style: const TextStyle(color: text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: onBoardCtrl, decoration: const InputDecoration(labelText: 'Update On Board Qty'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: orderedCtrl, decoration: const InputDecoration(labelText: 'Update Ordered Qty'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              item.onBoard = double.tryParse(onBoardCtrl.text.replaceAll(',', '.')) ?? item.onBoard;
              item.ordered = double.tryParse(orderedCtrl.text.replaceAll(',', '.')) ?? item.ordered;
              _box.put(item.id, item.toMap());
              Navigator.pop(ctx);
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
      title: 'Spares & Stores',
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
                      DropdownMenuItem(value: 'All', child: Text('All Items')),
                      DropdownMenuItem(value: 'Below Min', child: Text('⚠️ Below Minimum')),
                      DropdownMenuItem(value: 'Critical', child: Text('★ Critical Only')),
                      DropdownMenuItem(value: 'Spare', child: Text('Spares')),
                      DropdownMenuItem(value: 'Store', child: Text('Stores')),
                      DropdownMenuItem(value: 'Lube', child: Text('Lubes')),
                    ],
                    onChanged: (val) => setState(() => _filter = val!),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addItem,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 56)),
                  child: const Icon(Icons.add),
                )
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (context, Box box, _) {
                var items = box.values.map((e) => SparePart.fromMap(e)).toList();

                // Фильтрация
                if (_filter == 'Below Min') {
                  items = items.where((i) => (i.onBoard + i.ordered) < i.minQty).toList();
                } else if (_filter == 'Critical') {
                  items = items.where((i) => i.isCritical).toList();
                } else if (_filter != 'All') {
                  items = items.where((i) => i.category == _filter).toList();
                }

                if (items.isEmpty) return const Center(child: Text('No items match this filter.', style: TextStyle(color: textMuted)));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isBelowMin = (item.onBoard + item.ordered) < item.minQty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: cardSolid,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isBelowMin ? Colors.redAccent : (item.isCritical ? Colors.orangeAccent : border)),
                      ),
                      child: ListTile(
                        onTap: () => _editItem(item),
                        title: Row(
                          children: [
                            Text(item.name, style: const TextStyle(color: text, fontWeight: FontWeight.bold)),
                            if (item.isCritical) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.star, color: Colors.orangeAccent, size: 16)),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item.category} • ${item.maker} • P/N: ${item.partNo}', style: const TextStyle(color: textMuted, fontSize: 11)),
                            Text('Loc: ${item.location}', style: const TextStyle(color: textMuted, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              'On Board: ${item.onBoard}  |  Min: ${item.minQty}  |  Ordered: ${item.ordered}',
                              style: TextStyle(color: isBelowMin ? Colors.redAccent : text, fontWeight: isBelowMin ? FontWeight.bold : FontWeight.normal, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                          onPressed: () => box.delete(item.id),
                        ),
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