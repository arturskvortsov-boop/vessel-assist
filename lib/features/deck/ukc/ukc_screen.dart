import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../domain/models/ukc_model.dart';

class UkcScreen extends StatefulWidget {
  const UkcScreen({super.key});

  @override
  State<UkcScreen> createState() => _UkcScreenState();
}

class _UkcScreenState extends State<UkcScreen> {
  // --- Vessel Particulars ---
  final _vesselNameCtrl = TextEditingController();
  final _lbpCtrl = TextEditingController();
  final _breadthCtrl = TextEditingController();
  String _cbMethod = 'Calculate Cb';

  // --- Current Condition ---
  final _foreDraftCtrl = TextEditingController();
  final _aftDraftCtrl = TextEditingController();
  final _addMaxDraftCtrl = TextEditingController();
  final _displacementCtrl = TextEditingController();
  final _waterDensityCtrl = TextEditingController();
  final _heelCtrl = TextEditingController();
  final _densCorrCtrl = TextEditingController();
  
  // Вычисляемые поля (для отображения)
  String _meanDraftStr = '-';
  String _maxDraftStr = '-';
  String _cbUsedStr = '-';

  // --- Passage Conditions ---
  final _portCtrl = TextEditingController();
  String _waterType = 'Confined Water';
  final _speedCtrl = TextEditingController();
  bool _manualSquat = false;
  final _manualSquatCtrl = TextEditingController(); // <--- ВОТ ЭТА СТРОКА ПОТЕРЯЛАСЬ
  final _minDepthCtrl = TextEditingController();
  final _tideCtrl = TextEditingController(text: '0.00');
  final _swellCtrl = TextEditingController(text: '0.00');
  String _catzoc = 'A1';

  // --- Advanced Overrides ---
  bool _useManualCb = false;
  final _manualCbCtrl = TextEditingController();
  bool _useManualDepth = false;
  final _manualDepthCtrl = TextEditingController();
  final _depthBasisCtrl = TextEditingController();

  UkcResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Автоматический пересчет Mean/Max Draft при вводе осадок
    _foreDraftCtrl.addListener(_updateLiveDrafts);
    _aftDraftCtrl.addListener(_updateLiveDrafts);
    _addMaxDraftCtrl.addListener(_updateLiveDrafts);
  }

  void _updateLiveDrafts() {
    final fore = double.tryParse(_foreDraftCtrl.text.replaceAll(',', '.')) ?? 0;
    final aft = double.tryParse(_aftDraftCtrl.text.replaceAll(',', '.')) ?? 0;
    final addMax = double.tryParse(_addMaxDraftCtrl.text.replaceAll(',', '.')) ?? 0;

    if (fore > 0 && aft > 0) {
      setState(() {
        _meanDraftStr = ((fore + aft) / 2).toStringAsFixed(2);
        _maxDraftStr = [fore, aft, addMax].reduce((a, b) => a > b ? a : b).toStringAsFixed(2);
      });
    } else {
      setState(() {
        _meanDraftStr = '-';
        _maxDraftStr = '-';
      });
    }
  }

  void _calculate() {
    try {
      final input = UkcInput(
        length: double.tryParse(_lbpCtrl.text.replaceAll(',', '.')) ?? 0,
        breadth: double.tryParse(_breadthCtrl.text.replaceAll(',', '.')) ?? 0,
        fore: double.tryParse(_foreDraftCtrl.text.replaceAll(',', '.')) ?? 0,
        aft: double.tryParse(_aftDraftCtrl.text.replaceAll(',', '.')) ?? 0,
        waterDensity: double.tryParse(_waterDensityCtrl.text.replaceAll(',', '.')) ?? 1.025,
        depth: double.tryParse(_minDepthCtrl.text.replaceAll(',', '.')) ?? 0,
        tide: double.tryParse(_tideCtrl.text.replaceAll(',', '.')) ?? 0,
        speed: double.tryParse(_speedCtrl.text.replaceAll(',', '.')) ?? 0,
        heel: double.tryParse(_heelCtrl.text.replaceAll(',', '.')) ?? 0,
        swell: double.tryParse(_swellCtrl.text.replaceAll(',', '.')) ?? 0,
        densityCorrection: double.tryParse(_densCorrCtrl.text.replaceAll(',', '.')) ?? 0,
        catzoc: _catzoc,
        confined: _waterType == 'Confined Water',
        
        maxDraft: double.tryParse(_addMaxDraftCtrl.text.replaceAll(',', '.')) != null 
            ? double.tryParse(_addMaxDraftCtrl.text.replaceAll(',', '.')) 
            : null,
        displacement: double.tryParse(_displacementCtrl.text.replaceAll(',', '.')),
        manualCb: _useManualCb ? double.tryParse(_manualCbCtrl.text.replaceAll(',', '.')) : null,
        manualSquat: _manualSquat ? double.tryParse(_manualSquatCtrl.text.replaceAll(',', '.')) : null,
        manualDepth: _useManualDepth ? double.tryParse(_manualDepthCtrl.text.replaceAll(',', '.')) : null,
        depthBasis: _depthBasisCtrl.text,
      );

      final res = UkcResult.calculate(input);
      
      double? calculatedCb = res.cb; // Берем Cb из результата
      
      setState(() {
        _result = res;
        _error = null;
        _cbUsedStr = calculatedCb?.toStringAsFixed(2) ?? '-';
      });
    } on FormatException catch (e) {
      setState(() {
        _result = null;
        _error = e.message;
        _cbUsedStr = '-';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UKC Calculator'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Estimate under-keel clearance for the entered vessel and passage conditions.',
            style: TextStyle(color: textMuted, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),

          // --- VESSEL PARTICULARS ---
          _buildSection(
            title: 'Vessel Particulars',
            children: [
              _buildField('Vessel Name', _vesselNameCtrl, isNumber: false),
              _buildField('LBP (m)', _lbpCtrl),
              _buildField('Breadth (m)', _breadthCtrl),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _cbMethod,
                dropdownColor: cardSolid,
                decoration: const InputDecoration(labelText: 'Cb Method'),
                items: const [
                  DropdownMenuItem(value: 'Calculate Cb', child: Text('Calculate Cb')),
                  DropdownMenuItem(value: 'Enter Cb from Tables', child: Text('Enter Cb from Tables')),
                ],
                onChanged: (val) => setState(() => _cbMethod = val!),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  // Здесь в будущем можно сохранять в Hive
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vessel Settings Saved!')));
                },
                icon: const Icon(Icons.save, color: accent),
                label: const Text('Save Vessel Settings'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
              )
            ]
          ),

          // --- CURRENT CONDITION ---
          _buildSection(
            title: 'Current Condition',
            children: [
              _buildField('Fore Draft (m)', _foreDraftCtrl),
              _buildField('Aft Draft (m)', _aftDraftCtrl),
              _buildField('Additional Max Draft (m)', _addMaxDraftCtrl, helper: 'Optional: enter a known deeper static draft. The greatest entered draft is used.'),
              _buildReadOnlyField('Mean Draft — automatic:', '$_meanDraftStr m'),
              _buildReadOnlyField('Maximum Draft — automatic:', '$_maxDraftStr m'),
              _buildField('Displacement (t)', _displacementCtrl),
              _buildField('Water Density (t/m³)', _waterDensityCtrl),
              _buildReadOnlyField('Cb used:', _cbUsedStr),
              _buildField('Heel Angle (°)', _heelCtrl),
              _buildField('Density Correction (m)', _densCorrCtrl, helper: 'Leave 0 if the entered drafts already reflect the current water density.'),
            ]
          ),

          // --- PASSAGE CONDITIONS ---
          _buildSection(
            title: 'Passage Conditions',
            children: [
              _buildField('Port / Location', _portCtrl, isNumber: false),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _waterType,
                dropdownColor: cardSolid,
                decoration: const InputDecoration(labelText: 'Water Type'),
                items: const [
                  DropdownMenuItem(value: 'Confined Water', child: Text('Confined Water')),
                  DropdownMenuItem(value: 'Open Water', child: Text('Open Water')),
                ],
                onChanged: (val) => setState(() => _waterType = val!),
              ),
              const SizedBox(height: 8),
              _buildField('Speed Through Water (kn)', _speedCtrl),
              SwitchListTile(
                title: const Text('Manual Squat', style: TextStyle(color: text, fontSize: 14)),
                value: _manualSquat,
                activeColor: accent,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _manualSquat = val),
              ),
              if (_manualSquat) 
                _buildField('Squat at Entered STW (m)', _manualSquatCtrl), // <--- ДОБАВИЛИ ЭТУ СТРОКУ
              _buildField('Minimum Charted Depth (m)', _minDepthCtrl),
              _buildField('Tide / Water Level (m)', _tideCtrl, helper: 'Use the same vertical datum as the charted depth; negative values are allowed.'),
              _buildField('Swell Correction (m)', _swellCtrl, helper: 'Allowance for wave-induced vertical motion, not simply wave height. Zero means no allowance included; review for the passage.'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _catzoc,
                dropdownColor: cardSolid,
                decoration: const InputDecoration(labelText: 'CATZOC'),
                items: const [
                  DropdownMenuItem(value: 'A1', child: Text('A1')),
                  DropdownMenuItem(value: 'A2', child: Text('A2')),
                  DropdownMenuItem(value: 'B', child: Text('B')),
                  DropdownMenuItem(value: 'C', child: Text('C')),
                  DropdownMenuItem(value: 'D', child: Text('D')),
                  DropdownMenuItem(value: 'U', child: Text('U')),
                ],
                onChanged: (val) => setState(() => _catzoc = val!),
              ),
            ]
          ),

          // --- ADVANCED OVERRIDES ---
          _buildSection(
            title: 'Advanced Overrides (Optional)',
            initiallyExpanded: false,
            children: [
              SwitchListTile(
                title: const Text('Manual Cb', style: TextStyle(color: text, fontSize: 14)),
                value: _useManualCb,
                activeColor: accent,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _useManualCb = val),
              ),
              if (_useManualCb) _buildField('Cb Value', _manualCbCtrl),
              
              SwitchListTile(
                title: const Text('Manual Depth Allowance (CATZOC D/U)', style: TextStyle(color: text, fontSize: 14)),
                value: _useManualDepth,
                activeColor: accent,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _useManualDepth = val),
              ),
              if (_useManualDepth) ...[
                _buildField('Allowance (m)', _manualDepthCtrl),
                _buildField('Basis / Justification', _depthBasisCtrl, isNumber: false),
              ]
            ]
          ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: const Color(0xFF64FFDA), // Цвет как на скрине справа
              foregroundColor: bg,
            ),
            label: const Text('Calculate UKC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),

          if (_error != null) ...[
            const SizedBox(height: 24),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],

          // --- РЕЗУЛЬТАТ ---
          if (_result != null && _result!.complete) ...[
            const SizedBox(height: 24),
            GlassCard(
              glowColor: _result!.calculatedUkc! < 0.5 ? Colors.redAccent : Colors.greenAccent,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('CALCULATED UKC', style: TextStyle(color: textMuted, letterSpacing: 1.5, fontSize: 12)),
                    const SizedBox(height: 12),
                    Text(
                      '${ukcDisplay(_result!.calculatedUkc!)} m',
                      style: TextStyle(
                        color: _result!.calculatedUkc! < 0.5 ? Colors.redAccent : Colors.greenAccent,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: border, height: 32),
                    ..._result!.details.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(d, style: const TextStyle(color: text, fontSize: 12, height: 1.4)),
                    )),
                  ],
                ),
              ),
            ),
          ] else if (_result != null && !_result!.complete) ...[
             const SizedBox(height: 24),
             const Text("Incomplete Assessment: Check CATZOC D/U requirements.", style: TextStyle(color: Colors.orangeAccent)),
          ],

          // --- ABOUT THIS CALCULATION ---
          const SizedBox(height: 16),
          GlassCard(
            child: ExpansionTile(
              title: const Text('About This Calculation', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
              iconColor: accent,
              collapsedIconColor: textMuted,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cb = displacement / (density × LBP × breadth × mean draft), or manual.', style: TextStyle(color: textMuted, fontSize: 12, height: 1.5)),
                      const SizedBox(height: 8),
                      const Text('Squat = Cb × STW² / 50 (confined) or / 100 (open), unless manual.', style: TextStyle(color: textMuted, fontSize: 12, height: 1.5)),
                      const SizedBox(height: 8),
                      const Text('Heel allowance = breadth / 2 × tan(abs(heel in degrees) × pi / 180).', style: TextStyle(color: textMuted, fontSize: 12, height: 1.5)),
                      const SizedBox(height: 8),
                      const Text('CATZOC allowance: A1 = 0.5 + 0.01d; A2/B = 1 + 0.02d; C = 2 + 0.05d. D/U require justified manual input.', style: TextStyle(color: textMuted, fontSize: 12, height: 1.5)),
                      const SizedBox(height: 8),
                      const Text('Calculated UKC = charted depth + level − maximum draft − density correction − depth allowance − squat − heel allowance − swell allowance.', style: TextStyle(color: textMuted, fontSize: 12, height: 1.5)),
                      const SizedBox(height: 16),
                      const Text('These are approximate selected methods, not a universal IMO formula. Use a passage plan that accounts for additional uncertainties within the relevant allowances. Avoid coastal navigation where charting does not guarantee detection of every obstruction. A manual D/U allowance cannot replace survey reliability. This calculation is not a passage-safety approval.', style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontStyle: FontStyle.italic, height: 1.5)),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children, bool initiallyExpanded = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: ExpansionTile(
          title: Text(title, style: const TextStyle(color: accent, fontWeight: FontWeight.bold)),
          initiallyExpanded: initiallyExpanded,
          iconColor: accent,
          collapsedIconColor: textMuted,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: children),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {bool isNumber = true, String? helper}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
        ),
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: accent, fontSize: 14)),
          Text(value, style: const TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}