import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/utils/time_input_formatter.dart';
import '../../../domain/models/egcs_record.dart';

class EgcsScreen extends StatefulWidget {
  const EgcsScreen({super.key});

  @override
  State<EgcsScreen> createState() => _EgcsScreenState();
}

class _EgcsScreenState extends State<EgcsScreen> {
  final _box = Hive.box('egcs_records');

  final _dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
  final _timeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _posCtrl = TextEditingController();
  final _officerCtrl = TextEditingController();
  String _eventType = 'Normal Operation';

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _timeCtrl.text = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  void _addRecord() {
    if (_descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a description.')));
      return;
    }

    final record = EgcsRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _dateCtrl.text,
      time: _timeCtrl.text,
      eventType: _eventType,
      description: _descCtrl.text,
      position: _posCtrl.text,
      officer: _officerCtrl.text,
    );

    _box.put(record.id, record.toMap());
    
    setState(() {
      _descCtrl.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EGCS Record Book'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: accent, labelColor: accent, unselectedLabelColor: textMuted,
              tabs: [Tab(text: 'NEW RECORD'), Tab(text: 'HISTORY')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildForm(),
                  _buildHistory(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Record daily operations, maintenance, or failures of the Exhaust Gas Cleaning System (Scrubber) per MEPC.340(77).',
          style: TextStyle(color: textMuted, fontSize: 12, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) setState(() => _dateCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
                },
                child: InputDecorator(decoration: const InputDecoration(labelText: 'Date'), child: Text(_dateCtrl.text, style: const TextStyle(color: text))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'Time (HH:MM)'), keyboardType: TextInputType.number, inputFormatters: [TimeInputFormatter()])),
          ],
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _eventType,
          dropdownColor: cardSolid,
          decoration: const InputDecoration(labelText: 'Event Type'),
          items: const [
            DropdownMenuItem(value: 'Normal Operation', child: Text('Normal Operation')),
            DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance / Repair')),
            DropdownMenuItem(value: 'Failure', child: Text('Failure / Breakdown')),
            DropdownMenuItem(value: 'Compliance Test', child: Text('Compliance Test (pH/PAH/Turbidity)')),
          ],
          onChanged: (val) => setState(() => _eventType = val!),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _descCtrl, 
          decoration: const InputDecoration(
            labelText: 'Description of Event',
            hintText: 'e.g., Wash water pump #1 failed. Switched to standby pump. Repaired at 14:30.',
          ), 
          maxLines: 3,
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: TextField(controller: _posCtrl, decoration: const InputDecoration(labelText: 'Position (Lat/Long)'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _officerCtrl, decoration: const InputDecoration(labelText: 'Officer on Watch'))),
          ],
        ),
        
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _addRecord,
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          child: const Text('SAVE RECORD'),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    return ValueListenableBuilder(
      valueListenable: _box.listenable(),
      builder: (context, Box box, _) {
        final recordsData = box.values.map((e) => EgcsRecord.fromMap(e)).toList();
        recordsData.sort((a, b) => b.id.compareTo(a.id)); // Новые сверху

        if (recordsData.isEmpty) return const Center(child: Text('No records yet.', style: TextStyle(color: textMuted)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recordsData.length,
          itemBuilder: (context, index) {
            final rec = recordsData[index];
            
            // Цвет для разных типов событий
            Color typeColor = Colors.greenAccent;
            if (rec.eventType == 'Failure / Breakdown') typeColor = Colors.redAccent;
            if (rec.eventType == 'Maintenance / Repair') typeColor = Colors.orangeAccent;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardSolid, border: Border.all(color: border), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${rec.date} ${rec.time}', style: const TextStyle(color: text, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(rec.eventType, style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(color: border, height: 20),
                  Text(rec.description, style: const TextStyle(color: text, fontSize: 13)),
                  const SizedBox(height: 8),
                  if (rec.position.isNotEmpty || rec.officer.isNotEmpty)
                    Text('Pos: ${rec.position} | Officer: ${rec.officer}', style: const TextStyle(color: textMuted, fontSize: 11)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      onPressed: () => box.delete(rec.id),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}