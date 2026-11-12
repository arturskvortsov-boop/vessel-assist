import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import '../../core/theme.dart';

class DeckMenuScreen extends StatefulWidget {
  const DeckMenuScreen({super.key});

  @override
  State<DeckMenuScreen> createState() => _DeckMenuScreenState();
}

class _DeckMenuScreenState extends State<DeckMenuScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _NavigationTab(),
    const _CargoTab(),
    const _DeckOpsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Bridge & Deck'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 400),
        reverse: false,
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: const Border(top: BorderSide(color: border)),
          color: cardSolid,
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: cardSolid,
          indicatorColor: accent.withValues(alpha: 0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.explore, color: textMuted), selectedIcon: Icon(Icons.explore, color: accent), label: 'Nav'),
            NavigationDestination(
              icon: _CargoCraneIcon(color: textMuted),
              selectedIcon: _CargoCraneIcon(color: accent),
              label: 'Cargo',
            ),
            NavigationDestination(icon: Icon(Icons.book, color: textMuted), selectedIcon: Icon(Icons.book, color: accent), label: 'Deck Ops'),
          ],
        ),
      ),
    );
  }
}

// --- ВКЛАДКА 1: NAVIGATION ---
class _NavigationTab extends StatelessWidget {
  const _NavigationTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MenuCard(title: 'ETA Calculator', subtitle: 'Arrival time & required speed', icon: Icons.schedule, route: '/deck/eta'),
        _MenuCard(title: 'Port Distance', subtitle: 'Sea distance & time at sea', icon: Icons.route, route: '/deck/port_distance'),
        _MenuCard(title: 'Compass Error Calculator', subtitle: 'Gyro and magnetic compass checks', icon: Icons.explore_outlined, route: '/deck/compass_error'),
        _MenuCard(title: 'UKC Calculator', subtitle: 'Under-keel clearance', icon: Icons.waves, route: '/deck/ukc'),
        _MenuCard(title: 'Safety Depth', subtitle: 'Vessel settings & calculation', icon: Icons.straighten, route: '/deck/safety_depth'),
      ],
    );
  }
}

// --- ВКЛАДКА 2: CARGO ---
class _CargoTab extends StatelessWidget {
  const _CargoTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MenuCard(title: 'Cargo Tanks', subtitle: 'Volumes, density & Excel export', icon: Icons.storage, route: '/deck/cargo_tanks'),
        _MenuCard(title: 'Draft Survey', subtitle: 'Cargo weight from draft readings', icon: Icons.calculate_outlined, route: '/deck/draft_survey'),
        _MenuCard(title: 'Ballast Time', subtitle: 'Pumping duration', icon: Icons.water, route: '/deck/ballast_time'),
        _MenuCard(title: 'GM Estimate', subtitle: 'Stability from roll period', icon: Icons.straighten, route: '/deck/gm_roll'),
      ],
    );
  }
}

// --- ВКЛАДКА 3: DECK OPS ---
class _DeckOpsTab extends StatelessWidget {
  const _DeckOpsTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MenuCard(title: 'Logbook Records', subtitle: 'Inspection wording & schedule', icon: Icons.menu_book, route: '/deck/logbook'),
        _MenuCard(title: 'Crew Tasks', subtitle: 'Assignments, deadlines & status', icon: Icons.task_alt, route: '/deck/tasks'),
        _MenuCard(title: 'Port Codes', subtitle: 'Search ports by UN/LOCODE', icon: Icons.travel_explore, route: '/deck/ports'),
      ],
    );
  }
}

// --- ВИДЖЕТ КАРТОЧКИ (Строгий и четкий) ---
class _MenuCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final String route;
  const _MenuCard({required this.title, required this.subtitle, required this.icon, required this.route});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardSolid,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
        child: InkWell(
          onTap: () => context.push(route),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: accent.withValues(alpha: 0.2))
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CargoCraneIcon extends StatelessWidget {
  const _CargoCraneIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.square(24),
    painter: _CargoCranePainter(color),
  );
}

class _CargoCranePainter extends CustomPainter {
  const _CargoCranePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final crane = Path()
      ..moveTo(2, 21)
      ..lineTo(8, 21)
      ..moveTo(5, 21)
      ..lineTo(5, 4)
      ..lineTo(21, 4)
      ..moveTo(5, 10)
      ..lineTo(11, 4)
      ..moveTo(16, 4)
      ..lineTo(16, 10)
      ..lineTo(12, 13)
      ..moveTo(16, 10)
      ..lineTo(20, 13);
    canvas.drawPath(crane, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 13, 12, 7),
        const Radius.circular(1),
      ),
      paint,
    );
    canvas.drawLine(const Offset(14, 15), const Offset(14, 18), paint);
    canvas.drawLine(const Offset(18, 15), const Offset(18, 18), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CargoCranePainter oldDelegate) =>
      oldDelegate.color != color;
}
