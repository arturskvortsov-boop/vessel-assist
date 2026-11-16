import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../../../core/palette_state.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/staggered_item.dart';
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
  
  // Вычисляемые поля
  String _meanDraftStr = '-';
  String _maxDraftStr = '-';
  String _cbUsedStr = '-';

  // --- Passage Conditions ---
  final _portCtrl = TextEditingController();
  String _waterType = 'Confined Water';
  final _speedCtrl = TextEditingController();
  bool _manualSquat = false;
  final _manualSquatCtrl = TextEditingController();
  final _minDepthCtrl = TextEditingController();
  final _tideCtrl = TextEditingController(text: '0.00');
  final _swellCtrl = TextEditingController(text: '0.00');
  String _catzoc = 'A1';



    // --- Advanced Overrides ---
  final _manualCbCtrl = TextEditingController();
  bool _useManualDepth = false;
  final _manualDepthCtrl = TextEditingController();
  final _depthBasisCtrl = TextEditingController();

  UkcResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _foreDraftCtrl.addListener(_updateLiveDrafts);
    _aftDraftCtrl.addListener(_updateLiveDrafts);
    _addMaxDraftCtrl.addListener(_updateLiveDrafts);
  }

  @override
  void dispose() {
    for (final controller in [_vesselNameCtrl, _lbpCtrl, _breadthCtrl, _foreDraftCtrl, _aftDraftCtrl, _addMaxDraftCtrl, _displacementCtrl, _waterDensityCtrl, _heelCtrl, _densCorrCtrl, _portCtrl, _speedCtrl, _manualSquatCtrl, _minDepthCtrl, _tideCtrl, _swellCtrl, _manualCbCtrl, _manualDepthCtrl, _depthBasisCtrl]) { controller.dispose(); }
    super.dispose();
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

  void _invalidate() {
    _result = null;
    _error = null;
    _cbUsedStr = '-';
  }

  double? _number(TextEditingController ctrl, String label, {double? fallback}) {
    final text = ctrl.text.trim();
    if (text.isEmpty) return fallback;
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null || !value.isFinite) {
      throw FormatException('Enter a valid number for $label.');
    }
    return value;
  }

  double _requiredNumber(TextEditingController ctrl, String label) =>
      _number(ctrl, label) ?? (throw FormatException('Enter $label.'));

  void _calculate() {
    try {
      final input = UkcInput(
        length: _number(_lbpCtrl, 'LBP', fallback: 0)!,
        breadth: _number(_breadthCtrl, 'breadth', fallback: 0)!,
        fore: _number(_foreDraftCtrl, 'forward draft', fallback: 0)!,
        aft: _number(_aftDraftCtrl, 'aft draft', fallback: 0)!,
        waterDensity: _number(_waterDensityCtrl, 'water density', fallback: 1.025)!,
        depth: _number(_minDepthCtrl, 'charted depth', fallback: 0)!,
        tide: _number(_tideCtrl, 'tide', fallback: 0)!,
        speed: _requiredNumber(_speedCtrl, 'speed'),
        heel: _number(_heelCtrl, 'heel', fallback: 0)!,
        swell: _number(_swellCtrl, 'swell correction', fallback: 0)!,
        densityCorrection: _number(_densCorrCtrl, 'density correction', fallback: 0)!,
        catzoc: _catzoc,
        confined: _waterType == 'Confined Water',
        
        maxDraft: _number(_addMaxDraftCtrl, 'additional maximum draft'),
        displacement: _cbMethod == 'Calculate Cb' ? _requiredNumber(_displacementCtrl, 'displacement') : null,
        manualCb: _cbMethod == 'Enter Cb from Tables' ? _requiredNumber(_manualCbCtrl, 'Cb') : null,
        manualSquat: _manualSquat ? _requiredNumber(_manualSquatCtrl, 'manual squat') : null,
        manualDepth: _useManualDepth ? _number(_manualDepthCtrl, 'manual depth allowance') : null,
        depthBasis: _depthBasisCtrl.text,
      );

      final res = UkcResult.calculate(input);
      
      setState(() {
        _result = res;
        _error = null;
        _cbUsedStr = res.cb.toStringAsFixed(2);
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
    PaletteState.set(AppSection.bridge);
        return AppScaffold(
      title: 'UKC Calculator',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StaggeredItem(
            index: 0,
            child: const Text(
              'Estimate under-keel clearance for the entered vessel and passage conditions.',
              style: TextStyle(color: textMuted, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
          
          const SizedBox(height: 16),

          // --- VESSEL PARTICULARS ---
          StaggeredItem(
            index: 1,
            child: _buildSection(
              title: 'Vessel Particulars',
              children: [
                _buildField('Vessel Name', _vesselNameCtrl, isNumber: false),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('LBP (m)', _lbpCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField('Breadth (m)', _breadthCtrl)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _cbMethod,
                  dropdownColor: cardSolid,
                  decoration: const InputDecoration(labelText: 'Cb Method', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'Calculate Cb', child: Text('Calculate Cb')),
                    DropdownMenuItem(value: 'Enter Cb from Tables', child: Text('Enter Cb from Tables')),
                  ],
                  onChanged: (val) => setState(() { _cbMethod = val!; _invalidate(); }),
                ),
              ],
            ),
          ),

          // --- CURRENT CONDITION ---
          StaggeredItem(
            index: 2,
            child: _buildSection(
              title: 'Current Condition',
              children: [
                Row(
                  children: [
                    Expanded(child: _buildField('Fore Draft (m)', _foreDraftCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField('Aft Draft (m)', _aftDraftCtrl)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField('Additional Max Draft (m)', _addMaxDraftCtrl, helper: 'Optional'),
                const SizedBox(height: 8),
                _buildReadOnlyRow('Mean Draft:', '$_meanDraftStr m'),
                _buildReadOnlyRow('Maximum Draft:', '$_maxDraftStr m'),
                Divider(color: border, height: 24),
                if (_cbMethod == 'Enter Cb from Tables')
                  _buildField('Cb Value', _manualCbCtrl)
                else
                  _buildField('Displacement (t)', _displacementCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('Water Density (t/m³)', _waterDensityCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField('Heel (°)', _heelCtrl, signed: true)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildReadOnlyRow('Cb used:', _cbUsedStr),
                _buildField('Density Correction (m)', _densCorrCtrl),
              ],
            ),
          ),

          // --- PASSAGE CONDITIONS ---
          StaggeredItem(
            index: 3,
            child: _buildSection(
              title: 'Passage Conditions',
              children: [
                _buildField('Port / Location', _portCtrl, isNumber: false),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _waterType,
                  dropdownColor: cardSolid,
                  decoration: const InputDecoration(labelText: 'Water Type', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'Confined Water', child: Text('Confined Water')),
                    DropdownMenuItem(value: 'Open Water', child: Text('Open Water')),
                  ],
                  onChanged: (val) => setState(() { _waterType = val!; _invalidate(); }),
                ),
                const SizedBox(height: 12),
                _buildField('Speed Through Water (kn)', _speedCtrl),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text('Manual Squat', style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w600)),
                  value: _manualSquat,
                  activeThumbColor: accent,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() { _manualSquat = val; _invalidate(); }),
                ),
                if (_manualSquat) 
                  _buildField('Squat at Entered STW (m)', _manualSquatCtrl),
                const SizedBox(height: 12),
                _buildField('Minimum Charted Depth (m)', _minDepthCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('Tide / Water Level (m)', _tideCtrl, signed: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField('Swell Correction (m)', _swellCtrl)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _catzoc,
                  dropdownColor: cardSolid,
                  decoration: const InputDecoration(labelText: 'CATZOC', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'A1', child: Text('A1')),
                    DropdownMenuItem(value: 'A2', child: Text('A2')),
                    DropdownMenuItem(value: 'B', child: Text('B')),
                    DropdownMenuItem(value: 'C', child: Text('C')),
                    DropdownMenuItem(value: 'D', child: Text('D')),
                    DropdownMenuItem(value: 'U', child: Text('U')),
                  ],
                  onChanged: (val) => setState(() { _catzoc = val!; _invalidate(); }),
                ),
              ],
            ),
          ),

          // --- ADVANCED OVERRIDES ---
          StaggeredItem(
            index: 4,
            child: GlassCard(
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Material(
                  type: MaterialType.transparency,
                  child: ExpansionTile(
                                    title: Text('Advanced Overrides', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                  iconColor: accent,
                  children: [
                    
                    SwitchListTile(
                      title: const Text('Manual Depth Allowance (D/U)', style: TextStyle(color: text, fontSize: 14)),
                      value: _useManualDepth,
                      activeThumbColor: accent,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() { _useManualDepth = val; _invalidate(); }),
                    ),
                    if (_useManualDepth) ...[
                      _buildField('Allowance (m)', _manualDepthCtrl),
                      _buildField('Basis / Justification', _depthBasisCtrl, isNumber: false),
                    ]
                  ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Кнопка расчета с градиентом
          StaggeredItem(
            index: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accentDark, accent]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: Icon(Icons.calculate, color: bg),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 55),
                ),
                label: Text('CALCULATE UKC', style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 24),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],

          // --- РЕЗУЛЬТАТ ---
          if (_result != null && _result!.complete) ...[
            const SizedBox(height: 24),
            StaggeredItem(
              index: 6,
              child: GlassCard(
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
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(color: border, height: 32),
                      ..._result!.details.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(d, style: const TextStyle(color: text, fontSize: 12, height: 1.4)),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (_result != null && !_result!.complete) ...[
             const SizedBox(height: 24),
             const Text("Incomplete Assessment: Check CATZOC D/U requirements.", style: TextStyle(color: Colors.orangeAccent)),
          ],

          // --- ABOUT THIS CALCULATION ---
          const SizedBox(height: 16),
          StaggeredItem(
            index: 7,
            child: GlassCard(
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Material(
                  type: MaterialType.transparency,
                  child: ExpansionTile(
                  title: Text('About This Calculation', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                  iconColor: accent,
                  collapsedIconColor: textMuted,
                  childrenPadding: const EdgeInsets.all(16),
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
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title, style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                type: MaterialType.transparency,
                child: Column(children: children),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    bool isNumber = true,
    String? helper,
    bool signed = false,
  }) {
    final pattern = signed ? _signedNumber : _unsignedNumber;
    return TextField(
      controller: ctrl,
      onChanged: (_) {
        if (_result != null || _error != null) setState(_invalidate);
      },
      inputFormatters: isNumber
          ? [
              TextInputFormatter.withFunction(
                (previous, next) => pattern.hasMatch(next.text)
                    ? next
                    : previous,
              ),
            ]
          : null,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: isNumber
          ? TextInputType.numberWithOptions(decimal: true, signed: signed)
          : TextInputType.text,
    );
  }

  static final _signedNumber = RegExp(r'^-?\d*([.,]\d*)?$');
  static final _unsignedNumber = RegExp(r'^\d*([.,]\d*)?$');

  Widget _buildReadOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
