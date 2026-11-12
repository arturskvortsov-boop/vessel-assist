import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для статус-бара
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/widgets/global_clock.dart';
import 'core/widgets/important_notice.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Делаем верхнюю полосу (где время и батарея) темной, а иконки белыми
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: bg,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  await Hive.initFlutter();
  
  // Все базы данных проекта
  await Hive.openBox('tanks');
  await Hive.openBox('fuel_logs');
  await Hive.openBox('settings');
  await Hive.openBox('bunker_checklists');
  await Hive.openBox('tasks');
  await Hive.openBox('lube_rob');
  await Hive.openBox('night_orders');
  await Hive.openBox('engine_hours');
  await Hive.openBox('changeover_history');
  await Hive.openBox('egcs_records');
  await Hive.openBox('emergency_contacts');
  await Hive.openBox('emergency_procedures');
  await Hive.openBox('spares');
  await Hive.openBox('warranty');
  await Hive.openBox('delivery_checklist');
  await Hive.openBox('punch_list');
  await Hive.openBox('notes');
  await Hive.openBox('orb_history');
  await Hive.openBox('cargo_tanks'); 
  
  runApp(
    const ProviderScope(
      child: VesselApp(),
    ),
  );
}











/// Плавающая кнопка "Домой" справа снизу (под правый палец).
/// Скрыта на splash и на главном экране.
class _HomeFab extends StatefulWidget {
  const _HomeFab();

  @override
  State<_HomeFab> createState() => _HomeFabState();
}

class _HomeFabState extends State<_HomeFab> {
  String _location = appRouter.routerDelegate.currentConfiguration.uri.path;

  @override
  void initState() {
    super.initState();
    appRouter.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    appRouter.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    final location = appRouter.routerDelegate.currentConfiguration.uri.path;
    if (location != _location && mounted) {
      setState(() => _location = location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hidden = _location == '/' || _location == '/splash';

    return Positioned(
      right: 16,
      bottom: 16,
      child: AnimatedSlide(
        offset: hidden ? const Offset(0, 1.5) : Offset.zero,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: hidden ? 0 : 1,
          duration: const Duration(milliseconds: 180),
          child: IgnorePointer(
            ignoring: hidden,
            child: FloatingActionButton(
              heroTag: 'home_fab',
              backgroundColor: cardSolid,
              foregroundColor: accent,
              elevation: 6,
              tooltip: 'Home',
              onPressed: () => context.go('/'),
              child: const Icon(Icons.home_outlined),
            ),
          ),
        ),
      ),
    );
  }
}

class VesselApp extends StatelessWidget {
  const VesselApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vessel Assist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
            builder: (context, child) => StartupNotice(
        child: Column(
          children: [
            const GlobalClock(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: child ?? const SizedBox.shrink()),
                  const _HomeFab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}