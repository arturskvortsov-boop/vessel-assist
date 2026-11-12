import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_scaffold.dart';

class PumpScreen extends StatefulWidget {
  const PumpScreen({super.key});

  @override
  State<PumpScreen> createState() => _PumpScreenState();
}

class _PumpScreenState extends State<PumpScreen> {
  final _volCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _currVolCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  String _result = '';
  Color _resultColor = text;

  void _calculate() {
    final vol = double.tryParse(_volCtrl.text.replaceAll(',', '.')) ?? 0;
    final rate = double.tryParse(_rateCtrl.text.replaceAll(',', '.')) ?? 0;
    final currVol = double.tryParse(_currVolCtrl.text.replaceAll(',', '.')) ?? 0;
    final cap = double.tryParse(_capCtrl.text.replaceAll(',', '.')) ?? 0;

    if (vol <= 0 || rate <= 0 || cap <= 0) {
      setState(() {
        _result = 'Please enter valid Volume, Rate, and Capacity.';
        _resultColor = Colors.redAccent;
      });
      return;
    }

    final hoursDecimal = vol / rate;
    final hours = hoursDecimal.floor();
    final minutes = ((hoursDecimal - hours) * 60).round();
    
    final finalVol = currVol + vol;
    final isOverflow = finalVol > cap;

    setState(() {
      _result = 'Transfer Time: $hours h $minutes min\n'
          'Total Volume in Tank: ${finalVol.toStringAsFixed(1)} m³ / ${cap.toStringAsFixed(1)} m³\n\n';
      
      if (isOverflow) {
        _resultColor = Colors.redAccent;
        _result += '⚠️ WARNING: OVERFLOW BY ${(finalVol - cap).toStringAsFixed(1)} m³!\nMax safe transfer: ${(cap - currVol).toStringAsFixed(1)} m³.';
      } else {
        _resultColor = Colors.greenAccent;
        _result += '✅ SAFE. Space remaining: ${(cap - finalVol).toStringAsFixed(1)} m³.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
        return AppScaffold(
      title: 'Pump Calculator',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Calculate transfer time and check for overflow in the receiving tank.',
            style: TextStyle(color: textMuted, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextField(controller: _volCtrl, decoration: const InputDecoration(labelText: 'Volume to Transfer (m³)'), keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _rateCtrl, decoration: const InputDecoration(labelText: 'Pump Rate (m³/h)'), keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: border),
          const SizedBox(height: 8),
          const Text('Receiving Tank:', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: _currVolCtrl, decoration: const InputDecoration(labelText: 'Current Vol (m³)'), keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _capCtrl, decoration: const InputDecoration(labelText: 'Tank Capacity (m³)'), keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculate,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text('CALCULATE'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), border: Border.all(color: _resultColor), borderRadius: BorderRadius.circular(12)),
              child: Text(_result, style: TextStyle(color: _resultColor, fontFamily: 'monospace', fontSize: 14, height: 1.5)),
            ),
          ]
        ],
      ),
    );
  }
}