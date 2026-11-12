import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme.dart';
import '../router.dart'; // <--- Импортируем ключ

class GlobalClock extends StatefulWidget {
  const GlobalClock({super.key});

  @override
  State<GlobalClock> createState() => _GlobalClockState();
}

class _GlobalClockState extends State<GlobalClock> {
  DateTime _now = DateTime.now().toUtc();
  late Timer _timer;
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now().toUtc());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _editOffset() {
    final currentOffset = _settingsBox.get('localOffset', defaultValue: 0.0);
    final ctrl = TextEditingController(text: currentOffset.toString());

    showDialog(
      context: rootNavigatorKey.currentContext!, // <--- Используем глобальный контекст
      builder: (ctx) => AlertDialog(
        backgroundColor: cardSolid,
        title: const Text('Set Local Time Offset', style: TextStyle(color: text)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Offset in hours (e.g. 3, -1.5)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null) {
                _settingsBox.put('localOffset', val);
                setState(() {});
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      )
    );
  }

  String _formatTime(DateTime time, double offsetHours) {
    final adjusted = time.add(Duration(minutes: (offsetHours * 60).round()));
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(adjusted.hour)}:${two(adjusted.minute)}:${two(adjusted.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final offset = _settingsBox.get('localOffset', defaultValue: 0.0);
    
    return Material(
      color: cardSolid,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // UTC
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('UTC', style: TextStyle(color: textMuted, fontSize: 10, letterSpacing: 1)),
                Text(_formatTime(_now, 0), style: const TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ],
            ),
            
            Expanded(
              child: Center(
                child: Semantics(
                  label: 'Home',
                  child: IconButton(
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered) &&
                            !states.contains(WidgetState.focused) &&
                            !states.contains(WidgetState.pressed)) {
                          return Colors.transparent;
                        }
                        return null;
                      }),
                    ),
                    icon: const Icon(Icons.home_outlined, color: accent),
                    onPressed: () => appRouter.go('/'),
                  ),
                ),
              ),
            ),

            // LOCAL (с кнопкой настройки)
            InkWell(
              onTap: _editOffset,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('LOCAL (UTC${offset >= 0 ? '+' : ''}$offset)', style: const TextStyle(color: textMuted, fontSize: 10, letterSpacing: 1)),
                      Text(_formatTime(_now, offset), style: const TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.settings, color: textMuted, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}