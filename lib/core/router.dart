import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/deck/deck_menu_screen.dart';
import '../features/deck/gm_roll_screen.dart';
import '../features/engine_log/engine_log_screen.dart';

final appRouter = GoRouter(
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
    ),
  ],
);

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vessel Assist')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/deck'),
              child: const Text('Перейти на Палубу (Deck)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/engine'),
              child: const Text('Перейти в Машинное отделение (Engine)'),
            ),
          ],
        ),
      ),
    );
  }
}