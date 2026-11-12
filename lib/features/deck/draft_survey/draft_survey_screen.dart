import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'draft_marks_diagram.dart';
import 'draft_survey.dart';

const _stations = ['FWD', 'MID', 'AFT'];
const _deductibles = [
  ('ballast', 'Ballast'),
  ('freshWater', 'Fresh water'),
  ('fuelOil', 'Fuel oil'),
  ('dieselOil', 'Diesel oil'),
  ('lubeOil', 'Lubricating oil'),
  ('slops', 'Slops'),
  ('sludge', 'Sludge'),
  ('other', 'Other variable weights'),
];

class DraftSurveyScreen extends StatefulWidget {
  const DraftSurveyScreen({super.key});

  @override
  State<DraftSurveyScreen> createState() => _DraftSurveyScreenState();
}

class _DraftSurveyScreenState extends State<DraftSurveyScreen> {
  final _fields = <String, TextEditingController>{};
  final _focus = List.generate(6, (_) => FocusNode());
  final _lcf = [LcfReference.forwardOfMidships, LcfReference.forwardOfMidships];
  Box<dynamic>? _box;
  bool _ready = false;
  bool _saving = false;
  bool _starboard = false;
  int? _station;
  int _step = 0;
  CargoOperation _operation = CargoOperation.loading;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _focus.length; i++) {
      _focus[i].addListener(() {
        if (!_focus[i].hasFocus || !mounted) return;
        setState(() {
          _starboard = i.isOdd;
          _station = i ~/ 2;
        });
      });
    }
    _restore();
  }

  Future<void> _restore() async {
    try {
      final box = await Hive.openBox<dynamic>('deck_draft_survey');
      if (!mounted) return;
      _box = box;
      final saved = box.get('current');
      if (saved is Map) {
        final fields = saved['fields'];
        if (fields is Map) {
          for (final entry in fields.entries) {
            if (entry.key is String && entry.value is String) {
              _controller(entry.key as String).text = entry.value as String;
            }
          }
        }
        _operation = saved['discharging'] == true
            ? CargoOperation.discharging
            : CargoOperation.loading;
        final references = saved['lcf'];
        if (references is List) {
          for (var i = 0; i < _lcf.length && i < references.length; i++) {
            for (final value in LcfReference.values) {
              if (value.name == references[i]) _lcf[i] = value;
            }
          }
        }
      }
    } catch (_) {
      if (mounted) _notice('Unable to open local survey storage.');
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _save() async {
    final box = _box;
    if (box == null || _saving) return;
    setState(() => _saving = true);
    try {
      await box.put('current', {
        'fields': _fields.map((key, value) => MapEntry(key, value.text)),
        'discharging': _operation == CargoOperation.discharging,
        'lcf': _lcf.map((value) => value.name).toList(),
      });
      if (mounted) _notice('Survey saved on this device.');
    } catch (_) {
      if (mounted) _notice('Unable to save the survey.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _notice(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  TextEditingController _controller(String key) =>
      _fields.putIfAbsent(key, TextEditingController.new);

  double? _number(
    String key, {
    double? minimum = 0,
    bool strictlyPositive = false,
  }) {
    final raw = _fields[key]?.text.trim() ?? '';
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null ||
        !value.isFinite ||
        (minimum != null && value < minimum) ||
        (strictlyPositive && value <= 0)) {
      return null;
    }
    return value;
  }

  DraftGeometry? get _geometry {
    final lbp = _number('lbp', strictlyPositive: true);
    final density = _number('tableDensity', strictlyPositive: true);
    final fwd = _number('markFwd', minimum: null);
    final mid = _number('markMid', minimum: null);
    final aft = _number('markAft', minimum: null);
    if (lbp == null ||
        density == null ||
        fwd == null ||
        mid == null ||
        aft == null) {
      return null;
    }
    return (
      lbp: lbp,
      marks: (forward: fwd, midship: mid, aft: aft),
      tableDensity: density,
    );
  }

  CorrectedDrafts? _drafts(int survey, DraftGeometry? geometry) {
    if (geometry == null) return null;
    final values = List.generate(
      6,
      (i) => _number('${survey}draft$i', strictlyPositive: true),
    );
    if (values.any((value) => value == null)) return null;
    return correctDrafts(
      geometry,
      DraftReadings(
        (forward: values[0]!, midship: values[2]!, aft: values[4]!),
        (forward: values[1]!, midship: values[3]!, aft: values[5]!),
      ),
    );
  }

  SurveyResult? _result(int survey) {
    final geometry = _geometry;
    final drafts = _drafts(survey, geometry);
    if (geometry == null || drafts == null) return null;
    final displacement = _number(
      '${survey}displacement',
      strictlyPositive: true,
    );
    final tpc = _number('${survey}tpc', strictlyPositive: true);
    final mctcPlus = _number('${survey}mctcPlus', strictlyPositive: true);
    final mctcMinus = _number('${survey}mctcMinus', strictlyPositive: true);
    final lcf = _number('${survey}lcf');
    final density = _number('${survey}density', strictlyPositive: true);
    final list = _number('${survey}list');
    if (displacement == null ||
        tpc == null ||
        mctcPlus == null ||
        mctcMinus == null ||
        lcf == null ||
        density == null ||
        list == null) {
      return null;
    }
    var deductions = 0.0;
    for (final (key, _) in _deductibles) {
      final field = '$survey$key';
      if (key != 'ballast' && (_fields[field]?.text.trim().isEmpty ?? true)) {
        continue;
      }
      final value = _number(field);
      if (value == null) return null;
      deductions += value;
    }
    final result = calculateSurvey(
      geometry: geometry,
      drafts: drafts,
      hydro: (
        displacement: displacement,
        tpc: tpc,
        lcfForward: _lcf[survey].forwardOfMidship(lcf, geometry.lbp),
        mctcPlus: mctcPlus,
        mctcMinus: mctcMinus,
      ),
      waterDensity: density,
      listCorrection: list,
      deductibles: deductions,
    );
    return result.net.isFinite && result.net > 0 ? result : null;
  }

  Widget _field(
    String key,
    String label,
    String unit, {
    bool signed = false,
    bool positive = false,
    FocusNode? focus,
  }) {
    final controller = _controller(key);
    final invalid =
        controller.text.trim().isNotEmpty &&
        _number(key, minimum: signed ? null : 0, strictlyPositive: positive) ==
            null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        focusNode: focus,
        keyboardType: TextInputType.numberWithOptions(
          decimal: true,
          signed: signed,
        ),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          errorText: invalid ? 'Check value' : null,
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    ),
  );

  List<Widget> _setup() => [
    _section('Operation', [
      SegmentedButton<CargoOperation>(
        segments: const [
          ButtonSegment(value: CargoOperation.loading, label: Text('Loading')),
          ButtonSegment(
            value: CargoOperation.discharging,
            label: Text('Discharging'),
          ),
        ],
        selected: {_operation},
        showSelectedIcon: false,
        onSelectionChanged: (value) =>
            setState(() => _operation = value.single),
      ),
    ]),
    _section('Vessel data', [
      _field('lbp', 'Length between perpendiculars (LBP)', 'm', positive: true),
      _field(
        'tableDensity',
        'Hydrostatic table reference density',
        't/m³',
        positive: true,
      ),
      const Text(
        'Enter the position of each draft mark relative to its reference. Forward is +, aft is −. Enter 0 when aligned.',
      ),
      const SizedBox(height: 10),
      _field(
        'markFwd',
        'FWD mark from forward perpendicular',
        'm',
        signed: true,
      ),
      _field('markMid', 'MID mark from midships', 'm', signed: true),
      _field('markAft', 'AFT mark from aft perpendicular', 'm', signed: true),
    ]),
  ];

  List<Widget> _survey(int index) {
    final drafts = _drafts(index, _geometry);
    final quarter = drafts?.quarterMean;
    final trim = drafts?.trimByStern;
    return [
      _section('Observed drafts', [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Port')),
            ButtonSegment(value: true, label: Text('Starboard')),
          ],
          selected: {_starboard},
          showSelectedIcon: false,
          onSelectionChanged: (value) =>
              setState(() => _starboard = value.single),
        ),
        DraftMarksDiagram(
          starboard: _starboard,
          selectedStation: _station,
          trimByStern: trim,
          onSelect: (station) =>
              _focus[station * 2 + (_starboard ? 1 : 0)].requestFocus(),
        ),
        if (trim != null)
          Text(
            'Corrected trim · ${trim == 0 ? 'Even keel' : '${trim.abs().toStringAsFixed(3)} m by ${trim > 0 ? 'stern' : 'head'}'}',
          ),
        for (var i = 0; i < 3; i++)
          Row(
            children: [
              Expanded(
                child: _field(
                  '${index}draft${2 * i}',
                  '${_stations[i]} Port',
                  'm',
                  positive: true,
                  focus: _focus[2 * i],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(
                  '${index}draft${2 * i + 1}',
                  '${_stations[i]} STBD',
                  'm',
                  positive: true,
                  focus: _focus[2 * i + 1],
                ),
              ),
            ],
          ),
        _field(
          '${index}density',
          'Measured dock water density',
          't/m³',
          positive: true,
        ),
        if (drafts != null)
          ExpansionTile(
            title: const Text('Draft corrections'),
            children: [
              _draftLine(
                'FWD',
                drafts.observed.forward,
                drafts.corrected.forward,
              ),
              _draftLine(
                'MID',
                drafts.observed.midship,
                drafts.corrected.midship,
              ),
              _draftLine('AFT', drafts.observed.aft, drafts.corrected.aft),
              Text(
                'Hull deflection · ${(drafts.deflection * 100).toStringAsFixed(2)} cm',
              ),
            ],
          ),
      ]),
      _section('Hydrostatics · manual input', [
        Text(
          quarter == null
              ? 'Complete Vessel setup and enter all six drafts to see the lookup drafts.'
              : 'Quarter mean draft · ${quarter.toStringAsFixed(4)} m',
        ),
        const SizedBox(height: 10),
        _field(
          '${index}displacement',
          'Tabular displacement',
          't',
          positive: true,
        ),
        _field('${index}tpc', 'TPC', 't/cm', positive: true),
        DropdownButtonFormField<LcfReference>(
          key: ValueKey('lcf$index'),
          initialValue: _lcf[index],
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'LCF position'),
          items: [
            for (final reference in LcfReference.values)
              DropdownMenuItem(value: reference, child: Text(reference.label)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _lcf[index] = value);
          },
        ),
        const SizedBox(height: 10),
        _field('${index}lcf', 'LCF distance', 'm'),
        if (quarter != null)
          Text(
            'MCTC lookup · ${(quarter + 0.5).toStringAsFixed(4)} m and ${(quarter - 0.5).toStringAsFixed(4)} m',
          ),
        const SizedBox(height: 10),
        _field(
          '${index}mctcPlus',
          'MCTC at draft +0.50 m',
          't·m/cm',
          positive: true,
        ),
        _field(
          '${index}mctcMinus',
          'MCTC at draft −0.50 m',
          't·m/cm',
          positive: true,
        ),
        _field('${index}list', 'List correction at table density', 't'),
        const Text(
          'Enter a verified list correction or enter 0 if none applies. Use hydrostatic values before trim and density corrections.',
        ),
      ]),
      _section('Deductible weights', [
        const Text(
          'Enter total ballast from the ship’s tank calculations. Blank entries for other weights count as zero.',
        ),
        const SizedBox(height: 10),
        for (final (key, label) in _deductibles)
          _field('$index$key', label, 't'),
      ]),
    ];
  }

  Widget _draftLine(String station, double before, double after) {
    final correction = (after - before) * 100;
    return Text(
      '$station · ${before.toStringAsFixed(3)} → ${after.toStringAsFixed(3)} m '
      '(${correction >= 0 ? '+' : ''}${correction.toStringAsFixed(2)} cm)',
    );
  }

  Widget _details(String title, SurveyResult result) => ExpansionTile(
    title: Text(title),
    subtitle: Text('Net displacement · ${result.net.toStringAsFixed(2)} t'),
    children: [
      _draftLine(
        'FWD',
        result.drafts.observed.forward,
        result.drafts.corrected.forward,
      ),
      _draftLine(
        'MID',
        result.drafts.observed.midship,
        result.drafts.corrected.midship,
      ),
      _draftLine(
        'AFT',
        result.drafts.observed.aft,
        result.drafts.corrected.aft,
      ),
      Text(
        'Quarter mean draft · ${result.drafts.quarterMean.toStringAsFixed(4)} m',
      ),
      Text('First trim correction · ${result.firstTrim.toStringAsFixed(2)} t'),
      Text(
        'Second trim correction · ${result.secondTrim.toStringAsFixed(2)} t',
      ),
      Text('List correction · ${result.listCorrection.toStringAsFixed(2)} t'),
      Text(
        'Displacement at table density · ${result.displacementAtTableDensity.toStringAsFixed(2)} t',
      ),
      Text(
        'Density-corrected displacement · ${result.displacement.toStringAsFixed(2)} t',
      ),
      Text('Total deductibles · ${result.deductibles.toStringAsFixed(2)} t'),
    ],
  );

  List<Widget> _summary() {
    final initial = _result(0);
    final finalSurvey = _result(1);
    final amount = initial == null || finalSurvey == null
        ? null
        : cargoChange(_operation, initial, finalSurvey);
    return [
      if (amount == null)
        const Text(
          'Complete Vessel setup and both surveys. Check the draft mark positions, hydrostatic values, ballast and list correction.',
        ),
      if (amount != null)
        _section('Estimated cargo quantity', [
          if (amount < 0)
            Text(
              'The change in net displacement conflicts with the selected operation.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else
            Text(
              '${_operation == CargoOperation.loading ? 'Cargo loaded' : 'Cargo discharged'} · ${amount.toStringAsFixed(2)} t',
              style: Theme.of(context).textTheme.titleLarge,
            ),
        ]),
      if (initial != null) _details('Initial survey', initial),
      if (finalSurvey != null) _details('Final survey', finalSurvey),
      const SizedBox(height: 12),
      const Text(
        'Estimate for reference. Verify inputs and corrections against the vessel’s approved tables and the surveyor’s report.',
      ),
    ];
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    for (final node in _focus) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Draft Survey'),
      actions: [
        IconButton(
          onPressed: _ready && !_saving && _box != null ? _save : null,
          icon: const Icon(Icons.save_outlined),
          tooltip: 'Save survey',
        ),
      ],
    ),
    body: !_ready
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        for (final (index, label) in [
                          'Setup',
                          'Initial',
                          'Final',
                          'Result',
                        ].indexed)
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _step = index;
                                  _station = null;
                                });
                              },
                              style: _step == index
                                  ? TextButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.16),
                                    )
                                  : null,
                              child: Text(label),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: ValueKey(_step),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: switch (_step) {
                          0 => _setup(),
                          1 => _survey(0),
                          2 => _survey(1),
                          _ => _summary(),
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}
