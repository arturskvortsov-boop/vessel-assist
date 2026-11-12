import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для статус-бара
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}