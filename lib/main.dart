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
  await Hive.openBox('orb_history');
  await Hive.openBox('settings'); // База для настроек часов
  await Hive.openBox('bunker_checklists'); // База для чек-листов бункеровки
  await Hive.openBox('tasks'); // База для задач экипажу
  await Hive.openBox('lube_rob'); // База для остатков масел
  await Hive.openBox('night_orders'); // База для ночных приказов
  await Hive.openBox('engine_hours'); // База для наработки механизмов
  await Hive.openBox('changeover_history'); // База для записей смены топлива
  await Hive.openBox('egcs_records'); // База для журнала скруббера
  await Hive.openBox('emergency_contacts'); // База для аварийных контактов
  await Hive.openBox('emergency_procedures'); // База для аварийных процедур
  await Hive.openBox('spares'); // База для склада запчастей
  await Hive.openBox('warranty'); // База для гарантийных случаев
  
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