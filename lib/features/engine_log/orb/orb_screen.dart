import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/section_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/models/orb_entry.dart';
import '../../../domain/models/tank.dart';
import '../../../core/utils/time_input_formatter.dart';

class OrbScreen extends StatefulWidget {
  const OrbScreen({super.key});

  @override
  State<OrbScreen> createState() => _OrbScreenState();
}

class _OrbScreenState extends State<OrbScreen> {
  final _box = Hive.box('orb_history');
  final _tanksBox = Hive.box('tanks');
  
  String _selectedCode = 'C11.1';
  final Map<String, TextEditingController> _ctrls = {};
  String _generatedText = '';
  
  // Список для динамических танков при бункеровке (H_FUEL, H_LUBE)
  final List<Map<String, dynamic>> _bunkerTanks = [];
  
  // Дата
  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now();
  DateTime _stopDate = DateTime.now();

  final List<Map<String, String>> _codes = [
    {'code': 'C11.1', 'name': 'C 11.1 - Weekly Inventory of Sludge Tanks'},
    {'code': 'C11.4', 'name': 'C 11.4 - Collection of Sludge'},
    {'code': 'C12.1', 'name': 'C 12.1 - Disposal of Sludge to Shore'},
    {'code': 'C12.2', 'name': 'C 12.2 - Transfer Sludge to another tank'},
    {'code': 'C12.3', 'name': 'C 12.3 - Incineration of Sludge'},
    {'code': 'C12.4', 'name': 'C 12.4 - Evaporation of water from sludge'},
    {'code': 'D15.1', 'name': 'D 13-15.1 - Discharge Bilge Overboard'},
    {'code': 'D15.2', 'name': 'D 13-15.2 - Disposal Bilge to Shore'},
    {'code': 'D15.3', 'name': 'D 13-15.3 - Transfer Bilge to another tank'},
    {'code': 'F19', 'name': 'F 19-21 - Failure of 15 ppm Equipment'},
    {'code': 'H_FUEL', 'name': 'H - Bunkering of Fuel Oil'},
    {'code': 'H_LUBE', 'name': 'H - Bunkering of Lube Oil'},
    {'code': 'I_ALARM', 'name': 'I - Testing 15 ppm Alarm'},
    {'code': 'I_BILGE', 'name': 'I - Weekly Inventory of Bilge Water'},
    {'code': 'I_VALVE', 'name': 'I - Sealing / Unsealing Valve'},
    {'code': 'G', 'name': 'G - Accidental Discharge'},
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    // Создаем контроллеры заранее, чтобы не терять введенный текст при переключении
    final fields = ['qty', 'retained', 'cap', 'receiver', 'port', 'hours', 'pos', 'officer', 'tank1Name', 'tank2Name', 'tank1Add', 'tank1Total', 'tank2Add', 'tank2Total', 'startGmt', 'startLt', 'stopGmt', 'stopLt', 'posStart', 'posStop', 'receipt', 'substance', 'action', 'source', 'text'];
    for (var f in fields) {
      if (!_ctrls.containsKey(f)) _ctrls[f] = TextEditingController();
    }
  }

  String _formatDate(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    final months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    return '${two(dt.day)}-${months[dt.month - 1]}-${dt.year}';
  }

  List<String> _getTankNames({String type = 'all'}) {
    final tanks = _tanksBox.values.map((e) => Tank.fromMap(e)).toList();
    if (type == 'sludge') return tanks.where((t) => t.type == 'sludge').map((t) => t.name).toList();
    if (type == 'bilge') return tanks.where((t) => t.type == 'bilge').map((t) => t.name).toList();
    return tanks.map((t) => t.name).toList();
  }

