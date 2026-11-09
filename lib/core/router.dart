import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'nautical_background.dart';
import 'widgets/glass_card.dart';
import 'theme.dart';

// Экраны
import '../features/splash_screen.dart';
import '../features/admin/admin_menu_screen.dart'; // Вернули Admin
import '../features/deck/deck_menu_screen.dart';
import '../features/deck/gm_roll_screen.dart';
import '../features/deck/eta/eta_screen.dart';
import '../features/deck/eta/eco_speed_screen.dart';
import '../features/deck/ports/ports_screen.dart';
import '../features/deck/ukc/ukc_screen.dart';
import '../features/deck/safety_depth/safety_depth_screen.dart';
import '../features/deck/ballast/ballast_time_screen.dart';
import '../features/deck/ballast/ballast_sequence_screen.dart';
import '../features/deck/logbook/logbook_records_screen.dart';
import '../features/deck/cargo/cargo_tanks_screen.dart';

import '../features/engine_log/engine_log_screen.dart';
import '../features/engine_log/tanks/tanks_screen.dart';
import '../features/engine_log/fuel_log/fuel_log_screen.dart';
import '../features/engine_log/orb/orb_screen.dart';
import '../features/engine_log/bunkering/bunker_checklist_screen.dart';
import '../features/engine_log/bunkering/lop_screen.dart';
import '../features/engine_log/tasks/tasks_screen.dart';
import '../features/engine_log/lube/lube_screen.dart';
import '../features/engine_log/night_orders/night_orders_screen.dart';
import '../features/engine_log/hours/hours_screen.dart';
import '../features/engine_log/changeover/changeover_screen.dart';
import '../features/engine_log/egcs/egcs_screen.dart';
import '../features/engine_log/emergency/emergency_screen.dart';
import '../features/engine_log/spares/spares_screen.dart';
import '../features/engine_log/warranty/warranty_screen.dart';
import '../features/engine_log/delivery/delivery_screen.dart';
import '../features/engine_log/notes/notes_screen.dart';
import '../features/engine_log/backup/backup_screen.dart';
import '../features/engine_log/pump/pump_screen.dart';
import '../features/engine_log/voyage/voyage_screen.dart';
import '../features/engine_log/documents/documents_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// Премиум-анимация перехода
CustomTransitionPage<void> _buildPage(Widget child) {
  return CustomTransitionPage<void>(
    key: ValueKey(child.hashCode),
    child: child,
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.scaled,
        child: child,
      );
    },
  );
}

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _buildPage(const SplashScreen()),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _buildPage(const MainMenuScreen()),
    ),
    GoRoute(
      path: '/deck',
      pageBuilder: (context, state) => _buildPage(const DeckMenuScreen()),
      routes: [
        GoRoute(path: 'gm_roll', pageBuilder: (context, state) => _buildPage(const GmRollScreen())),
        GoRoute(path: 'safety_depth', pageBuilder: (context, state) => _buildPage(const SafetyDepthScreen())),
        GoRoute(path: 'eta', pageBuilder: (context, state) => _buildPage(const EtaScreen())),
        GoRoute(path: 'eco_speed', pageBuilder: (context, state) => _buildPage(const EcoSpeedScreen())),
        GoRoute(path: 'ukc', pageBuilder: (context, state) => _buildPage(const UkcScreen())),
        GoRoute(path: 'safety_depth', pageBuilder: (context, state) => _buildPage(const SafetyDepthScreen())),
        GoRoute(path: 'ports', pageBuilder: (context, state) => _buildPage(const PortsScreen())),
        GoRoute(path: 'ballast_time', pageBuilder: (context, state) => _buildPage(const BallastTimeScreen())),
        GoRoute(
          path: 'ballast_sequence',
          pageBuilder: (context, state) {
            final start = state.extra as DateTime;
            return _buildPage(BallastSequenceScreen(start: start));
          },
        ),
        GoRoute(path: 'logbook', pageBuilder: (context, state) => _buildPage(const LogbookRecordsScreen())),
        GoRoute(path: 'cargo_tanks', pageBuilder: (context, state) => _buildPage(const CargoTanksScreen())),
      ],
    ),
    GoRoute(
      path: '/engine',
      pageBuilder: (context, state) => _buildPage(const EngineLogScreen()),
      routes: [
        GoRoute(path: 'tanks', pageBuilder: (context, state) => _buildPage(const TanksScreen())),
        GoRoute(path: 'fuel_log', pageBuilder: (context, state) => _buildPage(const FuelLogScreen())),
        GoRoute(path: 'orb', pageBuilder: (context, state) => _buildPage(const OrbScreen())),
        GoRoute(path: 'bunker_checklist', pageBuilder: (context, state) => _buildPage(const BunkerChecklistScreen())),
        GoRoute(path: 'lop', pageBuilder: (context, state) => _buildPage(const LopScreen())),
        GoRoute(path: 'tasks', pageBuilder: (context, state) => _buildPage(const TasksScreen())),
        GoRoute(path: 'lube', pageBuilder: (context, state) => _buildPage(const LubeScreen())),
        GoRoute(path: 'night_orders', pageBuilder: (context, state) => _buildPage(const NightOrdersScreen())),
        GoRoute(path: 'hours', pageBuilder: (context, state) => _buildPage(const HoursScreen())),
        GoRoute(path: 'changeover', pageBuilder: (context, state) => _buildPage(const ChangeoverScreen())),
        GoRoute(path: 'egcs', pageBuilder: (context, state) => _buildPage(const EgcsScreen())),
        GoRoute(path: 'emergency', pageBuilder: (context, state) => _buildPage(const EmergencyScreen())),
        GoRoute(path: 'spares', pageBuilder: (context, state) => _buildPage(const SparesScreen())),
        GoRoute(path: 'warranty', pageBuilder: (context, state) => _buildPage(const WarrantyScreen())),
        GoRoute(path: 'delivery', pageBuilder: (context, state) => _buildPage(const DeliveryScreen())),
        GoRoute(path: 'notes', pageBuilder: (context, state) => _buildPage(const NotesScreen())),
        GoRoute(path: 'backup', pageBuilder: (context, state) => _buildPage(const BackupScreen())),
        GoRoute(path: 'pump', pageBuilder: (context, state) => _buildPage(const PumpScreen())),
        GoRoute(path: 'voyage', pageBuilder: (context, state) => _buildPage(const VoyageScreen())),
        GoRoute(path: 'documents', pageBuilder: (context, state) => _buildPage(const DocumentsScreen())),
      ],
    ),
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) => _buildPage(const AdminMenuScreen()),
      routes: [
        GoRoute(path: 'documents', pageBuilder: (context, state) => _buildPage(const DocumentsScreen())),
        GoRoute(path: 'backup', pageBuilder: (context, state) => _buildPage(const BackupScreen())),
      ],
    ),
  ],
);

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NauticalBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              Text(
                'VESSEL ASSIST',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [gold, accent],
                    ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'AHOY, SEAFARER! SEVEN FEET UNDER THE KEEL!',
                textAlign: TextAlign.center,
                style: TextStyle(color: gold, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ахой, моряк! Семь футов под килем!',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 11, letterSpacing: 1),
              ),
              const SizedBox(height: 40),

              _DashCard(
                title: 'UP TO THE BRIDGE',
                subtitle: 'Подняться на мост (Navigation & Cargo)',
                icon: Icons.explore_outlined,
                onTap: () => context.go('/deck'),
              ),
              
              const SizedBox(height: 24),

              _DashCard(
                title: 'DOWN TO THE ENGINE',
                subtitle: 'Спуститься в МО (MARPOL, Fuel & Tanks)',
                icon: Icons.settings_outlined,
                onTap: () => context.go('/engine'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DashCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                border: Border.all(color: accent.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: textMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: accent),
          ],
        ),
      ),
    );
  }
}