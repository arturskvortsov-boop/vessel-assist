import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nautical_background.dart';
import 'theme.dart';
import '../features/deck/deck_menu_screen.dart';
import '../features/deck/gm_roll_screen.dart';
import '../features/engine_log/engine_log_screen.dart';
import '../features/engine_log/tanks/tanks_screen.dart';
import '../features/engine_log/fuel_log/fuel_log_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey, // <--- Привязываем ключ
  initialLocation: '/',
  routes: [
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
              // Заголовок (Градиентный текст)
              Text(
                'VESSEL ASSIST',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [gold, accent],
                    ).createShader(const Rect.fromLTWH(0.0, 0.0, 250.0, 70.0)),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'DECK & ENGINE PROFESSIONAL TOOLS',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 12, letterSpacing: 1.5),
              ),
              const SizedBox(height: 40),

              // Карточка Палубы (Deck)
              _DashCard(
                title: 'DECK',
                subtitle: 'Navigation and cargo operations',
                icon: Icons.explore,
                onTap: () => context.push('/deck'),
              ),
              const SizedBox(height: 16),
              
              // Карточка Машинного отделения (Engine)
              _DashCard(
                title: 'ENGINE',
                subtitle: 'EngineLog tools and records',
                icon: Icons.settings,
                onTap: () => context.push('/engine'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Виджет карточки для дашборда (как в CSS .dash-card)
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
                color: accent.withOpacity(0.1),
                border: Border.all(color: accent.withOpacity(0.2)),
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