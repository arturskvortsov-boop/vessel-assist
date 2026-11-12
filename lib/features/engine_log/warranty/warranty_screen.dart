import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/models/warranty_claim.dart';

class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({super.key});

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> {
  final _box = Hive.box('warranty');

  void _addClaim() {
    final itemCtrl = TextEditingController();
    final makerCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String system = 'Main Engine';
    String status = 'Open';
    
    String dateFail = DateTime.now().toString().split(' ')[0];
    String expiry = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardSolid,
          title: const Text('Add Warranty Claim', style: TextStyle(color: text)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: itemCtrl, decoration: const InputDecoration(labelText: 'Item (What failed)')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: makerCtrl, decoration: const InputDecoration(labelText: 'Maker'))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: system,
                        dropdownColor: cardSolid,
                        decoration: const InputDecoration(labelText: 'System'),
                        items: const [
                          DropdownMenuItem(value: 'Main Engine', child: Text('Main Engine')),
                          DropdownMenuItem(value: 'Aux Engine', child: Text('Aux Engine')),
                          DropdownMenuItem(value: 'Boiler', child: Text('Boiler')),
                          DropdownMenuItem(value: 'Deck', child: Text('Deck')),
                          DropdownMenuItem(value: 'Electrical', child: Text('Electrical')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) => setDialogState(() => system = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description of Failure'), maxLines: 2),
                const SizedBox(height: 8),
                TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Ref No. (Service report)')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (picked != null) setDialogState(() => dateFail = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
                        },
                        child: InputDecorator(decoration: const InputDecoration(labelText: 'Date of Failure'), child: Text(dateFail, style: const TextStyle(color: text))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (picked != null) setDialogState(() => expiry = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
                        },
                        child: InputDecorator(decoration: const InputDecoration(labelText: 'Warranty Expiry'), child: Text(expiry.isEmpty ? 'Select Date' : expiry, style: TextStyle(color: expiry.isEmpty ? textMuted : text))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  dropdownColor: cardSolid,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'Open', child: Text('Open')),
                    DropdownMenuItem(value: 'Claimed', child: Text('Claimed')),
                    DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                    DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                  ],
                  onChanged: (val) => setDialogState(() => status = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (itemCtrl.text.isNotEmpty) {
                  final newClaim = WarrantyClaim(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    item: itemCtrl.text,
                    maker: makerCtrl.text,
                    system: system,
                    description: descCtrl.text,
                    dateFail: dateFail,
                    dateClaimed: DateTime.now().toString().split(' ')[0],
                    refNo: refCtrl.text,
                    expiry: expiry,
                    status: status,
                    notes: notesCtrl.text,
                  );
                  _box.put(newClaim.id, newClaim.toMap());
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

  int _getDaysLeft(String expiryDate) {
    if (expiryDate.isEmpty) return 999;
    try {
      final expiry = DateTime.parse(expiryDate);
      final now = DateTime.now();
      return expiry.difference(now).inDays;
    } catch (e) {
      return 999;
    }
  }

  @override
  Widget build(BuildContext context) {
        return AppScaffold(
      title: 'Warranty Claims',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Track defects under warranty. Red highlights mean expiry is in less than 30 days.',
                  style: TextStyle(color: textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _addClaim,
                  icon: const Icon(Icons.add),
                  label: const Text('ADD CLAIM'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (context, Box box, _) {
                final items = box.values.map((e) => WarrantyClaim.fromMap(e)).toList();
                if (items.isEmpty) return const Center(child: Text('No warranty claims.', style: TextStyle(color: textMuted)));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final daysLeft = _getDaysLeft(item.expiry);
                    final isUrgent = daysLeft < 30 && item.status != 'Resolved' && item.status != 'Rejected';
                    
                    Color statusColor = textMuted;
                    if (item.status == 'Resolved') statusColor = Colors.greenAccent;
                    if (item.status == 'Claimed') statusColor = Colors.orangeAccent;
                    if (item.status == 'Rejected') statusColor = Colors.redAccent;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardSolid,
                        border: Border.all(color: isUrgent ? Colors.redAccent : border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(item.item, style: const TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16))),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                onPressed: () => box.delete(item.id),
                              )
                            ],
                          ),
                          Text('${item.system} • ${item.maker}', style: const TextStyle(color: textMuted, fontSize: 12)),
                          const SizedBox(height: 8),
                          if (item.description.isNotEmpty) Text(item.description, style: const TextStyle(color: text, fontSize: 13)),
                          const Divider(color: border, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Status: ${item.status}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                              if (item.expiry.isNotEmpty)
                                Text(
                                  daysLeft >= 0 ? 'Expiry: ${item.expiry} ($daysLeft days)' : 'OVERDUE',
                                  style: TextStyle(color: isUrgent ? Colors.redAccent : textMuted, fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal, fontSize: 11),
                                ),
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