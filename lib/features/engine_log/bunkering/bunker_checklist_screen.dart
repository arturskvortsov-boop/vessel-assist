import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/signature_pad.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

class BunkerChecklistScreen extends StatefulWidget {
  const BunkerChecklistScreen({super.key});

  @override
  State<BunkerChecklistScreen> createState() => _BunkerChecklistScreenState();
}

class _BunkerChecklistScreenState extends State<BunkerChecklistScreen> {
  final _box = Hive.box('bunker_checklists');
  Uint8List? _signatureBytes; // Здесь храним картинку подписи

  @override
  Widget build(BuildContext context) {
        return AppScaffold(
      title: 'Bunkering Checklists',
      actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orangeAccent),
            tooltip: 'Reset for New Bunkering',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: cardSolid,
                  title: const Text('Reset Checklists?'),
                  content: const Text('This will uncheck all items. Your custom items will be kept.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        for (var i = 0; i < _box.length; i++) {
                          final key = _box.keyAt(i);
                          final list = List<Map>.from(_box.get(key) ?? []);
                          for (var item in list) {
                            item['checked'] = false;
                          }
                          _box.put(key, list);
                        }
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
                        },
          ),
        ],
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: accent,
              labelColor: accent,
              unselectedLabelColor: textMuted,
              isScrollable: true,
              tabs: [
                Tab(text: 'BEFORE'),
                Tab(text: 'DURING'),
                Tab(text: 'AFTER'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTab('before'),
                  _buildTab('during'),
                  _buildTab('after'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String tabKey) {
    // Инициализация, если базы нет
    if (!_box.containsKey(tabKey)) {
      _box.put(tabKey, _getDefaultItems(tabKey));
    }

    final List<Map> items = List<Map>.from(_box.get(tabKey) ?? []);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cardSolid,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: item['checked'] ? accent : border),
                ),
                child: ListTile(
                  leading: Checkbox(
                    value: item['checked'] ?? false,
                    activeColor: accent,
                    checkColor: bg,
                    onChanged: (val) {
                      item['checked'] = val;
                      _box.put(tabKey, items);
                      setState(() {});
                    },
                  ),
                  title: Text(
                    item['text'],
                    style: TextStyle(
                      color: item['checked'] ? textMuted : text,
                      decoration: item['checked'] ? TextDecoration.lineThrough : null,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: accent, size: 20),
                        onPressed: () => _editItem(tabKey, items, index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          items.removeAt(index);
                          _box.put(tabKey, items);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton.icon(
            onPressed: () => _addItem(tabKey, items),
            icon: const Icon(Icons.add),
            label: const Text('ADD CUSTOM ITEM'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: border, foregroundColor: text),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignatureScreen()),
                    );
                    if (result != null) {
                      setState(() => _signatureBytes = result as Uint8List);
                    }
                  },
                  icon: const Icon(Icons.draw),
                  label: const Text('SIGN'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50), backgroundColor: Colors.orangeAccent, foregroundColor: bg),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _exportPdf(tabKey, items),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('EXPORT PDF'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  void _addItem(String tabKey, List<Map> items) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardSolid,
        title: const Text('Add Item'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Item description'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                items.add({'text': ctrl.text, 'checked': false});
                _box.put(tabKey, items);
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  void _editItem(String tabKey, List<Map> items, int index) {
    final ctrl = TextEditingController(text: items[index]['text']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardSolid,
        title: const Text('Edit Item'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Item description'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                items[index]['text'] = ctrl.text;
                _box.put(tabKey, items);
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getDefaultItems(String tab) {
    if (tab == 'before') {
      return [
        {'text': 'Has the bunker loading plan been agreed, drawn up and posted?', 'checked': false},
        {'text': 'Has the bunker plan been seen and signed by all crewmembers involved?', 'checked': false},
        {'text': 'Has the identification and 85% capacity of tanks receiving oil been stated?', 'checked': false},
        {'text': 'Has "No smoking" sign been displayed in conspicuous place?', 'checked': false},
        {'text': 'Is the involved personnel aware of their duties as per bunkering plan?', 'checked': false},
        {'text': 'Has the topping off procedures discussed (including sequence of tanks)?', 'checked': false},
        {'text': 'Is the ship securely moored?', 'checked': false},
        {'text': 'Is there safe access between ship and shore/barge?', 'checked': false},
        {'text': 'Is fire fighting equipment ready for use?', 'checked': false},
        {'text': 'Is the anti-pollution equipment ready at bunkering station?', 'checked': false},
        {'text': 'Are bunker hoses/arms in good condition and properly rigged?', 'checked': false},
        {'text': 'Are scuppers effectively plugged and drip trays in position?', 'checked': false},
        {'text': 'Are unused bunker connections blanked (fully bolted)?', 'checked': false},
        {'text': 'Have two-way communication and emergency stop signal been established?', 'checked': false},
        {'text': 'Are the air vents open on tanks to be filled?', 'checked': false},
        {'text': 'Does the bunkering plan designate an overflow tank?', 'checked': false},
        {'text': 'Is the overflow tank empty or slack?', 'checked': false},
        {'text': 'Have ship and facility agreed on pumping rates (Initial/Max/Topping off)?', 'checked': false},
        {'text': 'Has Risk Assessment carried out before bunkering?', 'checked': false},
        {'text': 'Is all sampling equipment clean and ready for use?', 'checked': false},
      ];
    } else if (tab == 'during') {
      return [
        {'text': 'Check levels of all bunker tanks, including those not being filled.', 'checked': false},
        {'text': 'Check hoses, loading arms and manifolds for pressure, safe support and no leaks.', 'checked': false},
        {'text': 'Check unused manifolds blanks for leaks.', 'checked': false},
        {'text': 'Check no build up of pressure in bunkers tanks (venting system working).', 'checked': false},
        {'text': 'Do those on watch know the bunkering plan including agreed signals?', 'checked': false},
        {'text': 'Are there enough crew available to control the change over of tanks safely?', 'checked': false},
        {'text': 'Check communication with delivering facility at regular intervals.', 'checked': false},
        {'text': 'Verify that all fuel tanks levels are as expected by frequent observations.', 'checked': false},
        {'text': 'Check ship\'s moorings.', 'checked': false},
        {'text': 'Is sampling taken continuously during bunkering period?', 'checked': false},
        {'text': 'Atmosphere checks for H2S & Benzene near tank vents.', 'checked': false},
        {'text': 'One person must be standby at manifold at all times.', 'checked': false},
        {'text': 'The level in the tanks to be staggered (one tank topped up at a time).', 'checked': false},
      ];
    } else {
      return [
        {'text': 'Has the hose / loading arm been properly blown or drained?', 'checked': false},
        {'text': 'Are the Manifold Valves Closed?', 'checked': false},
        {'text': 'What is the percentage of the higher tank?', 'checked': false},
        {'text': 'Was the Hose/Loading Arm blanked or sealed before lifting overside?', 'checked': false},
        {'text': 'Are the ship\'s deck lines drained so far as practicable?', 'checked': false},
        {'text': 'Are the Drip Trays and tank vent Save-alls drained?', 'checked': false},
        {'text': 'Has the atmosphere of fuel oil tank checked on completion for LEL?', 'checked': false},
        {'text': 'Are the Bunker Tank Valves, Venting Systems, Hatches secured?', 'checked': false},
        {'text': 'Are the Scupper Plugs, Absorbent Material, Firefighting Equipment stowed away?', 'checked': false},
        {'text': 'Is the Oil Record Book Entry completed?', 'checked': false},
        {'text': 'Are samples bottles sealed and labels signed by supplier?', 'checked': false},
      ];
    }
  }
    Future<void> _exportPdf(String tabKey, List<Map> items) async {
    final pdf = pw.Document();
    final title = 'BUNKERING CHECKLIST - ${tabKey.toUpperCase()}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 10),
            pw.Text('Vessel: ________________________     Port: ________________________', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
            
            // Таблица чек-листа
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Description', 'Status'],
              data: List<List<String>>.generate(items.length, (index) {
                final item = items[index];
                return [
                  (index + 1).toString(),
                  item['text'],
                  item['checked'] ? 'YES / OK' : 'NO / N/A',
                ];
              }),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(5),
            ),

            pw.SizedBox(height: 40),
            
            // Подпись
            if (_signatureBytes != null) ...[
              pw.Text('Officer in Charge Signature:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Image(pw.MemoryImage(_signatureBytes!), height: 80),
            ] else ...[
              pw.Text('Officer in Charge Signature: ________________________', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ]
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}