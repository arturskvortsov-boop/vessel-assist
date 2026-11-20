import 'package:flutter/material.dart';

import '../../core/palette_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';

/// Данные по трубам (JIS / ASME). Размеры в мм.
class PipeSpec {
  final String size; // 15A, 20A, ...
  final String inch; // 1/2, 3/4, ...
  final int dn; // номинальный диаметр
  final double jisOD; // наружный диаметр JIS
  final double sgpWall; // толщина стенки SGP (JIS)
  final double asmeOD; // наружный диаметр ASME

  const PipeSpec({
    required this.size,
    required this.inch,
    required this.dn,
    required this.jisOD,
    required this.sgpWall,
    required this.asmeOD,
  });
}

/// Справочник труб от 15A до 500A.
const List<PipeSpec> pipeSpecs = [
  PipeSpec(size: '15A', inch: '1/2', dn: 15, jisOD: 21.7, sgpWall: 2.8, asmeOD: 21.34),
  PipeSpec(size: '20A', inch: '3/4', dn: 20, jisOD: 27.2, sgpWall: 2.8, asmeOD: 26.67),
  PipeSpec(size: '25A', inch: '1', dn: 25, jisOD: 34.0, sgpWall: 3.2, asmeOD: 33.40),
  PipeSpec(size: '32A', inch: '1 1/4', dn: 32, jisOD: 42.7, sgpWall: 3.5, asmeOD: 42.16),
  PipeSpec(size: '40A', inch: '1 1/2', dn: 40, jisOD: 48.6, sgpWall: 3.5, asmeOD: 48.26),
  PipeSpec(size: '50A', inch: '2', dn: 50, jisOD: 60.5, sgpWall: 3.8, asmeOD: 60.33),
  PipeSpec(size: '65A', inch: '2 1/2', dn: 65, jisOD: 76.3, sgpWall: 4.2, asmeOD: 73.03),
  PipeSpec(size: '80A', inch: '3', dn: 80, jisOD: 89.1, sgpWall: 4.2, asmeOD: 88.90),
  PipeSpec(size: '100A', inch: '4', dn: 100, jisOD: 114.3, sgpWall: 4.5, asmeOD: 114.30),
  PipeSpec(size: '125A', inch: '5', dn: 125, jisOD: 139.8, sgpWall: 4.5, asmeOD: 141.30),
  PipeSpec(size: '150A', inch: '6', dn: 150, jisOD: 165.2, sgpWall: 5.0, asmeOD: 168.28),
  PipeSpec(size: '200A', inch: '8', dn: 200, jisOD: 216.3, sgpWall: 5.8, asmeOD: 219.08),
  PipeSpec(size: '250A', inch: '10', dn: 250, jisOD: 267.4, sgpWall: 6.6, asmeOD: 273.05),
  PipeSpec(size: '300A', inch: '12', dn: 300, jisOD: 318.5, sgpWall: 6.9, asmeOD: 323.85),
  PipeSpec(size: '350A', inch: '14', dn: 350, jisOD: 355.6, sgpWall: 7.9, asmeOD: 355.60),
  PipeSpec(size: '400A', inch: '16', dn: 400, jisOD: 406.4, sgpWall: 7.9, asmeOD: 406.40),
  PipeSpec(size: '450A', inch: '18', dn: 450, jisOD: 457.2, sgpWall: 7.9, asmeOD: 457.20),
  PipeSpec(size: '500A', inch: '20', dn: 500, jisOD: 508.0, sgpWall: 9.5, asmeOD: 508.00),
];

class PipeReferenceScreen extends StatefulWidget {
  const PipeReferenceScreen({super.key});

  @override
  State<PipeReferenceScreen> createState() => _PipeReferenceScreenState();
}

class _PipeReferenceScreenState extends State<PipeReferenceScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    PaletteState.set(AppSection.admin);
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? pipeSpecs
        : pipeSpecs
            .where((p) =>
                p.size.toLowerCase().contains(q) ||
                p.inch.contains(q) ||
                p.dn.toString().contains(q))
            .toList();

    return AppScaffold(
      title: 'Pipe Sizes',
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
                    labelText: 'Search (size, inch, DN)',
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
                      _PipeCard(spec: filtered[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PipeCard extends StatelessWidget {
  final PipeSpec spec;
  const _PipeCard({required this.spec});

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
                '${spec.inch}"  ·  DN ${spec.dn}',
                style: const TextStyle(color: textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('JIS OD', '${spec.jisOD} mm'),
          _row('SGP wall', '${spec.sgpWall} mm'),
          _row('ASME OD', '${spec.asmeOD} mm'),
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