  void _generate() {
    final dateStr = _formatDate(_selectedDate);
    String text = 'Date: $dateStr\n';
    String v(String key) => _ctrls[key]?.text ?? '';

    switch (_selectedCode) {
      case 'C11.1':
        text += 'C11.1 ${v('tank1Name')}\n11.2 ${v('cap')} m³\n11.3 ${v('retained')} m³';
        break;
      case 'C11.4':
        text += 'C11.1 ${v('tank1Name')}\n11.2 ${v('cap')} m³\n11.3 ${v('retained')} m³\n11.4 ${v('qty')} m³ collected from ${v('source')}';
        break;
      case 'C12.1':
        text += 'C12.1 ${v('qty')} m³ sludge from ${v('tank1Name')}, ${v('retained')} m³ retained,\nto "${v('receiver')}" during port stay (${v('port')})';
        break;
      case 'C12.2':
        text += 'C12.2 ${v('qty')} m³ ${v('substance')} from ${v('tank1Name')}, ${v('retained')} m³ retained,\nto ${v('tank2Name')} retained in tank(s) ${v('qty')} m³';
        break;
      case 'C12.3':
        text += 'C12.3 ${v('qty')} m³ sludge from ${v('tank1Name')}, ${v('retained')} m³ retained,\nBurned in Incinerator for ${v('hours')} hours';
        break;
      case 'C12.4':
        text += 'C12.4 ${v('qty')} m³ water evaporated from ${v('tank1Name')}, ${v('retained')} m³ retained.';
        break;
      case 'D15.1':
        text += 'D13 ${v('qty')} m³ bilge water from ${v('tank1Name')}\nCapacity ${v('cap')} m³, ${v('retained')} m³ retained\n14\nStart: ${v('startGmt')}H GMT / ${v('startLt')}H LT, stop: ${v('stopGmt')}H GMT / ${v('stopLt')}H LT\n15.1\nThrough 15 ppm equipment overboard\nPosition start: ${v('posStart')}\nPosition stop: ${v('posStop')}';
        break;
      case 'D15.2':
        text += 'D13 ${v('qty')} m³ bilge water from ${v('tank1Name')}, ${v('retained')} m³ retained\n14\nStart: ${v('startGmt')}H GMT / ${v('startLt')}H LT, stop: ${v('stopGmt')}H GMT / ${v('stopLt')}H LT\n15.2\nTo port reception facilities of ${v('port')}, receipt No: ${v('receipt')}';
        break;
      case 'D15.3':
        text += 'D13 ${v('qty')} m³ bilge water from ${v('tank1Name')}, ${v('retained')} m³ retained\n14\nStart: ${v('startGmt')}H GMT / ${v('startLt')}H LT, stop: ${v('stopGmt')}H GMT / ${v('stopLt')}H LT\n15.3\nTo ${v('tank2Name')}, retained in tank(s) ${v('qty')} m³';
        break;
      case 'F19':
        text += 'F19 ${v('startGmt')}H GMT / ${v('startLt')}H LT\n20 ${v('stopGmt')}H GMT / ${v('stopLt')}H LT\n21 ${v('source')}';
        break;
      case 'H_FUEL':
        String tanksText = '';
        for (var t in _bunkerTanks) {
          final added = double.tryParse(t['added'].text) ?? 0;
          if (added > 0) {
            tanksText += '${t['added'].text} MT added to ${t['name']} now containing ${t['total'].text} MT\n';
          }
        }
        final startStr = _formatDate(_startDate);
        final stopStr = _formatDate(_stopDate);
        text = 'Date: ${_formatDate(_selectedDate)}\nCode: H\n\n26.1 ${v('port')}\n26.2 Start $startStr-${v('startGmt')} Stop $stopStr-${v('stopGmt')}\n26.3 ${v('qty')} MT of ${v('source')} ${v('substance')} ${v('retained')} % S bunkered in tanks:\n$tanksText\nSigned: ${v('officer')}\nDate: $dateStr';
        break;
      case 'H_LUBE':
        String lubeTanksText = '';
        for (var t in _bunkerTanks) {
          final added = double.tryParse(t['added'].text) ?? 0;
          if (added > 0) {
            lubeTanksText += '${t['added'].text} MT added to ${t['name']} now containing ${t['total'].text} MT\n';
          }
        }
        final lStartStr = _formatDate(_startDate);
        final lStopStr = _formatDate(_stopDate);
        text = 'Date: ${_formatDate(_selectedDate)}\nCode: H\n\n26.1 ${v('port')}\n26.2 Start $lStartStr-${v('startGmt')} Stop $lStopStr-${v('stopGmt')}\n26.4 ${v('qty')} MT ${v('substance')} bunkered in tanks:\n$lubeTanksText\nSigned: ${v('officer')}\nDate: $dateStr';
        break;
      case 'I_ALARM':
        text += 'I Tested 15 ppm alarm in OCM unit\nStart: ${v('startGmt')}H GMT / ${v('startLt')}H LT, stop: ${v('stopGmt')}H GMT / ${v('stopLt')}H LT\nFound working properly';
        break;
      case 'I_BILGE':
        text += 'I Weekly Inventory of Bilge Water Tanks (listed under item 3.3)\n${v('tank1Name')}\ncapacity ${v('cap')} m³, ${v('retained')} m³ retained';
        break;
      case 'I_VALVE':
        text += 'I Overboard valve ${v('source')} from 15 ppm bilge water separator unit ${v('action')}\nfor normal operation of 15 ppm unit\nseal No.: ${v('receipt')}';
        break;
      case 'G':
        text += 'G22 ${v('startGmt')}H GMT / ${v('startLt')}H LT\n23 Place or Position: ${v('posStart')}\n24 Type and Quantity of oily residue (if known): ${v('qty')}\n25 Circumstances of the discharge: ${v('source')}';
        break;
    }

    if (_selectedCode != 'H_FUEL' && _selectedCode != 'H_LUBE') {
      final officerText = v('officer').isNotEmpty ? v('officer') : 'Chief Engineer';
      text += '\n\nSigned: $officerText\nDate: $dateStr';
    }

    setState(() => _generatedText = text);
  }

