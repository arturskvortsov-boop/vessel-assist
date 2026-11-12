import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nautical_background.dart';
import 'theme.dart';

// Экраны
import '../features/splash_screen.dart';
import '../features/admin/admin_menu_screen.dart';
import '../features/admin/scan_to_pdf_screen.dart';
import '../features/deck/deck_menu_screen.dart';
import '../features/deck/organizer/deck_organizer.dart';
import '../features/deck/gm_roll_screen.dart';
import '../features/deck/eta/eta_screen.dart';
import '../features/deck/port_distance/port_distance_screen.dart';
import '../features/deck/compass_error/compass_error_screen.dart';
import '../features/deck/eta/eco_speed_screen.dart';
import '../features/deck/ports/ports_screen.dart';
import '../features/deck/ukc/ukc_screen.dart';
import '../features/deck/ballast/ballast_time_screen.dart';
import '../features/deck/ballast/ballast_sequence_screen.dart';
import '../features/deck/logbook/logbook_records_screen.dart';
import '../features/deck/tasks/deck_tasks_screen.dart';
import '../features/deck/cargo/cargo_tanks_screen.dart';
import '../features/deck/draft_survey/draft_survey_screen.dart';
import '../features/deck/safety_depth/safety_depth_screen.dart';

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

// Легкая анимация для Web (без тормозов)
CustomTransitionPage<void> _buildPage(Widget child) {
  return CustomTransitionPage<void>(
    key: ValueKey(child.hashCode),
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', pageBuilder: (context, state) => _buildPage(const SplashScreen())),
    GoRoute(path: '/', pageBuilder: (context, state) => _buildPage(const MainMenuScreen())),
    GoRoute(
      path: '/deck',
      pageBuilder: (context, state) => _buildPage(const DeckMenuScreen()),
      routes: [
        GoRoute(path: 'gm_roll', pageBuilder: (context, state) => _buildPage(const GmRollScreen())),
        GoRoute(path: 'organizer', redirect: (context, state) => '/admin/organizer'),
        GoRoute(
          path: 'compress_pdf',
          redirect: (context, state) => '/admin/compress_pdf',
        ),
        GoRoute(path: 'eta', pageBuilder: (context, state) => _buildPage(const EtaScreen())),
        GoRoute(path: 'port_distance', pageBuilder: (context, state) => _buildPage(const PortDistanceScreen())),
        GoRoute(path: 'compass_error', pageBuilder: (context, state) => _buildPage(const CompassErrorScreen())),
        GoRoute(path: 'eco_speed', pageBuilder: (context, state) => _buildPage(const EcoSpeedScreen())),
        GoRoute(path: 'ukc', pageBuilder: (context, state) => _buildPage(const UkcScreen())),
        GoRoute(path: 'ports', pageBuilder: (context, state) => _buildPage(const PortsScreen())),
        GoRoute(path: 'ballast_time', pageBuilder: (context, state) => _buildPage(const BallastTimeScreen())),
        GoRoute(path: 'ballast_sequence', pageBuilder: (context, state) {
            final start = state.extra as DateTime;
            return _buildPage(BallastSequenceScreen(start: start));
        }),
        GoRoute(path: 'logbook', pageBuilder: (context, state) => _buildPage(const LogbookRecordsScreen())),
        GoRoute(path: 'tasks', pageBuilder: (context, state) => _buildPage(const DeckTasksScreen())),
        GoRoute(path: 'cargo_tanks', pageBuilder: (context, state) => _buildPage(const CargoTanksScreen())),
        GoRoute(path: 'draft_survey', pageBuilder: (context, state) => _buildPage(const DraftSurveyScreen())),
        GoRoute(path: 'safety_depth', pageBuilder: (context, state) => _buildPage(const SafetyDepthScreen())),
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
        GoRoute(path: 'organizer', pageBuilder: (context, state) => _buildPage(const DeckOrganizerScreen())),
        GoRoute(path: 'scan_to_pdf', pageBuilder: (context, state) => _buildPage(const ScanToPdfScreen())),
        GoRoute(
          path: 'compress_pdf',
          pageBuilder: (context, state) => _buildPage(const PdfCompressScreen()),
        ),
        GoRoute(path: 'documents', pageBuilder: (context, state) => _buildPage(const DocumentsScreen())),
        GoRoute(path: 'backup', pageBuilder: (context, state) => _buildPage(const BackupScreen())),
      ],
    ),
  ],
);

// --- ГЛАВНЫЙ ЭКРАН (Дашборд) ---
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
                  fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 4,
                  foreground: Paint()..shader = const LinearGradient(colors: [gold, accent]).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                ),
              ),
              const SizedBox(height: 8),
              const Text('AHOY, SEAFARER!', textAlign: TextAlign.center, style: TextStyle(color: gold, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),

              _DashCard(
                title: 'UP TO THE BRIDGE',
                subtitle: 'Подняться на мост\nNavigation & Cargo Operations',
                icon: Icons.explore_outlined,
                gradientColors: [accentDark, accent],
                onTap: () => context.push('/deck'), // Теперь push
              ),
              const SizedBox(height: 20),

              _DashCard(
                title: 'DOWN TO THE ENGINE',
                subtitle: 'Спуститься в МО\nMARPOL, Fuel & Tanks',
                icon: Icons.settings_outlined,
                gradientColors: [gold, Colors.orangeAccent],
                onTap: () => context.push('/engine'), // Теперь push
              ),
              const SizedBox(height: 20),

              _DashCard(
                title: 'ADMIN & DOCUMENTS',
                subtitle: 'Документы и резервные копии',
                icon: Icons.security,
                gradientColors: [Colors.blueGrey, Colors.grey], 
                onTap: () => context.push('/admin'), // Теперь push
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _DashCard({required this.title, required this.subtitle, required this.icon, required this.gradientColors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: gradientColors.first.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}