import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';

class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin & Documents'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('DOCUMENTS', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          _buildMenuCard(
            context: context,
            title: 'Document Storage',
            subtitle: 'Scanned manuals & certificates',
            icon: Icons.folder_copy,
            route: '/admin/documents',
          ),
          
          const SizedBox(height: 24),
          
          const Text('DATA MANAGEMENT', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          _buildMenuCard(
            context: context,
            title: 'Backup & Restore',
            subtitle: 'Save or load all app data',
            icon: Icons.cloud_sync,
            route: '/admin/backup',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({required BuildContext context, required String title, required String subtitle, required IconData icon, required String route}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }
}