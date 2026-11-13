import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/section_theme.dart';
import '../../../core/widgets/app_scaffold.dart';

class VoyageScreen extends StatefulWidget {
  const VoyageScreen({super.key});

  @override
  State<VoyageScreen> createState() => _VoyageScreenState();
}

class _VoyageScreenState extends State<VoyageScreen> {
  final _distCtrl = TextEditingController();
  final _speedCtrl = TextEditingController();
  final _consCtrl = TextEditingController();
  final _robCtrl = TextEditingController();
  String _result = '';
  Color _resultColor = text;

  void _calculate() {
    final dist = double.tryParse(_distCtrl.text.replaceAll(',', '.')) ?? 0;
    final speed = double.tryParse(_speedCtrl.text.replaceAll(',', '.')) ?? 0;
    final cons = double.tryParse(_consCtrl.text.replaceAll(',', '.')) ?? 0;
    final rob = double.tryParse(_robCtrl.text.replaceAll(',', '.')) ?? 0;

    if (dist <= 0 || speed <= 0 || cons <= 0) {
      setState(() {
        _result = 'Please enter valid Distance, Speed, and Consumption.';
        _resultColor = Colors.redAccent;
      });
      return;
    }

    final days = dist / (speed * 24);
    final totalCons = days * cons;
    final expectedRob = rob - totalCons;

    setState(() {
      _result = 'Voyage Details:\n'
          '- Total Days: ${days.toStringAsFixed(1)} days\n'
          '- Total Consumption: ${totalCons.toStringAsFixed(1)} MT\n'
          '- Arrival ROB: ${expectedRob.toStringAsFixed(1)} MT\n\n';
      
      if (expectedRob < 0) {
        _resultColor = Colors.redAccent;
        _result += '⚠️ WARNING: SHORTAGE OF ${expectedRob.abs().toStringAsFixed(1)} MT!\nYou need to bunker or reduce speed.';
      } else {
        _resultColor = Colors.greenAccent;
        _result += '✅ SAFE: You will arrive with ${expectedRob.toStringAsFixed(1)} MT.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
        return AppScaffold(
      title: 'Voyage Plan',
      background: AppBackground.engineRoom,
      section: AppSection.engine,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Calculate if you have enough fuel for the voyage. Enter distance, planned speed, and daily consumption.',
            style: TextStyle(color: textMuted, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          
          TextField(controller: _distCtrl, decoration: const InputDecoration(labelText: 'Distance (NM)'), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(child: TextField(controller: _speedCtrl, decoration: const InputDecoration(labelText: 'Speed (kts)'), keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _consCtrl, decoration: const InputDecoration(labelText: 'Daily Cons (MT/day)'), keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 12),
          
          TextField(controller: _robCtrl, decoration: const InputDecoration(labelText: 'Current ROB (MT)'), keyboardType: TextInputType.number),
          
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculate,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text('CALCULATE VOYAGE'),
          ),
          
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardSolid, border: Border.all(color: _resultColor), borderRadius: BorderRadius.circular(12)),
              child: Text(_result, style: TextStyle(color: _resultColor, fontFamily: 'monospace', fontSize: 14, height: 1.5)),
            ),
          ]
        ],
      ),
    );
  }
}