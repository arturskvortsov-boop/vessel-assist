import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/palette_state.dart';
import '../../core/section_theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/important_notice.dart';

class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    PaletteState.set(AppSection.admin);
                return AppScaffold(
      title: 'Admin & Documents',
      section: AppSection.admin,
      background: AppBackground.neutral,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('DOCUMENTS', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          _buildMenuCard(
            context: context,
            title: 'Document Storage',
            subtitle: 'Scanned manuals & certificates',
            icon: Icons.folder_copy,
            route: '/admin/documents',
          ),
          _buildMenuCard(
            context: context,
            title: 'Organizer',
            subtitle: 'Notes, documents & expiry',
            icon: Icons.event_note,
            route: '/admin/organizer',
          ),
          _buildMenuCard(
            context: context,
            title: 'Scan to PDF',
            subtitle: 'Create a PDF from photos',
            icon: Icons.document_scanner_outlined,
            route: '/admin/scan_to_pdf',
          ),
          _buildMenuCard(
            context: context,
            title: 'Date & Time Stamper',
            subtitle: 'Add a date or time to photos',
            icon: Icons.date_range_outlined,
            route: '/admin/date_time_stamper',
          ),
          _buildMenuCard(
            context: context,
            title: 'Unit Converter',
            subtitle: 'Convert maritime and everyday units',
            icon: Icons.swap_horiz,
            route: '/admin/unit_converter',
          ),
          _buildMenuCard(
            context: context,
            title: 'Compress Photos',
            subtitle: 'Resize photos and adjust JPEG quality',
            icon: Icons.photo_size_select_large_outlined,
            route: '/admin/compress_photos',
          ),
          _buildMenuCard(
            context: context,
            title: 'Compress PDF',
            subtitle: 'Create a smaller PDF copy',
            icon: Icons.picture_as_pdf_outlined,
            route: '/admin/compress_pdf',
          ),
          
          const SizedBox(height: 24),
          
          Text('DATA MANAGEMENT', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          _buildMenuCard(
            context: context,
            title: 'Backup & Restore',
            subtitle: 'Save or load all app data',
            icon: Icons.cloud_sync,
            route: '/admin/backup',
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: accent),
            title: const Text('Important Notice'),
            trailing: const Icon(Icons.chevron_right, color: textMuted),
            onTap: () => showImportantNotice(context),
          ),
        ],
      ),
    );
  }

    Widget _buildMenuCard({required BuildContext context, required String title, required String subtitle, required IconData icon, required String route}) {
    final palette = SectionTheme.of(context);
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
                  color: palette.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.accent.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: palette.accent, size: 24),
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