  void _save() {
    if (_generatedText.isEmpty) return;
    final entry = OrbEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: _selectedCode,
      date: _formatDate(_selectedDate),
      text: _generatedText,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _box.put(entry.id, entry.toMap());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to History!')));
  }

  @override
  Widget build(BuildContext context) {
        return AppScaffold(
      title: 'ORB Generator',
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
        DropdownButtonFormField<String>(
          initialValue: _selectedCode,
          dropdownColor: cardSolid,
          decoration: const InputDecoration(labelText: 'Operation Code'),
          items: _codes.map((c) => DropdownMenuItem(value: c['code'], child: Text(c['name']!, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (val) {
            setState(() { _selectedCode = val!; _generatedText = ''; });
          },
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Date'),
            child: Text(_formatDate(_selectedDate), style: const TextStyle(color: text, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        ..._buildDynamicFields(),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _generate, child: const Text('GENERATE TEXT')),
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
              Expanded(child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _generatedText));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
                },
                icon: const Icon(Icons.copy),
                label: const Text('COPY'),
                style: ElevatedButton.styleFrom(backgroundColor: border, foregroundColor: text),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('SAVE'),
                style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: bg),
              )),
            ],
          )
        ]
      ],
    );
  }

  Widget _buildField(String label, String key, {bool isNumber = false, bool isTime = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _ctrls[key],
        decoration: InputDecoration(labelText: label),
        keyboardType: isTime ? TextInputType.number : (isNumber ? TextInputType.number : TextInputType.text),
        inputFormatters: isTime ? [TimeInputFormatter()] : [],
      ),
    );
  }

  Widget _buildTankDropdown(String label, String key, String type) {
    final tanks = _getTankNames(type: type);
    if (tanks.isEmpty) tanks.add('NO TANKS FOUND');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: _ctrls[key]!.text.isEmpty ? tanks.first : _ctrls[key]!.text,
        decoration: InputDecoration(labelText: label),
        dropdownColor: cardSolid,
        items: tanks.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: (val) => _ctrls[key]!.text = val!,
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    List<Widget> fields = [];
    switch (_selectedCode) {
      case 'C11.1':
        fields = [_buildTankDropdown('Sludge Tank', 'tank1Name', 'sludge'), _buildField('Capacity (m³)', 'cap', isNumber: true), _buildField('Quantity Retained (m³)', 'retained', isNumber: true)];
        break;
      case 'C11.4':
        fields = [_buildTankDropdown('Destination Tank', 'tank1Name', 'sludge'), _buildField('Capacity (m³)', 'cap', isNumber: true), _buildField('Retained (m³)', 'retained', isNumber: true), _buildField('Collected (m³)', 'qty', isNumber: true), _buildField('Source', 'source')];
        break;
      case 'C12.1':
        fields = [_buildTankDropdown('Source Tank', 'tank1Name', 'sludge'), _buildField('Quantity (m³)', 'qty', isNumber: true), _buildField('Retained (m³)', 'retained', isNumber: true), _buildField('Receiver (Barge)', 'receiver'), _buildField('Port', 'port')];
        break;
      case 'C12.2':
        fields = [_buildTankDropdown('Source Tank', 'tank1Name', 'sludge'), _buildTankDropdown('Dest Tank', 'tank2Name', 'all'), _buildField('Substance (sludge/water)', 'substance'), _buildField('Quantity (m³)', 'qty', isNumber: true), _buildField('Retained Source', 'retained', isNumber: true)];
        break;
      case 'C12.3':
        fields = [_buildTankDropdown('Source Tank', 'tank1Name', 'sludge'), _buildField('Quantity (m³)', 'qty', isNumber: true), _buildField('Retained (m³)', 'retained', isNumber: true), _buildField('Hours', 'hours', isNumber: true)];
        break;
      case 'C12.4':
        fields = [_buildTankDropdown('Source Tank', 'tank1Name', 'sludge'), _buildField('Quantity (m³)', 'qty', isNumber: true), _buildField('Retained (m³)', 'retained', isNumber: true)];
        break;
      case 'D15.1':
        fields = [_buildTankDropdown('Bilge Tank', 'tank1Name', 'bilge'), _buildField('Quantity (m³)', 'qty', isNumber: true), _buildField('Capacity (m³)', 'cap', isNumber: true), _buildField('Retained (m³)', 'retained', isNumber: true), _buildField('Start GMT', 'startGmt', isTime: true), _buildField('Start LT', 'startLt', isTime: true), _buildField('Stop GMT', 'stopGmt', isTime: true), _buildField('Stop LT', 'stopLt', isTime: true), _buildField('Pos Start', 'posStart'), _buildField('Pos Stop', 'posStop')];
        break;
      case 'D15.2':
        fields = [_buildTankDropdown('Bilge Tank', 'tank1Name', 'bilge'), _buildField('Quantity (m³)', 'qty', isNumber: true), _buildField('Retained (m³)', 'retained', isNumber: true), _buildField('Start GMT', 'startGmt', isTime: true), _buildField('Start LT', 'startLt', isTime: true), _buildField('Stop GMT', 'stopGmt', isTime: true), _buildField('Stop LT', 'stopLt', isTime: true), _buildField('Port', 'port'), _buildField('Receipt No', 'receipt')];
        break;
      case 'D15.3':
        fields = [_buildTankDropdown('Source Tank', 'tank1Name', 'bilge'), _buildTankDropdown('Dest Tank', 'tank2Name', 'all'), _buildField('Quantity (m³)', 'qty', isNumber: true), _buildField('Retained Source', 'retained', isNumber: true), _buildField('Start GMT', 'startGmt', isTime: true), _buildField('Start LT', 'startLt', isTime: true), _buildField('Stop GMT', 'stopGmt', isTime: true), _buildField('Stop LT', 'stopLt', isTime: true)];
        break;
      case 'F19':
        fields = [_buildField('Start GMT', 'startGmt', isTime: true), _buildField('Start LT', 'startLt', isTime: true), _buildField('Stop GMT', 'stopGmt', isTime: true), _buildField('Stop LT', 'stopLt', isTime: true), _buildField('Reason', 'source')];
        break;
      case 'H_FUEL':
        fields = [
          _buildField('Port', 'port'), 
          Row(
            children: [
              Expanded(child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) setState(() => _startDate = picked);
                },
                child: InputDecorator(decoration: const InputDecoration(labelText: 'Start Date'), child: Text(_formatDate(_startDate), style: const TextStyle(color: text))),
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildField('Start Time', 'startGmt', isTime: true)),
            ],
          ),
          Row(
            children: [
              Expanded(child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _stopDate, firstDate: _startDate, lastDate: DateTime(2100));
                  if (picked != null) setState(() => _stopDate = picked);
                },
                child: InputDecorator(decoration: const InputDecoration(labelText: 'Stop Date'), child: Text(_formatDate(_stopDate), style: const TextStyle(color: text))),
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildField('Stop Time', 'stopGmt', isTime: true)),
            ],
          ),
          _buildField('Total Qty (MT)', 'qty', isNumber: true), 
          _buildField('ISO Designation', 'source'), 
          _buildField('Fuel Type (HFO/MGO)', 'substance'), 
          _buildField('Sulphur (%)', 'retained'),
          Text('Tanks Distribution:', style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ..._buildDynamicTankList(),
          _buildField('Officer Name & Rank', 'officer')
        ];
        break;
      case 'H_LUBE':
        fields = [
          _buildField('Port', 'port'), 
          Row(
            children: [
              Expanded(child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) setState(() => _startDate = picked);
                },
                child: InputDecorator(decoration: const InputDecoration(labelText: 'Start Date'), child: Text(_formatDate(_startDate), style: const TextStyle(color: text))),
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildField('Start Time', 'startGmt', isTime: true)),
            ],
          ),
          Row(
            children: [
              Expanded(child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _stopDate, firstDate: _startDate, lastDate: DateTime(2100));
                  if (picked != null) setState(() => _stopDate = picked);
                },
                child: InputDecorator(decoration: const InputDecoration(labelText: 'Stop Date'), child: Text(_formatDate(_stopDate), style: const TextStyle(color: text))),
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildField('Stop Time', 'stopGmt', isTime: true)),
            ],
          ),
          _buildField('Total Qty (MT)', 'qty', isNumber: true), 
          _buildField('Oil Type', 'substance'),
          Text('Tanks Distribution:', style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ..._buildDynamicTankList(),
          _buildField('Officer Name & Rank', 'officer')
        ];
        break;
      case 'I_ALARM':
        fields = [_buildField('Start GMT', 'startGmt', isTime: true), _buildField('Start LT', 'startLt', isTime: true), _buildField('Stop GMT', 'stopGmt', isTime: true), _buildField('Stop LT', 'stopLt', isTime: true)];
        break;
      case 'I_BILGE':
        fields = [_buildTankDropdown('Bilge Tank', 'tank1Name', 'bilge'), _buildField('Capacity (m³)', 'cap', isNumber: true), _buildField('Retained (m³)', 'retained', isNumber: true)];
        break;
      case 'I_VALVE':
        fields = [DropdownButtonFormField<String>(
          initialValue: _ctrls['action']!.text.isEmpty ? 'UNSEALED' : _ctrls['action']!.text,
          decoration: const InputDecoration(labelText: 'Action'),
          dropdownColor: cardSolid,
          items: const [DropdownMenuItem(value: 'UNSEALED', child: Text('UNSEALED')), DropdownMenuItem(value: 'SEALED', child: Text('SEALED'))],
          onChanged: (val) => _ctrls['action']!.text = val!,
        ), _buildField('Valve No', 'source'), _buildField('Seal No', 'receipt')];
        break;
      case 'G':
        fields = [_buildField('Start GMT', 'startGmt', isTime: true), _buildField('Start LT', 'startLt', isTime: true), _buildField('Position', 'posStart'), _buildField('Type & Qty', 'qty'), _buildField('Circumstances', 'source')];
        break;
    }
    return fields;
  }

  Widget _buildHistory() {
    final data = _box.values.map((e) => OrbEntry.fromMap(e)).toList();
    data.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (data.isEmpty) return const Center(child: Text('No history yet.', style: TextStyle(color: textMuted)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.code} - ${item.date}', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        _box.delete(item.id);
                        setState(() {});
                      },
                    )
                  ],
                ),
                Divider(color: border),
                Text(item.text, style: const TextStyle(color: text, fontFamily: 'monospace', fontSize: 12)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.text));
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
  List<Widget> _buildDynamicTankList() {
    List<Widget> widgets = [];
    final tankNames = _getTankNames(); // Берем все танки
    
    for (int i = 0; i < _bunkerTanks.length; i++) {
      final t = _bunkerTanks[i];
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardSolid,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: t['name'],
                      isExpanded: true,
                      dropdownColor: cardSolid,
                      decoration: const InputDecoration(labelText: 'Tank', isDense: true),
                      items: tankNames.map((name) => DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setState(() => t['name'] = val!),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => setState(() => _bunkerTanks.removeAt(i)),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: t['added'],
                      decoration: const InputDecoration(labelText: 'Added (MT)', isDense: true),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: t['total'],
                      decoration: const InputDecoration(labelText: 'Total (MT)', isDense: true),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              )
            ],
          ),
        )
      );
    }
    
    widgets.add(
      TextButton.icon(
        onPressed: () {
          setState(() {
            _bunkerTanks.add({
              'name': tankNames.isNotEmpty ? tankNames.first : 'NO TANKS',
              'added': TextEditingController(),
              'total': TextEditingController(),
            });
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('+ Add Tank'),
      )
    );
    
    return widgets;
  }
}
