import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/section_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/models/fuel_log.dart';
import '../../../domain/calculators/vcf_calculator.dart';
import '../../../core/utils/time_input_formatter.dart';

class FuelLogScreen extends StatefulWidget {
  const FuelLogScreen({super.key});

  @override
  State<FuelLogScreen> createState() => _FuelLogScreenState();
}

class _FuelLogScreenState extends State<FuelLogScreen> {
  final _box = Hive.box('fuel_logs');
  final _settingsBox = Hive.box('settings');

  final _eventCtrl = TextEditingController(text: 'NOON');
  final _timeCtrl = TextEditingController();
  final _bunkerCtrl = TextEditingController(text: '0');
  final _robCtrl = TextEditingController();

  // Контроллеры замеров (показания)
  final _meCurrCtrl = TextEditingController();
  final _dgCurrCtrl = TextEditingController();
  final _dgOutCurrCtrl = TextEditingController();
  final _blrCurrCtrl = TextEditingController();
  final _commonCurrCtrl = TextEditingController();

  // Контроллеры плотности и температуры (только для Volumetric)
  final _meDensCtrl = TextEditingController(text: '0.9455');
  final _meTempCtrl = TextEditingController(text: '15');
  final _dgDensCtrl = TextEditingController(text: '0.9455');
  final _dgTempCtrl = TextEditingController(text: '15');
  final _dgOutDensCtrl = TextEditingController(text: '0.9455');
  final _dgOutTempCtrl = TextEditingController(text: '15');
  final _blrDensCtrl = TextEditingController(text: '0.9455');
  final _blrTempCtrl = TextEditingController(text: '15');
  final _commonDensCtrl = TextEditingController(text: '0.9455');
  final _commonTempCtrl = TextEditingController(text: '15');

