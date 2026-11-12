import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/models/safety_depth_model.dart';

class SafetyDepthScreen extends StatefulWidget {
  const SafetyDepthScreen({super.key});

  @override
  State<SafetyDepthScreen> createState() => _SafetyDepthScreenState();
}

class _SafetyDepthScreenState extends State<SafetyDepthScreen> {
  final _box = Hive.box('settings');
  final _form = GlobalKey<FormState>();

  // Vessel Particulars
  final _vesselNameCtrl = TextEditingController();
  final _lbpCtrl = TextEditingController();
  final _breadthCtrl = TextEditingController();
  String _cbMethod = calculateCbMethod;

  // Inputs
  final _foreCtrl = TextEditingController();
  final _aftCtrl = TextEditingController();
  final _dispCtrl = TextEditingController();
  final _densityCtrl = TextEditingController(text: '1.025');
  final _chartedDepthCtrl = TextEditingController();
  final _speedCtrl = TextEditingController();
  final _heelCtrl = TextEditingController(text: '0');
  final _densCorrCtrl = TextEditingController(text: '0');
  String? _catzoc = 'A1';

  SafetyDepthResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final data = _box.get('vessel_profile');
    if (data != null) {
      _vesselNameCtrl.text = data['name'] ?? '';
      _lbpCtrl.text = data['lbp']?.toString() ?? '';
      _breadthCtrl.text = data['breadth']?.toString() ?? '';
      _cbMethod = data['cbMethod'] ?? calculateCbMethod;
    }
  }

  void _saveProfile() {
    _box.put('vessel_profile', {
      'name': _vesselNameCtrl.text,
      'lbp': double.tryParse(_lbpCtrl.text.replaceAll(',', '.')),
      'breadth': double.tryParse(_breadthCtrl.text.replaceAll(',', '.')),
      'cbMethod': _cbMethod,
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vessel particulars saved.')));
  }

  void _calculate() {
    if (!_form.currentState!.validate()) return;
    if (_catzoc == null) {
      setState(() => _error = 'Select CATZOC.');
      return;
    }

    try {
      final vessel = VesselSafetySettings(
        name: _vesselNameCtrl.text.isEmpty ? 'Vessel' : _vesselNameCtrl.text,
        lengthBP: double.tryParse(_lbpCtrl.text.replaceAll(',', '.')) ?? 0,
        breadth: double.tryParse(_breadthCtrl.text.replaceAll(',', '.')) ?? 0,
        cbMethod: _cbMethod,
      );

      final input = SafetyDepthInput(
        foreDraft: double.tryParse(_foreCtrl.text.replaceAll(',', '.')) ?? 0,
        aftDraft: double.tryParse(_aftCtrl.text.replaceAll(',', '.')) ?? 0,
        displacementMT: double.tryParse(_dispCtrl.text.replaceAll(',', '.')) ?? 0,
        waterDensity: double.tryParse(_densityCtrl.text.replaceAll(',', '.')) ?? 1.025,
        chartedDepth: double.tryParse(_chartedDepthCtrl.text.replaceAll(',', '.')) ?? 0,
        speedThroughWater: double.tryParse(_speedCtrl.text.replaceAll(',', '.')) ?? 0,
        heelDegrees: double.tryParse(_heelCtrl.text.replaceAll(',', '.')) ?? 0,
        densityCorrection: double.tryParse(_densCorrCtrl.text.replaceAll(',', '.')) ?? 0,
        catzoc: _catzoc!,
        manualDepthAllowance: null, // Handle D/U logic if needed later
        depthAllowanceBasis: '',
      );

      final res = SafetyDepthResult.calculate(vessel, input);
      setState(() {
        _result = res;
        _error = null;
      });
    } on FormatException catch (e) {
      setState(() {
        _result = null;
        _error = e.message;
      });
    }
  }

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: cardSolid,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: border),
    ),
    child: child,
  );

  Widget _field(String label, TextEditingController ctrl, {bool isNum = false, String? helper}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (isNum && double.tryParse(v.replaceAll(',', '.')) == null) return 'Invalid number';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
        return AppScaffold(
      title: 'Safety Depth',
      actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: accent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: cardSolid,
                  title: const Text('Calculation Method'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Max Draft = MAX(Fore Draft, Aft Draft)\n'
                      'Mean Draft = (Fore Draft + Aft Draft) / 2\n'
                      'Cb = (Displacement / Water Density) / (LBP × Breadth × Mean Draft), or entered from vessel tables.\n'
                      'Safety Margin = 10% × Max Draft\n'
                      'Squat = Cb × STW² / 50\n'
                      'Heel Correction = 0.008 × Breadth × |Heel Angle in degrees|\n'
                      'Density Correction = manually entered value, initially 0 m.\n'
                      'ENC ZOC: A1 = 0.5 + 0.01d; A2/B = 1 + 0.02d; C = 2 + 0.05d.\n'
                      'D/U require a justified manual depth allowance and its basis. Without these, assessment is incomplete.\n\n'
                      'Safety Depth is the sum of Max Draft, Safety Margin, Squat, Heel Correction, Density Correction and ENC ZOC Correction.\n'
                      'd is the entered charted depth. Result is rounded upward to 0.01 m.\n\n'
                      'The configured squat and linear heel relations are approximations. Use them within the conditions applicable to the vessel. Mean fore/aft draught is a simple approximation. CATZOC depth accuracy is a 95% measure, not a guaranteed seabed limit. Do not add a density correction already included in the entered draughts. This calculation does not select an ECDIS contour or assess passage safety.',
                      style: TextStyle(color: textMuted, height: 1.5, fontSize: 13),
                    ),
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                ),
              );
                        },
          )
        ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // VESSEL PARTICULARS
            _card(Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Vessel Particulars', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _field('Vessel Name', _vesselNameCtrl),
                Row(
                  children: [
                    Expanded(child: _field('LBP (m)', _lbpCtrl, isNum: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _field('Breadth (m)', _breadthCtrl, isNum: true)),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: _cbMethod,
                  dropdownColor: cardSolid,
                  decoration: const InputDecoration(labelText: 'Cb Method', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: calculateCbMethod, child: Text('Calculate Cb')),
                    DropdownMenuItem(value: tableCbMethod, child: Text('Enter Cb from Tables')),
                  ],
                  onChanged: (v) => setState(() => _cbMethod = v!),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Vessel Particulars'),
                ),
              ],
            )),
            
            const SizedBox(height: 20),

            // CURRENT CONDITION
            Form(
              key: _form,
              child: _card(Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Current Condition', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _field('Fore Draft (m)', _foreCtrl, isNum: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _field('Aft Draft (m)', _aftCtrl, isNum: true)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _field('Displacement (t)', _dispCtrl, isNum: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _field('Water Density (t/m³)', _densityCtrl, isNum: true)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _field('Charted Depth (m)', _chartedDepthCtrl, isNum: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _field('Speed STW (kts)', _speedCtrl, isNum: true)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _field('Heel (°)', _heelCtrl, isNum: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _field('Density Corr. (m)', _densCorrCtrl, isNum: true)),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _catzoc,
                    dropdownColor: cardSolid,
                    decoration: const InputDecoration(labelText: 'CATZOC', border: OutlineInputBorder()),
                    items: ['A1', 'A2', 'B', 'C', 'D', 'U'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _catzoc = v),
                  ),
                  
                  if (_error != null)
                    Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error!, style: const TextStyle(color: Colors.amber))),
                  
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _calculate,
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Padding(padding: EdgeInsets.all(16), child: Text('Calculate Safety Depth')),
                    style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: bg),
                  ),
                ],
              )),
            ),

            // RESULT
            if (_result != null) ...[
              const SizedBox(height: 20),
              _card(Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('SAFETY DEPTH', style: TextStyle(color: textMuted, letterSpacing: 1.5)),
                  Text('${_result!.displayedDepth.toStringAsFixed(2)} m', style: const TextStyle(fontSize: 36, color: accent, fontWeight: FontWeight.bold)),
                  const Divider(color: border, height: 24),
                  ..._result!.calculationLines.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l.label, style: const TextStyle(color: textMuted, fontSize: 13)),
                        Text('${l.value.toStringAsFixed(3)} ${l.unit}', style: const TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  )),
                ],
              )),
            ],
          ],
        ),
      ),
    );
  }
}