import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/palette_state.dart';
import '../../../core/widgets/app_scaffold.dart';

class NightOrdersScreen extends StatefulWidget {
  const NightOrdersScreen({super.key});

  @override
  State<NightOrdersScreen> createState() => _NightOrdersScreenState();
}

class _NightOrdersScreenState extends State<NightOrdersScreen> {
  final _historyBox = Hive.box('night_orders');
  
  final _dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
  final _posCtrl = TextEditingController();
  final _weatherCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();
  String _status = 'At Sea';
  
  String _generatedText = '';

  // Список стандартных приказов (редактируемый)
  final List<Map<String, dynamic>> _orders = [
    {'text': 'Monitor M/E parameters (Watch for abnormal noise, vibration, temperatures).', 'checked': true},
    {'text': 'Check A/E and generators (Load, temperatures, fuel/oil pressure).', 'checked': true},
    {'text': 'Monitor boiler water level and steam pressure.', 'checked': true},
    {'text': 'Check operation of purifiers and fuel viscosity.', 'checked': true},
    {'text': 'Monitor sludge tank levels and pump out if necessary.', 'checked': true},
    {'text': 'Maintain bilge levels and check for water ingress.', 'checked': true},
    {'text': 'Perform fire safety rounds.', 'checked': true},
  ];

  void _generateText() {
    String text = 'NIGHT ORDER\n';
    text += 'Date: ${_dateCtrl.text}\n';
    text += 'Position: ${_posCtrl.text.isEmpty ? "N/A" : _posCtrl.text}\n';
    text += 'Weather: ${_weatherCtrl.text.isEmpty ? "N/A" : _weatherCtrl.text}\n';
    text += 'Status: $_status\n\n';
    text += 'To the Duty Engineer:\n\n';
    text += 'Please pay special attention to the following during your watch:\n';

    for (var order in _orders) {
      if (order['checked']) {
        text += '- ${order['text']}\n';
      }
    }

    if (_extraCtrl.text.isNotEmpty) {
      text += '\nAdditional Instructions:\n${_extraCtrl.text}\n';
    }

    text += '\nIn case of any abnormalities or emergencies, call the Chief Engineer immediately.\n\n';
    text += 'Signed: Chief Engineer';

    setState(() {
      _generatedText = text;
    });
  }

  void _saveToHistory() {
    if (_generatedText.isEmpty) return;
    _historyBox.put(DateTime.now().millisecondsSinceEpoch.toString(), _generatedText);
    setState(() {}); // <--- Добавили принудительное обновление
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to History!')));
  }

  @override
  Widget build(BuildContext context) {
    PaletteState.set(AppSection.engine);
        return AppScaffold(
      title: 'Night Orders',
      background: AppBackground.engineRoom,
      section: AppSection.engine,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
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
          'Fill in the current conditions and select the orders for the duty engineer. The app will generate the text.',
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
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _status,
                dropdownColor: cardSolid,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'At Sea', child: Text('At Sea (В море)')),
                  DropdownMenuItem(value: 'At Anchor', child: Text('At Anchor (На якоре)')),
                  DropdownMenuItem(value: 'In Port', child: Text('In Port (В порту)')),
                ],
                onChanged: (val) => setState(() => _status = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(child: TextField(controller: _posCtrl, decoration: const InputDecoration(labelText: 'Position / Port'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _weatherCtrl, decoration: const InputDecoration(labelText: 'Weather'))),
          ],
        ),
        const SizedBox(height: 24),
        
        Text('Standard Orders:', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        ..._orders.asMap().entries.map((entry) {
          int idx = entry.key;
          var order = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: cardSolid, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
            child: CheckboxListTile(
              value: order['checked'],
              activeColor: accent,
              checkColor: bg,
              title: Text(order['text'], style: const TextStyle(color: text, fontSize: 13)),
              onChanged: (val) => setState(() => _orders[idx]['checked'] = val),
              secondary: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                onPressed: () => setState(() => _orders.removeAt(idx)),
              ),
            ),
          );
        }),
        
        TextButton.icon(
          onPressed: () {
            final ctrl = TextEditingController();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: cardSolid,
                title: const Text('Add Custom Order'),
                content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Order text')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () {
                      if (ctrl.text.isNotEmpty) {
                        setState(() => _orders.add({'text': ctrl.text, 'checked': true}));
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Add'),
                  )
                ],
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Custom Order'),
        ),

        const SizedBox(height: 16),
        TextField(
          controller: _extraCtrl, 
          decoration: const InputDecoration(labelText: 'Additional Instructions'), 
          maxLines: 3,
        ),
        
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _generateText,
          child: const Text('GENERATE NIGHT ORDER'),
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
    // ValueListenableBuilder автоматически обновляет экран, когда база меняется
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
                        Text('Order from: ${DateTime.fromMillisecondsSinceEpoch(int.parse(key.toString())).toString().split(' ')[0]}', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            box.delete(key); // Удаляем прямо из box
                          },
                        )
                      ],
                    ),
                    Divider(color: border),
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
