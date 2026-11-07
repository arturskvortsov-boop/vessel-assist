import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/widgets/global_clock.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tanks');
  await Hive.openBox('fuel_logs');
  await Hive.openBox('settings'); // База для настроек часов
  
  runApp(
    const ProviderScope(
      child: VesselApp(),
    ),
  );
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
      // Этот блок выводит часы на всех экранах сверху
      builder: (context, child) => Column(
        children: [
          const GlobalClock(),
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}