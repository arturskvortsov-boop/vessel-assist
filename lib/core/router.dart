import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nautical_background.dart';
import 'theme.dart';
import '../features/splash_screen.dart';
import '../features/deck/deck_menu_screen.dart';
import '../features/deck/gm_roll_screen.dart';
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

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const MainMenuScreen(),
    ),
    GoRoute(
      path: '/deck',
      builder: (context, state) => const DeckMenuScreen(),
      routes: [
        GoRoute(
          path: 'gm_roll',
          builder: (context, state) => const GmRollScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/engine',
      builder: (context, state) => const EngineLogScreen(),
      routes: [
        GoRoute(
          path: 'tanks',
          builder: (context, state) => const TanksScreen(),
        ),
        GoRoute(
          path: 'fuel_log',
          builder: (context, state) => const FuelLogScreen(),
        ),
        GoRoute(
          path: 'orb',
          builder: (context, state) => const OrbScreen(),
        ),
        GoRoute(
          path: 'bunker_checklist',
          builder: (context, state) => const BunkerChecklistScreen(),
        ),
        GoRoute(
          path: 'lop',
          builder: (context, state) => const LopScreen(),
        ),
        GoRoute(
          path: 'tasks',
          builder: (context, state) => const TasksScreen(),
        ),
        GoRoute(
          path: 'lube',
          builder: (context, state) => const LubeScreen(),
        ),
        GoRoute(
          path: 'night_orders',
          builder: (context, state) => const NightOrdersScreen(),
        ),
        GoRoute(
          path: 'hours',
          builder: (context, state) => const HoursScreen(),
        ),
        GoRoute(
          path: 'changeover',
          builder: (context, state) => const ChangeoverScreen(),
        ),
        GoRoute(
          path: 'egcs',
          builder: (context, state) => const EgcsScreen(),
        ),
        GoRoute(
          path: 'emergency',
          builder: (context, state) => const EmergencyScreen(),
        ),
        GoRoute(
          path: 'spares',
          builder: (context, state) => const SparesScreen(),
        ),
        GoRoute(
          path: 'warranty',
          builder: (context, state) => const WarrantyScreen(),
        ),
        GoRoute(
          path: 'delivery',
          builder: (context, state) => const DeliveryScreen(),
        ),
        GoRoute(
          path: 'notes',
          builder: (context, state) => const NotesScreen(),
        ),
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

              // --- ПОДНЯТЬСЯ НА МОСТ ---
              _DashCard(
                title: 'UP TO THE BRIDGE',
                subtitle: 'Подняться на мост (Navigation & Cargo)',
                icon: Icons.explore_outlined,
                onTap: () => context.push('/deck'),
              ),
              
              const SizedBox(height: 24),

              // --- СПУСТИТЬСЯ В МО ---
              _DashCard(
                title: 'DOWN TO THE ENGINE',
                subtitle: 'Спуститься в МО (MARPOL, Fuel & Tanks)',
                icon: Icons.settings_outlined,
                onTap: () => context.push('/engine'),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardSolid,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(16),
        ),
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