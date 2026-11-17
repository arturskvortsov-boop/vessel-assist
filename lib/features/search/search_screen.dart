import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/palette_state.dart';
import '../../core/widgets/app_scaffold.dart';

/// Запись каталога экранов для поиска.
class _ScreenEntry {
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final AppSection section;

  const _ScreenEntry({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.section,
  });
}

/// Каталог всех экранов приложения (для глобального поиска).
const List<_ScreenEntry> _catalog = [
  // --- Bridge & Deck ---
  _ScreenEntry(title: 'ETA Calculator', subtitle: 'Arrival time, required speed & eco/full split', route: '/deck/eta', icon: Icons.schedule, section: AppSection.bridge),
  _ScreenEntry(title: 'Port Distance', subtitle: 'Sea distance & time at sea', route: '/deck/port_distance', icon: Icons.route, section: AppSection.bridge),
  _ScreenEntry(title: 'True Wind Calculator', subtitle: 'True and apparent wind vectors', route: '/deck/true_wind', icon: Icons.air, section: AppSection.bridge),
  _ScreenEntry(title: 'Compass Error Calculator', subtitle: 'Gyro and magnetic compass checks', route: '/deck/compass_error', icon: Icons.explore_outlined, section: AppSection.bridge),
  _ScreenEntry(title: 'UKC Calculator', subtitle: 'Under-keel clearance', route: '/deck/ukc', icon: Icons.waves, section: AppSection.bridge),
  _ScreenEntry(title: 'Safety Depth', subtitle: 'Vessel settings & calculation', route: '/deck/safety_depth', icon: Icons.straighten, section: AppSection.bridge),
  _ScreenEntry(title: 'Cargo Tanks', subtitle: 'Volumes, density & Excel export', route: '/deck/cargo_tanks', icon: Icons.storage, section: AppSection.bridge),
  _ScreenEntry(title: 'Draft Survey', subtitle: 'Cargo weight from draft readings', route: '/deck/draft_survey', icon: Icons.calculate_outlined, section: AppSection.bridge),
  _ScreenEntry(title: 'Ballast Time', subtitle: 'Pumping duration', route: '/deck/ballast_time', icon: Icons.water, section: AppSection.bridge),
  _ScreenEntry(title: 'GM Estimate', subtitle: 'Stability from roll period', route: '/deck/gm_roll', icon: Icons.straighten, section: AppSection.bridge),
  _ScreenEntry(title: 'Logbook Records', subtitle: 'Inspection wording & schedule', route: '/deck/logbook', icon: Icons.menu_book, section: AppSection.bridge),
  _ScreenEntry(title: 'Crew Tasks (Deck)', subtitle: 'Assignments, deadlines & status', route: '/deck/tasks', icon: Icons.task_alt, section: AppSection.bridge),
  _ScreenEntry(title: 'Port Codes', subtitle: 'Search ports by UN/LOCODE', route: '/deck/ports', icon: Icons.travel_explore, section: AppSection.bridge),

  // --- Engine Operations ---
  _ScreenEntry(title: 'Tank Status', subtitle: 'Volumes, ROB & Free space', route: '/engine/tanks', icon: Icons.storage, section: AppSection.engine),
  _ScreenEntry(title: 'ORB Generator', subtitle: 'MARPOL Record Book entries', route: '/engine/orb', icon: Icons.menu_book, section: AppSection.engine),
  _ScreenEntry(title: 'Fuel Changeover', subtitle: 'Fuel switch logbook records', route: '/engine/changeover', icon: Icons.swap_horiz, section: AppSection.engine),
  _ScreenEntry(title: 'EGCS Record Book', subtitle: 'Scrubber operations & failures', route: '/engine/egcs', icon: Icons.air, section: AppSection.engine),
  _ScreenEntry(title: 'Bunkering Checklists', subtitle: 'Before, During & After loading', route: '/engine/bunker_checklist', icon: Icons.checklist, section: AppSection.engine),
  _ScreenEntry(title: 'Letters of Protest', subtitle: 'Bunkering disputes & claims', route: '/engine/lop', icon: Icons.gavel, section: AppSection.engine),
  _ScreenEntry(title: 'Fuel Daily Log', subtitle: 'Consumption & ROB (3 schemes)', route: '/engine/fuel_log', icon: Icons.calculate, section: AppSection.engine),
  _ScreenEntry(title: 'Lube Oil', subtitle: 'Feed rate, Top-up & DG sump tanks', route: '/engine/lube', icon: Icons.water_drop, section: AppSection.engine),
  _ScreenEntry(title: 'Pump Calculator', subtitle: 'Transfer time & overflow check', route: '/engine/pump', icon: Icons.water, section: AppSection.engine),
  _ScreenEntry(title: 'Voyage Plan', subtitle: 'Fuel requirement & arrival ROB', route: '/engine/voyage', icon: Icons.map, section: AppSection.engine),
  _ScreenEntry(title: 'Engine Hours', subtitle: 'Machinery running hours', route: '/engine/hours', icon: Icons.timer, section: AppSection.engine),
  _ScreenEntry(title: 'Night Orders', subtitle: 'Watch instructions', route: '/engine/night_orders', icon: Icons.nights_stay, section: AppSection.engine),
  _ScreenEntry(title: 'Crew Tasks (Engine)', subtitle: 'To-do list and assignments', route: '/engine/tasks', icon: Icons.assignment, section: AppSection.engine),
  _ScreenEntry(title: 'Emergency', subtitle: 'Contacts & Procedures', route: '/engine/emergency', icon: Icons.warning_amber_rounded, section: AppSection.engine),
  _ScreenEntry(title: 'Spares & Stores', subtitle: 'Inventory & Requisitions', route: '/engine/spares', icon: Icons.inventory_2, section: AppSection.engine),
  _ScreenEntry(title: 'Warranty Claims', subtitle: 'Defect tracker & expiry alerts', route: '/engine/warranty', icon: Icons.shield, section: AppSection.engine),
  _ScreenEntry(title: 'Delivery & Acceptance', subtitle: 'Checklists & Punch List', route: '/engine/delivery', icon: Icons.assignment_turned_in, section: AppSection.engine),
  _ScreenEntry(title: 'Notes', subtitle: 'Quick reminders & inspector notes', route: '/engine/notes', icon: Icons.sticky_note_2, section: AppSection.engine),
  _ScreenEntry(title: 'Document Storage', subtitle: 'Scanned manuals & certificates', route: '/engine/documents', icon: Icons.folder_copy, section: AppSection.engine),
  _ScreenEntry(title: 'Backup & Restore', subtitle: 'Save or load all app data', route: '/engine/backup', icon: Icons.cloud_sync, section: AppSection.engine),

  // --- Admin & Documents ---
  _ScreenEntry(title: 'Document Storage', subtitle: 'Scanned manuals & certificates', route: '/admin/documents', icon: Icons.folder_copy, section: AppSection.admin),
  _ScreenEntry(title: 'Organizer', subtitle: 'Notes, documents & expiry', route: '/admin/organizer', icon: Icons.event_note, section: AppSection.admin),
  _ScreenEntry(title: 'Scan to PDF', subtitle: 'Create a PDF from photos', route: '/admin/scan_to_pdf', icon: Icons.document_scanner_outlined, section: AppSection.admin),
  _ScreenEntry(title: 'Date & Time Stamper', subtitle: 'Add a date or time to photos', route: '/admin/date_time_stamper', icon: Icons.date_range_outlined, section: AppSection.admin),
  _ScreenEntry(title: 'Unit Converter', subtitle: 'Convert maritime and everyday units', route: '/admin/unit_converter', icon: Icons.swap_horiz, section: AppSection.admin),
  _ScreenEntry(title: 'Compress Photos', subtitle: 'Resize photos and adjust JPEG quality', route: '/admin/compress_photos', icon: Icons.photo_size_select_large_outlined, section: AppSection.admin),
  _ScreenEntry(title: 'Compress PDF', subtitle: 'Create a smaller PDF copy', route: '/admin/compress_pdf', icon: Icons.picture_as_pdf_outlined, section: AppSection.admin),
  _ScreenEntry(title: 'Backup & Restore', subtitle: 'Save or load all app data', route: '/admin/backup', icon: Icons.cloud_sync, section: AppSection.admin),
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<_ScreenEntry> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _catalog;
    return _catalog.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.subtitle.toLowerCase().contains(q) ||
          e.route.toLowerCase().contains(q);
    }).toList();
  }

  String _sectionLabel(AppSection s) => switch (s) {
        AppSection.bridge => 'Bridge & Deck',
        AppSection.engine => 'Engine Operations',
        AppSection.admin => 'Admin & Documents',
      };

  @override
  Widget build(BuildContext context) {
    PaletteState.set(AppSection.bridge);
    final results = _results;

    return AppScaffold(
      title: 'Search',
      section: AppSection.bridge,
      showHomeFab: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search screens…',
                prefixIcon: Icon(Icons.search, color: accent),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, color: textMuted),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Text('Nothing found.', style: TextStyle(color: textMuted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final e = results[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: border),
                          ),
                          child: InkWell(
                            onTap: () => context.push(e.route),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(11),
                                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                                    ),
                                    child: Icon(e.icon, color: accent, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e.title,
                                            style: const TextStyle(
                                                color: text,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 3),
                                        Text(e.subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: textMuted, fontSize: 12)),
                                        const SizedBox(height: 3),
                                        Text(_sectionLabel(e.section),
                                            style: TextStyle(
                                                color: accent.withValues(alpha: 0.7),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: textMuted),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