  String _meterType = 'vol';
  String _scheme = 'direct';
  bool _hasDgOut = false;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _timeCtrl.text = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    _loadSettings();
  }

  void _loadSettings() {
    _meterType = _settingsBox.get('meterType', defaultValue: 'vol');
    _scheme = _settingsBox.get('scheme', defaultValue: 'direct');
    _hasDgOut = _settingsBox.get('hasDgOut', defaultValue: false);
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: cardSolid,
            title: const Text('Meter Settings', style: TextStyle(color: text)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure how your flow meters work. Choose Volumetric if they show m³, or Mass if they show MT.',
                    style: TextStyle(color: textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  Text('Meter Type:', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _meterType,
                    isExpanded: true,
                    dropdownColor: cardSolid,
                    items: const [
                      DropdownMenuItem(value: 'vol', child: Text('Volumetric (m³)')),
                      DropdownMenuItem(value: 'mass', child: Text('Mass (MT)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _meterType = val);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Meter Scheme:', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _scheme,
                    isExpanded: true,
                    dropdownColor: cardSolid,
                    items: const [
                      DropdownMenuItem(value: 'direct', child: Text('Direct (M/E, D/G, BLR)')),
                      DropdownMenuItem(value: 'common_all', child: Text('Common All (M/E = Comm - DG - BLR)')),
                      DropdownMenuItem(value: 'common_me_dg', child: Text('Common M/E + D/G (M/E = Comm - DG)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _scheme = val);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Has D/G OUT Meter', style: TextStyle(color: accent, fontSize: 14)),
                    subtitle: const Text('Calculate D/G Cons as (IN - OUT)', style: TextStyle(color: textMuted, fontSize: 12)),
                    value: _hasDgOut,
                    activeThumbColor: accent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() => _hasDgOut = val);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  _settingsBox.put('meterType', _meterType);
                  _settingsBox.put('scheme', _scheme);
                  _settingsBox.put('hasDgOut', _hasDgOut);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              )
            ],
          );
        }
      ),
    );
  }

  double _calcLiveMT(TextEditingController currCtrl, TextEditingController densCtrl, TextEditingController tempCtrl, double? prevVal) {
    final curr = double.tryParse(currCtrl.text) ?? 0;
    if (curr == 0 || prevVal == null) return 0;
    final delta = curr - prevVal;
    if (delta <= 0) return 0;
    if (_meterType == 'mass') return delta;
    
    final dens = double.tryParse(densCtrl.text) ?? 0.9455;
    final temp = double.tryParse(tempCtrl.text) ?? 15.0;
    final vcf = VcfCalculator.getVcf(dens);
    final mass = (delta * dens) - (vcf * (temp - 15) * delta * dens);
    return mass > 0 ? mass : 0;
  }

  void _addLog() {
    final allLogs = _box.values.map((e) => FuelLog.fromMap(e)).toList();
    FuelLog? lastLog;
    if (allLogs.isNotEmpty) {
      allLogs.sort((a, b) => a.id.compareTo(b.id));
      lastLog = allLogs.last;
    }

    final meCurr = double.tryParse(_meCurrCtrl.text) ?? 0.0;
    final dgInCurr = double.tryParse(_dgCurrCtrl.text) ?? 0.0;
    final dgOutCurr = _hasDgOut ? (double.tryParse(_dgOutCurrCtrl.text) ?? 0.0) : 0.0;
    final blrCurr = double.tryParse(_blrCurrCtrl.text) ?? 0.0;
    final commCurr = double.tryParse(_commonCurrCtrl.text) ?? 0.0;

    final meDens = double.tryParse(_meDensCtrl.text) ?? 0.9455;
    final meTemp = double.tryParse(_meTempCtrl.text) ?? 15.0;
    final dgDens = double.tryParse(_dgDensCtrl.text) ?? 0.9455;
    final dgTemp = double.tryParse(_dgTempCtrl.text) ?? 15.0;
    final dgOutDens = double.tryParse(_dgOutDensCtrl.text) ?? 0.9455;
    final dgOutTemp = double.tryParse(_dgOutTempCtrl.text) ?? 15.0;
    final blrDens = double.tryParse(_blrDensCtrl.text) ?? 0.9455;
    final blrTemp = double.tryParse(_blrTempCtrl.text) ?? 15.0;
    final commDens = double.tryParse(_commonDensCtrl.text) ?? 0.9455;
    final commTemp = double.tryParse(_commonTempCtrl.text) ?? 15.0;

    final memtRaw = _calcLiveMT(_meCurrCtrl, _meDensCtrl, _meTempCtrl, lastLog?.meCurr);
    final dgInMT = _calcLiveMT(_dgCurrCtrl, _dgDensCtrl, _dgTempCtrl, lastLog?.dgCurr);
    final dgOutMT = _hasDgOut ? _calcLiveMT(_dgOutCurrCtrl, _dgOutDensCtrl, _dgOutTempCtrl, lastLog?.dgOutCurr) : 0.0;
    final dgMT = (dgInMT - dgOutMT) > 0 ? (dgInMT - dgOutMT) : 0.0;
    
    final blrMT = _calcLiveMT(_blrCurrCtrl, _blrDensCtrl, _blrTempCtrl, lastLog?.blrCurr);
    final commMT = _calcLiveMT(_commonCurrCtrl, _commonDensCtrl, _commonTempCtrl, lastLog?.commonCurr);

    double finalMeMT = memtRaw;
    if (_scheme == 'common_all') {
      finalMeMT = commMT - dgMT - blrMT;
    } else if (_scheme == 'common_me_dg') {
      finalMeMT = commMT - dgMT;
    }
    if (finalMeMT < 0) finalMeMT = 0;

    final bunker = double.tryParse(_bunkerCtrl.text) ?? 0.0;
    double newRob;
    if (_robCtrl.text.isNotEmpty) {
      newRob = double.tryParse(_robCtrl.text) ?? 0.0;
    } else {
      final prevRob = lastLog?.rob ?? 0.0;
      newRob = prevRob - (finalMeMT + dgMT + blrMT) + bunker;
    }

    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final newLog = FuelLog(
      id: now.millisecondsSinceEpoch.toString(),
      date: dateStr, time: _timeCtrl.text, event: _eventCtrl.text,
      bunker: bunker, rob: newRob,
      meCurr: meCurr, meMT: finalMeMT, meDens: meDens, meTemp: meTemp,
      dgCurr: dgInCurr, dgOutCurr: dgOutCurr, dgMT: dgMT, dgDens: dgDens, dgTemp: dgTemp, dgOutDens: dgOutDens, dgOutTemp: dgOutTemp,
      blrCurr: blrCurr, blrMT: blrMT, blrDens: blrDens, blrTemp: blrTemp,
      commonCurr: commCurr, commonMT: commMT, commonDens: commDens, commonTemp: commTemp,
    );

    _box.put(newLog.id, newLog.toMap());
    setState(() {}); 
    
    _meCurrCtrl.clear(); _dgCurrCtrl.clear(); _dgOutCurrCtrl.clear(); _blrCurrCtrl.clear(); _commonCurrCtrl.clear();
    _bunkerCtrl.text = '0'; _robCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved! ME: ${finalMeMT.toStringAsFixed(2)} MT, DG Net: ${dgMT.toStringAsFixed(2)} MT')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsData = _box.values.toList();
    final logs = logsData.map((e) => FuelLog.fromMap(e)).toList();
    logs.sort((a, b) => b.id.compareTo(a.id)); 

    FuelLog? lastLog = logs.isNotEmpty ? logs.first : null;

                return AppScaffold(
      title: 'Fuel Daily Log',
      background: AppBackground.engineRoom,
      section: AppSection.engine,
      actions: [
        IconButton(icon: Icon(Icons.settings, color: SectionTheme.of(context).accent), onPressed: _showSettings),
      ],
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [Tab(text: 'NEW ENTRY'), Tab(text: 'HISTORY')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildInputForm(lastLog),
                  _buildHistoryList(logs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm(FuelLog? lastLog) {
    return StatefulBuilder(
      builder: (context, setInputState) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Enter CURRENT FLOW METER READINGS. The app calculates the difference.',
              style: TextStyle(color: textMuted, fontSize: 13, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            if (lastLog != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(8), 
                  border: Border.all(color: accent.withValues(alpha: 0.3))
                ),
                child: Text('Previous (${lastLog.date} ${lastLog.time}):\nME: ${lastLog.meCurr} | DG IN: ${lastLog.dgCurr} | BLR: ${lastLog.blrCurr}', style: TextStyle(color: accent, fontSize: 12)),
              ),

            Row(
              children: [
                Expanded(child: TextField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'Time (HH:MM)'), keyboardType: TextInputType.number, inputFormatters: [TimeInputFormatter()])),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: TextField(controller: _eventCtrl, decoration: const InputDecoration(labelText: 'Event / Status'))),
              ],
            ),
            const SizedBox(height: 16),

            if (_scheme == 'direct')
              _buildMeterBlock('Main Engine (M/E)', _meCurrCtrl, _meDensCtrl, _meTempCtrl, lastLog?.meCurr, setInputState),
            if (_scheme != 'direct')
              _buildMeterBlock('Common Meter (Total)', _commonCurrCtrl, _commonDensCtrl, _commonTempCtrl, lastLog?.commonCurr, setInputState, isCommon: true),
              
            _buildMeterBlock('Diesel Generators (D/G IN)', _dgCurrCtrl, _dgDensCtrl, _dgTempCtrl, lastLog?.dgCurr, setInputState),
            
            if (_hasDgOut)
              _buildMeterBlock('Diesel Generators (D/G OUT)', _dgOutCurrCtrl, _dgOutDensCtrl, _dgOutTempCtrl, lastLog?.dgOutCurr, setInputState, isOut: true),
              
            _buildMeterBlock('Boiler (BLR)', _blrCurrCtrl, _blrDensCtrl, _blrTempCtrl, lastLog?.blrCurr, setInputState),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _bunkerCtrl, decoration: const InputDecoration(labelText: 'Bunker Received (MT)'), keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _robCtrl, decoration: const InputDecoration(labelText: 'Total ROB (MT)'), keyboardType: TextInputType.number)),
              ],
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addLog,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('CALCULATE & SAVE'),
            ),
          ],
        );
      }
    );
  }

  Widget _buildMeterBlock(String title, TextEditingController currCtrl, TextEditingController densCtrl, TextEditingController tempCtrl, double? prevVal, StateSetter setInputState, {bool isCommon = false, bool isOut = false}) {
    final liveMT = _calcLiveMT(currCtrl, densCtrl, tempCtrl, prevVal);
    final unit = _meterType == 'vol' ? 'm³' : 'MT';
    
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
                Text(title, style: TextStyle(color: isCommon ? Colors.orangeAccent : (isOut ? Colors.blueAccent : accent), fontWeight: FontWeight.bold)),
                if (liveMT > 0 && !isOut)
                  Text('Cons: ${liveMT.toStringAsFixed(2)} MT', style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold)),
              ],
            ),
            if (prevVal != null) 
              Text('Prev: $prevVal $unit', style: const TextStyle(color: textMuted, fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: currCtrl, 
                    decoration: InputDecoration(labelText: 'Curr ($unit)'), 
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setInputState((){}),
                  ),
                ),
                if (_meterType == 'vol') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: tempCtrl, 
                      decoration: const InputDecoration(labelText: 'Temp °C'), 
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setInputState((){}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: densCtrl, 
                      decoration: const InputDecoration(labelText: 'Dens t/m³'), 
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setInputState((){}),
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<FuelLog> logs) {
    if (logs.isEmpty) return const Center(child: Text('No logs yet.', style: TextStyle(color: textMuted)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardSolid, border: Border.all(color: border), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${log.date}  ${log.time}', style: const TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(log.event, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              Divider(color: border, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('ME', log.meMT, accent),
                  _buildStatItem('DG (Net)', log.dgMT, accent),
                  _buildStatItem('BLR', log.blrMT, accent),
                  if (_scheme != 'direct') _buildStatItem('COMMON', log.commonMT, Colors.orangeAccent),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('BUNKER', log.bunker, Colors.orangeAccent),
                  _buildStatItem('ROB', log.rob, const Color(0xFF4ADE80)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: textMuted, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value.toStringAsFixed(2), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
