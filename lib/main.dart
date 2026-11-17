import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для статус-бара
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/support_outbox.dart';
import 'core/widgets/global_clock.dart';
import 'core/widgets/important_notice.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Делаем верхнюю полосу (где время и батарея) темной, а иконки белыми
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
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
  
  try {
    await SupportOutbox.initialize();
    SupportOutbox.current?.record('app_open');
  } catch (error) {
    debugPrint('Could not initialize support outbox.');
  }

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
      builder: (context, child) {
        // В вебе/PWA браузер сообщает ненулевые safe-area отступы
        // (viewport-fit=cover + env(safe-area-inset)), из-за чего AppBar
        // «съезжает» вниз, а нижняя навигация висит выше края. Обнуляем
        // padding/viewPadding (viewInsets — клавиатуру — не трогаем).
                // GlobalClock сверху уже учитывает верхнюю safe-area (чёлка/статус-бар).
        // Поэтому нижележащим экранам (AppBar) верхний отступ больше не нужен —
        // иначе он учитывается дважды и заголовок «съезжает» вниз.
        final mq = MediaQuery.of(context);
        final childWithoutTopInset = MediaQuery(
          data: mq.copyWith(
            padding: mq.padding.copyWith(top: 0),
            viewPadding: mq.viewPadding.copyWith(top: 0),
          ),
          child: child ?? const SizedBox.shrink(),
        );

        Widget content = StartupNotice(
          child: Column(
            children: [
              const GlobalClock(),
              Expanded(child: childWithoutTopInset),
            ],
          ),
        );

        // В вебе/PWA браузер сообщает «фантомные» safe-area отступы снизу,
        // из-за чего нижняя навигация висит выше края. На десктопном браузере
        // обнуляем нижние отступы полностью.
        if (kIsWeb && MediaQuery.sizeOf(context).width >= 600) {
          content = MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
            ),
            child: content,
          );
        }
        return content;
      },
    );
  }
}
