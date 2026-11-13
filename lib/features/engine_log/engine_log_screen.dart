import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/section_theme.dart';
import 'package:animations/animations.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/staggered_item.dart';

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
    final palette = SectionPalette.of(AppSection.engine);
    return AppScaffold(
      title: 'Engine Operations',
      background: AppBackground.engineRoom,
      section: AppSection.engine,
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
              color: palette.accent.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: cardSolid,
          indicatorColor: palette.accent.withValues(alpha: 0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.anchor, color: textMuted),
              selectedIcon: Icon(Icons.anchor, color: palette.accent),
              label: 'MARPOL',
            ),
            NavigationDestination(
              icon: const Icon(Icons.engineering, color: textMuted),
              selectedIcon: Icon(Icons.engineering, color: palette.accent),
              label: 'Daily Ops',
            ),
            NavigationDestination(
              icon: const Icon(Icons.security, color: textMuted),
              selectedIcon: Icon(Icons.security, color: palette.accent),
              label: 'Admin',
            ),
          ],
        ),
      ),
    );
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
        StaggeredItem(index: 0, child: _MenuCard(title: 'Tank Status', subtitle: 'Volumes, ROB & Free space', icon: Icons.storage, route: '/engine/tanks')),
        StaggeredItem(index: 1, child: _MenuCard(title: 'ORB Generator', subtitle: 'MARPOL Record Book entries', icon: Icons.menu_book, route: '/engine/orb')),
        StaggeredItem(index: 2, child: _MenuCard(title: 'Fuel Changeover', subtitle: 'Fuel switch logbook records', icon: Icons.swap_horiz, route: '/engine/changeover')),
        StaggeredItem(index: 3, child: _MenuCard(title: 'EGCS Record Book', subtitle: 'Scrubber operations & failures', icon: Icons.air, route: '/engine/egcs')),
        StaggeredItem(index: 4, child: _MenuCard(title: 'Bunkering Checklists', subtitle: 'Before, During & After loading', icon: Icons.checklist, route: '/engine/bunker_checklist')),
        StaggeredItem(index: 5, child: _MenuCard(title: 'Letters of Protest', subtitle: 'Bunkering disputes & claims', icon: Icons.gavel, route: '/engine/lop')),
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
        StaggeredItem(index: 0, child: _MenuCard(title: 'Fuel Daily Log', subtitle: 'Consumption & ROB (3 schemes)', icon: Icons.calculate, route: '/engine/fuel_log')),
        StaggeredItem(index: 1, child: _MenuCard(title: 'Lube Oil', subtitle: 'Feed rate, Top-up & ROB Tracker', icon: Icons.water_drop, route: '/engine/lube')),
        StaggeredItem(index: 2, child: _MenuCard(title: 'Pump Calculator', subtitle: 'Transfer time & overflow check', icon: Icons.water, route: '/engine/pump')),
        StaggeredItem(index: 3, child: _MenuCard(title: 'Voyage Plan', subtitle: 'Fuel requirement & arrival ROB', icon: Icons.map, route: '/engine/voyage')),
        StaggeredItem(index: 4, child: _MenuCard(title: 'Engine Hours', subtitle: 'Machinery running hours', icon: Icons.timer, route: '/engine/hours')),
        StaggeredItem(index: 5, child: _MenuCard(title: 'Night Orders', subtitle: 'Watch instructions', icon: Icons.nights_stay, route: '/engine/night_orders')),
        StaggeredItem(index: 6, child: _MenuCard(title: 'Crew Tasks', subtitle: 'To-do list and assignments', icon: Icons.assignment, route: '/engine/tasks')),
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
        StaggeredItem(index: 0, child: _MenuCard(title: 'Emergency', subtitle: 'Contacts & Procedures', icon: Icons.warning_amber_rounded, route: '/engine/emergency')),
        StaggeredItem(index: 1, child: _MenuCard(title: 'Spares & Stores', subtitle: 'Inventory & Requisitions', icon: Icons.inventory_2, route: '/engine/spares')),
        StaggeredItem(index: 2, child: _MenuCard(title: 'Warranty Claims', subtitle: 'Defect tracker & expiry alerts', icon: Icons.shield, route: '/engine/warranty')),
        StaggeredItem(index: 3, child: _MenuCard(title: 'Delivery & Acceptance', subtitle: 'Checklists & Punch List', icon: Icons.assignment_turned_in, route: '/engine/delivery')),
        StaggeredItem(index: 4, child: _MenuCard(title: 'Notes', subtitle: 'Quick reminders & inspector notes', icon: Icons.sticky_note_2, route: '/engine/notes')),
        StaggeredItem(index: 5, child: _MenuCard(title: 'Document Storage', subtitle: 'Scanned manuals & certificates', icon: Icons.folder_copy, route: '/engine/documents')),
        StaggeredItem(index: 6, child: _MenuCard(title: 'Backup & Restore', subtitle: 'Save or load all app data', icon: Icons.cloud_sync, route: '/engine/backup')),
      ],
    );
  }
}

// --- ВИДЖЕТ КАРТОЧКИ ---
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
    final palette = SectionTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.accent.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: palette.accent, size: 24),
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