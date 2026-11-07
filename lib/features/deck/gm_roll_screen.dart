import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/gm_roll_model.dart';
import '../../core/theme.dart';

class GmRollScreen extends StatefulWidget {
  const GmRollScreen({super.key});

  @override
  State<GmRollScreen> createState() => _GmRollScreenState();
}

class _GmRollScreenState extends State<GmRollScreen> {
  final _breadthCtrl = TextEditingController();
  final _coeffCtrl = TextEditingController(text: '0.8');
  final _timeCtrl = TextEditingController();
  final _cyclesCtrl = TextEditingController();
  String _result = '';

  void _calculate() {
    try {
      final breadth = double.parse(_breadthCtrl.text.replaceAll(',', '.'));
      final coeff = double.parse(_coeffCtrl.text.replaceAll(',', '.'));
      final time = double.parse(_timeCtrl.text.replaceAll(',', '.'));
      final cycles = int.parse(_cyclesCtrl.text);

      final estimate = GmRollEstimate.calculate(
        breadth: breadth, coefficient: coeff, elapsedSeconds: time, cycles: cycles,
      );

      setState(() {
        _result = 'GM: ${estimate.gm.toStringAsFixed(2)} m\nPeriod: ${estimate.periodSeconds.toStringAsFixed(2)} sec';
      });
    } catch (e) {
      setState(() => _result = 'Error: Check your inputs.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GM Estimate'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Декоративный заголовок
          const Text(
            'STABILITY CALCULATOR',
            style: TextStyle(color: gold, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _breadthCtrl,
            decoration: const InputDecoration(labelText: 'Breadth (m)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _coeffCtrl,
            decoration: const InputDecoration(labelText: 'Roll Coefficient', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _timeCtrl,
            decoration: const InputDecoration(labelText: 'Elapsed Time (sec)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cyclesCtrl,
            decoration: const InputDecoration(labelText: 'Whole Cycles', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [accentDark, accent]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 4))],
            ),
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('CALCULATE', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ),
          const SizedBox(height: 24),
          if (_result.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                border: Border.all(color: accent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _result,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Color(0xFF4ADE80), height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}