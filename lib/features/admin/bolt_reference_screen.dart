import 'package:flutter/material.dart';

import '../../core/palette_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';

/// Данные по метрическим болтам/резьбам (ISO / JIS). Размеры в мм.
class BoltSpec {
  final String size; // M3, M4, ...
  final double d; // номинальный диаметр
  final double pitchCoarse; // шаг крупной резьбы
  final double pitchFine; // шаг мелкой резьбы
  final double spanner; // размер ключа (под ключ)
  final double hex; // размер шестигранника (hex key)
  final double tapDrill; // сверло под резьбу

  const BoltSpec({
    required this.size,
    required this.d,
    required this.pitchCoarse,
    required this.pitchFine,
    required this.spanner,
    required this.hex,
    required this.tapDrill,
  });
}

/// Справочник метрических болтов от M3 до M64.
const List<BoltSpec> boltSpecs = [
  BoltSpec(size: 'M3', d: 3, pitchCoarse: 0.5, pitchFine: 0.35, spanner: 5.5, hex: 2.5, tapDrill: 2.5),
  BoltSpec(size: 'M4', d: 4, pitchCoarse: 0.7, pitchFine: 0.5, spanner: 7, hex: 3, tapDrill: 3.3),
  BoltSpec(size: 'M5', d: 5, pitchCoarse: 0.8, pitchFine: 0.5, spanner: 8, hex: 4, tapDrill: 4.2),
  BoltSpec(size: 'M6', d: 6, pitchCoarse: 1.0, pitchFine: 0.75, spanner: 10, hex: 5, tapDrill: 5.0),
  BoltSpec(size: 'M8', d: 8, pitchCoarse: 1.25, pitchFine: 1.0, spanner: 13, hex: 6, tapDrill: 6.8),
  BoltSpec(size: 'M10', d: 10, pitchCoarse: 1.5, pitchFine: 1.25, spanner: 17, hex: 8, tapDrill: 8.5),
  BoltSpec(size: 'M12', d: 12, pitchCoarse: 1.75, pitchFine: 1.25, spanner: 19, hex: 10, tapDrill: 10.2),
  BoltSpec(size: 'M14', d: 14, pitchCoarse: 2.0, pitchFine: 1.5, spanner: 22, hex: 11, tapDrill: 12.0),
  BoltSpec(size: 'M16', d: 16, pitchCoarse: 2.0, pitchFine: 1.5, spanner: 24, hex: 14, tapDrill: 14.0),
  BoltSpec(size: 'M18', d: 18, pitchCoarse: 2.5, pitchFine: 1.5, spanner: 27, hex: 14, tapDrill: 15.5),
  BoltSpec(size: 'M20', d: 20, pitchCoarse: 2.5, pitchFine: 1.5, spanner: 30, hex: 17, tapDrill: 17.5),
  BoltSpec(size: 'M22', d: 22, pitchCoarse: 2.5, pitchFine: 1.5, spanner: 32, hex: 17, tapDrill: 19.5),
  BoltSpec(size: 'M24', d: 24, pitchCoarse: 3.0, pitchFine: 2.0, spanner: 36, hex: 19, tapDrill: 21.0),
  BoltSpec(size: 'M27', d: 27, pitchCoarse: 3.0, pitchFine: 2.0, spanner: 41, hex: 20, tapDrill: 24.0),
  BoltSpec(size: 'M30', d: 30, pitchCoarse: 3.5, pitchFine: 2.0, spanner: 46, hex: 22, tapDrill: 26.5),
  BoltSpec(size: 'M33', d: 33, pitchCoarse: 3.5, pitchFine: 2.0, spanner: 50, hex: 24, tapDrill: 29.5),
  BoltSpec(size: 'M36', d: 36, pitchCoarse: 4.0, pitchFine: 3.0, spanner: 55, hex: 27, tapDrill: 32.0),
  BoltSpec(size: 'M42', d: 42, pitchCoarse: 4.5, pitchFine: 3.0, spanner: 65, hex: 32, tapDrill: 37.5),
  BoltSpec(size: 'M48', d: 48, pitchCoarse: 5.0, pitchFine: 3.0, spanner: 75, hex: 38, tapDrill: 43.0),
  BoltSpec(size: 'M56', d: 56, pitchCoarse: 5.5, pitchFine: 4.0, spanner: 85, hex: 46, tapDrill: 50.5),
  BoltSpec(size: 'M64', d: 64, pitchCoarse: 6.0, pitchFine: 4.0, spanner: 95, hex: 55, tapDrill: 58.0),
];

class BoltReferenceScreen extends StatefulWidget {
  const BoltReferenceScreen({super.key});

  @override
  State<BoltReferenceScreen> createState() => _BoltReferenceScreenState();
}

class _BoltReferenceScreenState extends State<BoltReferenceScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    PaletteState.set(AppSection.admin);
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? boltSpecs
        : boltSpecs
            .where((b) =>
                b.size.toLowerCase().contains(q) ||
                b.d.toString().contains(q))
            .toList();

    return AppScaffold(
      title: 'Bolts & Threads',
      section: AppSection.admin,
      background: AppBackground.neutral,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search (M-size, diameter)',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _BoltCard(spec: filtered[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoltCard extends StatelessWidget {
  final BoltSpec spec;
  const _BoltCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                spec.size,
                style: TextStyle(
                  color: accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Ø${spec.d} mm',
                style: const TextStyle(color: textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('Pitch coarse', '${spec.pitchCoarse} mm'),
          _row('Pitch fine', '${spec.pitchFine} mm'),
          _row('Spanner (A/F)', '${spec.spanner} mm'),
          _row('Hex key', '${spec.hex} mm'),
          _row('Tap drill', '${spec.tapDrill} mm'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: textMuted, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              color: text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
