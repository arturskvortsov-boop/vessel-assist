import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/utils/time_input_formatter.dart';

class ChangeoverScreen extends StatefulWidget {
  const ChangeoverScreen({super.key});

  @override
  State<ChangeoverScreen> createState() => _ChangeoverScreenState();
}

class _ChangeoverScreenState extends State<ChangeoverScreen> {
  final _historyBox = Hive.box('changeover_history');

  final _dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
  final _posCtrl = TextEditingController();
  final _sulfurCtrl = TextEditingController(text: '0.10');
  final _startTimeCtrl = TextEditingController();
  final _finishTimeCtrl = TextEditingController();
  final _viscStartCtrl = TextEditingController();
  final _viscEndCtrl = TextEditingController();
  final _tanksCtrl = TextEditingController();
  
  String _type = 'HFO/VLSFO to MGO/MDO';
  String _generatedText = '';
  
  // Настройки скруббера (EGCS)
  bool _hasScrubber = false;
  final _phCtrl = TextEditingController();
  final _pahCtrl = TextEditingController();
  final _turbidityCtrl = TextEditingController();

  void _generateText() {
    final date = _dateCtrl.text;
    final pos = _posCtrl.text.isEmpty ? 'N/A' : _posCtrl.text;
    final sulfur = _sulfurCtrl.text.replaceAll(',', '.');
    final start = _startTimeCtrl.text;
    final finish = _finishTimeCtrl.text;
    final vStart = _viscStartCtrl.text.replaceAll(',', '.');
    final vEnd = _viscEndCtrl.text.replaceAll(',', '.');
    final tanks = _tanksCtrl.text;

    if (start.isEmpty || finish.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter Start and Finish times.')));
      return;
    }

    String text = '$date at Position: $pos\n';
    text += 'Commenced fuel oil changeover from ${_type.split(' to ')[0]} to ${_type.split(' to ')[1]}.\n';
    text += 'Start Time: $start. Initial Viscosity: ${vStart.isEmpty ? "N/A" : vStart} cSt.\n';
    text += 'Completed fuel oil changeover at $finish.\n';
    text += 'Final Viscosity: ${vEnd.isEmpty ? "N/A" : vEnd} cSt. Sulfur content: max $sulfur% m/m.\n';
    text += 'Volume of low sulphur fuel oils in each tank at completion/commencement:\n${tanks.isEmpty ? "N/A" : tanks}\n';
    
    if (_hasScrubber) {
      final ph = _phCtrl.text.isEmpty ? "N/A" : _phCtrl.text;
      final pah = _pahCtrl.text.isEmpty ? "N/A" : _pahCtrl.text;
      final turb = _turbidityCtrl.text.isEmpty ? "N/A" : _turbidityCtrl.text;
      text += '\nEGCS (Scrubber) Data at changeover:\n';
      text += 'Wash water pH: $ph. PAH: $pah. Turbidity: $turb.\n';
      text += 'Scrubber operated in compliance with MEPC.340(77).\n';
    }
    
    text += 'Changeover procedure performed in accordance with vessel\'s approved changeover plan.';

    setState(() => _generatedText = text);
  }

  void _saveToHistory() {
    if (_generatedText.isEmpty) return;
    _historyBox.put(DateTime.now().millisecondsSinceEpoch.toString(), _generatedText);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to History!')));
  }

