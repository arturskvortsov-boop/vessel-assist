import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import 'package:animations/animations.dart';

class EngineLogScreen extends StatefulWidget {
  const EngineLogScreen({super.key});

  @override
  State<EngineLogScreen> createState() => _EngineLogScreenState();
}

class _EngineLogScreenState extends State<EngineLogScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _MarpolTab(),
    const _DailyOpsTab(),
    const _AdminSafetyTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Engine Operations'),
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
            BoxShadow(
              color: accent.withValues(alpha: 0.1), // Неоновое свечение снизу
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: cardSolid,
          indicatorColor: accent.withValues(alpha: 0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.anchor, color: textMuted),
              selectedIcon: Icon(Icons.anchor, color: accent),
              label: 'MARPOL',
            ),
            NavigationDestination(
              icon: Icon(Icons.engineering, color: textMuted),
              selectedIcon: Icon(Icons.engineering, color: accent),
              label: 'Daily Ops',
            ),
            NavigationDestination(
              icon: Icon(Icons.security, color: textMuted),
              selectedIcon: Icon(Icons.security, color: accent),
              label: 'Admin',
            ),
          ],
        ), // <--- Закрываем NavigationBar
      ), // <--- Закрываем Container
    ); // <--- Закрываем Scaffold
  }
}

// --- ВКЛАДКА 1: MARPOL & LOGS ---
class _MarpolTab extends StatelessWidget {
  const _MarpolTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MenuCard(title: 'Tank Status', subtitle: 'Volumes, ROB & Free space', icon: Icons.storage, route: '/engine/tanks'),
        _MenuCard(title: 'ORB Generator', subtitle: 'MARPOL Record Book entries', icon: Icons.menu_book, route: '/engine/orb'),
        _MenuCard(title: 'Fuel Changeover', subtitle: 'Fuel switch logbook records', icon: Icons.swap_horiz, route: '/engine/changeover'),
        _MenuCard(title: 'EGCS Record Book', subtitle: 'Scrubber operations & failures', icon: Icons.air, route: '/engine/egcs'),
        _MenuCard(title: 'Bunkering Checklists', subtitle: 'Before, During & After loading', icon: Icons.checklist, route: '/engine/bunker_checklist'),
        _MenuCard(title: 'Letters of Protest', subtitle: 'Bunkering disputes & claims', icon: Icons.gavel, route: '/engine/lop'),
      ],
    );
  }
}

// --- ВКЛАДКА 2: DAILY OPERATIONS ---
class _DailyOpsTab extends StatelessWidget {
  const _DailyOpsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MenuCard(title: 'Fuel Daily Log', subtitle: 'Consumption & ROB (3 schemes)', icon: Icons.calculate, route: '/engine/fuel_log'),
        _MenuCard(title: 'Lube Oil', subtitle: 'Feed rate, Top-up & ROB Tracker', icon: Icons.water_drop, route: '/engine/lube'),
        _MenuCard(title: 'Pump Calculator', subtitle: 'Transfer time & overflow check', icon: Icons.water, route: '/engine/pump'),
        _MenuCard(title: 'Voyage Plan', subtitle: 'Fuel requirement & arrival ROB', icon: Icons.map, route: '/engine/voyage'),
        _MenuCard(title: 'Engine Hours', subtitle: 'Machinery running hours', icon: Icons.timer, route: '/engine/hours'),
        _MenuCard(title: 'Night Orders', subtitle: 'Watch instructions', icon: Icons.nights_stay, route: '/engine/night_orders'),
        _MenuCard(title: 'Crew Tasks', subtitle: 'To-do list and assignments', icon: Icons.assignment, route: '/engine/tasks'),
      ],
    );
  }
}

// --- ВКЛАДКА 3: ADMIN & SAFETY ---
class _AdminSafetyTab extends StatelessWidget {
  const _AdminSafetyTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MenuCard(title: 'Emergency', subtitle: 'Contacts & Procedures', icon: Icons.warning_amber_rounded, route: '/engine/emergency'),
        _MenuCard(title: 'Spares & Stores', subtitle: 'Inventory & Requisitions', icon: Icons.inventory_2, route: '/engine/spares'),
        _MenuCard(title: 'Warranty Claims', subtitle: 'Defect tracker & expiry alerts', icon: Icons.shield, route: '/engine/warranty'),
        _MenuCard(title: 'Delivery & Acceptance', subtitle: 'Checklists & Punch List', icon: Icons.assignment_turned_in, route: '/engine/delivery'),
        _MenuCard(title: 'Notes', subtitle: 'Quick reminders & inspector notes', icon: Icons.sticky_note_2, route: '/engine/notes'),
        _MenuCard(title: 'Document Storage', subtitle: 'Scanned manuals & certificates', icon: Icons.folder_copy, route: '/engine/documents'),
        _MenuCard(title: 'Backup & Restore', subtitle: 'Save or load all app data', icon: Icons.cloud_sync, route: '/engine/backup'),
      ],
    );
  }
}

// --- ВИДЖЕТ КАРТОЧКИ (вынесен отдельно для чистоты) ---
class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardSolid,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
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
    );
  }
}