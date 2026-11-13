import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import '../../../core/theme.dart';
import '../../../core/palette_state.dart';
import '../../../core/widgets/app_scaffold.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;

  // Список всех наших баз данных
  final List<String> _boxNames = [
    'tanks', 'fuel_logs', 'settings', 'bunker_checklists', 'tasks',
    'lube_rob', 'night_orders', 'engine_hours', 'changeover_history',
    'egcs_records', 'emergency_contacts', 'emergency_procedures',
    'spares', 'warranty', 'delivery_checklist', 'punch_list', 'notes',
    'orb_history'
  ];

  Future<void> _exportBackup() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> backupData = {};
      
      for (var boxName in _boxNames) {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          final Map<String, dynamic> boxData = {};
          for (var key in box.keys) {
            boxData[key.toString()] = box.get(key);
          }
          backupData[boxName] = boxData;
        }
      }

      final jsonString = jsonEncode(backupData);
      final date = DateTime.now().toString().split(' ')[0];
      
      await FileSaver.instance.saveFile(
        name: 'VesselAssist_Backup_$date',
        bytes: utf8.encode(jsonString),
        ext: 'json',
        mimeType: MimeType.json,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup saved successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isLoading = true);
      try {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> backupData = jsonDecode(jsonString);

        for (var boxName in backupData.keys) {
          if (_boxNames.contains(boxName)) {
            final box = Hive.box(boxName);
            await box.clear(); // Очищаем текущие данные перед восстановлением
            final Map<dynamic, dynamic> boxData = backupData[boxName];
            await box.putAll(boxData);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restored successfully!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error restoring: $e')));
        }
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    PaletteState.set(AppSection.engine);
        return AppScaffold(
      title: 'Backup & Restore',
      body: _isLoading      
        ? Center(child: CircularProgressIndicator(color: accent))
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(Icons.cloud_sync, size: 80, color: accent),
              const SizedBox(height: 24),
              const Text(
                'Data Management',
                textAlign: TextAlign.center,
                style: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Save all your data (Tanks, Logs, Tasks, Spares, etc.) into one file. You can send this file to yourself via Email/Telegram and restore it later on any device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 40),

              // Кнопка сохранения
              Container(
                decoration: BoxDecoration(
                  color: cardSolid,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.download, color: Colors.greenAccent, size: 36),
                  title: const Text('Save Backup File', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text('Export all data to JSON', style: TextStyle(color: textMuted, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: textMuted),
                  onTap: _exportBackup,
                ),
              ),

              const SizedBox(height: 16),

              // Кнопка восстановления
              Container(
                decoration: BoxDecoration(
                  color: cardSolid,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.upload, color: Colors.orangeAccent, size: 36),
                  title: const Text('Restore from Backup', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text('Import data from JSON file', style: TextStyle(color: textMuted, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: textMuted),
                  onTap: _importBackup,
                ),
              ),
              
              const SizedBox(height: 32),
              const Text(
                '⚠️ Warning: Restoring a backup will overwrite all current data in the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent, fontSize: 11),
              )
            ],
          ),
    );
  }
}