  @override
  Widget build(BuildContext context) {
        return AppScaffold(
      title: 'Fuel Changeover',
      background: AppBackground.engineRoom,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: accent, labelColor: accent, unselectedLabelColor: textMuted,
              tabs: [Tab(text: 'GENERATOR'), Tab(text: 'HISTORY')],
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
          'Generate a logbook entry for fuel oil changeover. Fill in the coordinates, times, and viscosity before/after.',
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
            Expanded(child: TextField(controller: _posCtrl, decoration: const InputDecoration(labelText: 'Position Lat/Long'))),
          ],
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: _type,
          dropdownColor: cardSolid,
          decoration: const InputDecoration(labelText: 'Type of Changeover'),
          items: const [
            DropdownMenuItem(value: 'HFO/VLSFO to MGO/MDO', child: Text('HFO/VLSFO to MGO/MDO')),
            DropdownMenuItem(value: 'MGO/MDO to HFO/VLSFO', child: Text('MGO/MDO to HFO/VLSFO')),
          ],
          onChanged: (val) => setState(() => _type = val!),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: TextField(controller: _startTimeCtrl, decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'), keyboardType: TextInputType.number, inputFormatters: [TimeInputFormatter()])),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _finishTimeCtrl, decoration: const InputDecoration(labelText: 'Finish Time (HH:MM)'), keyboardType: TextInputType.number, inputFormatters: [TimeInputFormatter()])),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: TextField(controller: _viscStartCtrl, decoration: const InputDecoration(labelText: 'Start Viscosity (cSt)'), keyboardType: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _viscEndCtrl, decoration: const InputDecoration(labelText: 'Finish Viscosity (cSt)'), keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 12),

        TextField(controller: _sulfurCtrl, decoration: const InputDecoration(labelText: 'Sulfur Target (%)'), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        TextField(
          controller: _tanksCtrl,
          decoration: const InputDecoration(
            labelText: 'LSFO Volume per Tank',
            hintText: 'e.g., No.1 HFO: 120 m³; No.2 MGO: 45 m³',
            helperText: 'MARPOL Reg. 14.6 requires volume in each tank at changeover completion/commencement.',
            helperMaxLines: 2,
          ),
          maxLines: 2,
        ),

        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Vessel equipped with Scrubber (EGCS)', style: TextStyle(color: accent, fontSize: 14)),
          subtitle: const Text('Check to add EGCS compliance data to the log', style: TextStyle(color: textMuted, fontSize: 11)),
          value: _hasScrubber,
          activeThumbColor: accent,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) => setState(() => _hasScrubber = val),
        ),

        if (_hasScrubber) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: _phCtrl, decoration: const InputDecoration(labelText: 'Wash Water pH'), keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _pahCtrl, decoration: const InputDecoration(labelText: 'PAH (ppm)'), keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _turbidityCtrl, decoration: const InputDecoration(labelText: 'Turbidity (NTU)'), keyboardType: TextInputType.number)),
            ],
          ),
        ],
        
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _generateText,
          child: const Text('GENERATE TEXT'),
        ),

        if (_generatedText.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardSolid, border: Border.all(color: accent), borderRadius: BorderRadius.circular(12)),
            child: Text(_generatedText, style: const TextStyle(color: Color(0xFF4ADE80), fontFamily: 'monospace', fontSize: 13)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _generatedText));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('COPY'),
                  style: ElevatedButton.styleFrom(backgroundColor: border, foregroundColor: text),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveToHistory,
                  icon: const Icon(Icons.save),
                  label: const Text('SAVE'),
                ),
              ),
            ],
          )
        ]
      ],
    );
  }

  Widget _buildHistory() {
    return ValueListenableBuilder(
      valueListenable: _historyBox.listenable(),
      builder: (context, Box box, _) {
        final keys = box.keys.toList().reversed;
        if (keys.isEmpty) return const Center(child: Text('No history yet.', style: TextStyle(color: textMuted)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: keys.length,
          itemBuilder: (context, index) {
            final key = keys.elementAt(index);
            final orderText = box.get(key) as String;
            
            return Card(
              color: cardSolid,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Record: ${DateTime.fromMillisecondsSinceEpoch(int.parse(key.toString())).toString().split(' ')[0]}', style: const TextStyle(color: accent, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                          onPressed: () => box.delete(key),
                        )
                      ],
                    ),
                    const Divider(color: border),
                    Text(orderText, style: const TextStyle(color: text, fontFamily: 'monospace', fontSize: 12)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: orderText));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('COPY'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 30), backgroundColor: border, foregroundColor: text),
                    )
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }
}