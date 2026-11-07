import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
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

  final _eventCtrl = TextEditingController(text: 'NOON');
  final _timeCtrl = TextEditingController();
  
  final _meCurrCtrl = TextEditingController();
  final _meTempCtrl = TextEditingController(text: '15');
  final _meDensCtrl = TextEditingController(text: '0.9455');

  final _dgCurrCtrl = TextEditingController();
  final _dgTempCtrl = TextEditingController(text: '15');
  final _dgDensCtrl = TextEditingController(text: '0.9455');

  final _blrCurrCtrl = TextEditingController();
  final _blrTempCtrl = TextEditingController(text: '15');
  final _blrDensCtrl = TextEditingController(text: '0.9455');

  final _bunkerCtrl = TextEditingController(text: '0');
  final _robCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _timeCtrl.text = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  // Эта функция считает дельту и переводит в тонны "на лету"
  double _calcLiveMT(TextEditingController currCtrl, TextEditingController tempCtrl, TextEditingController densCtrl, double? prevVal) {
    final curr = double.tryParse(currCtrl.text) ?? 0;
    if (curr == 0 || prevVal == null) return 0;
    
    final delta = curr - prevVal;
    if (delta <= 0) return 0;

    final temp = double.tryParse(tempCtrl.text) ?? 15;
    final dens = double.tryParse(densCtrl.text) ?? 0.95;
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

    final meCurr = double.tryParse(_meCurrCtrl.text) ?? 0;
    final dgCurr = double.tryParse(_dgCurrCtrl.text) ?? 0;
    final blrCurr = double.tryParse(_blrCurrCtrl.text) ?? 0;

    final meMT = _calcLiveMT(_meCurrCtrl, _meTempCtrl, _meDensCtrl, lastLog?.meCurr);
    final dgMT = _calcLiveMT(_dgCurrCtrl, _dgTempCtrl, _dgDensCtrl, lastLog?.dgCurr);
    final blrMT = _calcLiveMT(_blrCurrCtrl, _blrTempCtrl, _blrDensCtrl, lastLog?.blrCurr);

    final bunker = double.tryParse(_bunkerCtrl.text) ?? 0;
    
    double newRob;
    if (_robCtrl.text.isNotEmpty) {
      newRob = double.tryParse(_robCtrl.text) ?? 0;
    } else {
      final prevRob = lastLog?.rob ?? 0;
      newRob = prevRob - (meMT + dgMT + blrMT) + bunker;
    }

    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final newLog = FuelLog(
      id: now.millisecondsSinceEpoch.toString(),
      date: dateStr,
      time: _timeCtrl.text,
      event: _eventCtrl.text,
      bunker: bunker,
      rob: newRob,
      meCurr: meCurr, meMT: meMT,
      dgCurr: dgCurr, dgMT: dgMT,
      blrCurr: blrCurr, blrMT: blrMT,
    );

    _box.put(newLog.id, newLog.toMap());
    setState(() {}); 
    
    _meCurrCtrl.clear();
    _dgCurrCtrl.clear();
    _blrCurrCtrl.clear();
    _bunkerCtrl.text = '0';
    _robCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved! ME: ${meMT.toStringAsFixed(2)} MT, ROB: ${newRob.toStringAsFixed(1)} MT')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsData = _box.values.toList();
    final logs = logsData.map((e) => FuelLog.fromMap(e)).toList();
    logs.sort((a, b) => b.id.compareTo(a.id)); // Новые сверху

    FuelLog? lastLog = logs.isNotEmpty ? logs.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Daily Log'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: accent,
              labelColor: accent,
              unselectedLabelColor: textMuted,
              tabs: [
                Tab(text: 'NEW ENTRY'),
                Tab(text: 'HISTORY'),
              ],
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
    // Обертка для перерисовки экрана при вводе цифр (для живого расчета)
    return StatefulBuilder(
      builder: (context, setInputState) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Enter CURRENT FLOW METER READINGS (not daily consumption). The app will automatically calculate the difference.',
              style: TextStyle(color: textMuted, fontSize: 13, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            if (lastLog != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: accent.withOpacity(0.3))),
                child: Text('Previous reading (${lastLog.date} ${lastLog.time}):\nME: ${lastLog.meCurr} | DG: ${lastLog.dgCurr} | BLR: ${lastLog.blrCurr}', style: const TextStyle(color: accent, fontSize: 12)),
              ),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _timeCtrl, 
                    decoration: const InputDecoration(labelText: 'Time (HH:MM)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [TimeInputFormatter()],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _eventCtrl, 
                    decoration: const InputDecoration(labelText: 'Event / Status'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildMeterBlock('Main Engine (M/E)', _meCurrCtrl, _meTempCtrl, _meDensCtrl, lastLog?.meCurr, setInputState),
            _buildMeterBlock('Diesel Generators (D/G)', _dgCurrCtrl, _dgTempCtrl, _dgDensCtrl, lastLog?.dgCurr, setInputState),
            _buildMeterBlock('Boiler (BLR)', _blrCurrCtrl, _blrTempCtrl, _blrDensCtrl, lastLog?.blrCurr, setInputState),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _bunkerCtrl, decoration: const InputDecoration(labelText: 'Bunker Received (MT)'), keyboardType: TextInputType.number, onChanged: (v) => setInputState((){}))),
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

  Widget _buildMeterBlock(String title, TextEditingController currCtrl, TextEditingController tempCtrl, TextEditingController densCtrl, double? prevVal, StateSetter setInputState) {
    final liveMT = _calcLiveMT(currCtrl, tempCtrl, densCtrl, prevVal);
    
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
                Text(title, style: const TextStyle(color: accent, fontWeight: FontWeight.bold)),
                if (liveMT > 0)
                  Text('Cons: ${liveMT.toStringAsFixed(2)} MT', style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold)),
              ],
            ),
            if (prevVal != null) 
              Text('Prev: $prevVal  |  Delta: ${(double.tryParse(currCtrl.text) ?? 0) - prevVal}', style: const TextStyle(color: textMuted, fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(flex: 2, child: TextField(
                  controller: currCtrl, 
                  decoration: const InputDecoration(labelText: 'Current Reading'), 
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setInputState((){}), // Вызывает живой пересчет
                )),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: tempCtrl, decoration: const InputDecoration(labelText: 'Temp °C'), keyboardType: TextInputType.number, onChanged: (v) => setInputState((){}))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: densCtrl, decoration: const InputDecoration(labelText: 'Dens t/m³'), keyboardType: TextInputType.number, onChanged: (v) => setInputState((){}))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<FuelLog> logs) {
    if (logs.isEmpty) {
      return const Center(child: Text('No logs yet.', style: TextStyle(color: textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardSolid,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Шапка карточки (Дата, Время, Событие)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${log.date}  ${log.time}', style: const TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(log.event, style: const TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(color: border, height: 24),
              
              // Расход по механизмам
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('ME', log.meMT, accent),
                  _buildStatItem('DG', log.dgMT, accent),
                  _buildStatItem('BLR', log.blrMT, accent),
                ],
              ),
              const SizedBox(height: 12),
              
              // Бункер и Остаток
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