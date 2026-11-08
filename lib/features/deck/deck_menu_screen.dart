import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/staggered_item.dart';

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
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: cardSolid,
          indicatorColor: accent.withValues(alpha: 0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.explore, color: textMuted), selectedIcon: Icon(Icons.explore, color: accent), label: 'Nav'),
            NavigationDestination(icon: Icon(Icons.local_shipping, color: textMuted), selectedIcon: Icon(Icons.local_shipping, color: accent), label: 'Cargo'),
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
        StaggeredItem(index: 0, child: _MenuCard(title: 'ETA Calculator', subtitle: 'Arrival time & required speed', icon: Icons.schedule, route: '/deck/eta')),
        StaggeredItem(index: 1, child: _MenuCard(title: 'UKC Calculator', subtitle: 'Under-keel clearance', icon: Icons.waves, route: '/deck/gm_roll')), // Заглушка
        StaggeredItem(index: 2, child: _MenuCard(title: 'Safety Depth', subtitle: 'Vessel settings & calculation', icon: Icons.straighten, route: '/deck/gm_roll')), // Заглушка
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
        StaggeredItem(index: 0, child: _MenuCard(title: 'Cargo Tanks', subtitle: 'Volumes & calculations', icon: Icons.storage, route: '/engine/tanks')), // Временно ведет в Engine Tanks
        StaggeredItem(index: 1, child: _MenuCard(title: 'Ballast Time', subtitle: 'Pumping duration', icon: Icons.water, route: '/deck/gm_roll')), // Заглушка
        StaggeredItem(index: 2, child: _MenuCard(title: 'GM Estimate', subtitle: 'Stability from roll period', icon: Icons.straighten, route: '/deck/gm_roll')),
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
        StaggeredItem(index: 0, child: _MenuCard(title: 'Deck Organizer', subtitle: 'Notes, documents & expiry', icon: Icons.event_note, route: '/deck/gm_roll')), // Заглушка
        StaggeredItem(index: 1, child: _MenuCard(title: 'Logbook Records', subtitle: 'Inspection wording & schedule', icon: Icons.menu_book, route: '/deck/gm_roll')), // Заглушка
        StaggeredItem(index: 2, child: _MenuCard(title: 'Port Codes', subtitle: 'Search ports by UN/LOCODE', icon: Icons.travel_explore, route: '/deck/gm_roll')), // Заглушка
      ],
    );
  }
}

// --- ВИДЖЕТ КАРТОЧКИ ---
class _MenuCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final String route;
  const _MenuCard({required this.title, required this.subtitle, required this.icon, required this.route});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: accent.withValues(alpha: 0.2))),
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
    );
  }
}