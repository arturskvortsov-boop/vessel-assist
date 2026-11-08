import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class EngineLogScreen extends StatelessWidget {
  const EngineLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Engine Operations'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- ГРУППА 1: MARPOL & LOGS ---
          const Text('MARPOL & LOGS', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          _buildMenuCard(
            context: context,
            title: 'Tank Status',
            subtitle: 'Volumes, ROB & Free space to 85%',
            icon: Icons.storage,
            route: '/engine/tanks',
          ),
          _buildMenuCard(
            context: context,
            title: 'Fuel Changeover',
            subtitle: 'Fuel switch logbook records',
            icon: Icons.swap_horiz,
            route: '/engine/changeover',
          ),
          _buildMenuCard(
            context: context,
            title: 'ORB Generator',
            subtitle: 'MARPOL Record Book entries',
            icon: Icons.menu_book,
            route: '/engine/orb',
          ),
          _buildMenuCard(
            context: context,
            title: 'EGCS Record Book',
            subtitle: 'Scrubber operations & failures',
            icon: Icons.air,
            route: '/engine/egcs',
          ),
          _buildMenuCard(
            context: context,
            title: 'Bunkering Checklists',
            subtitle: 'Before, During & After loading',
            icon: Icons.checklist,
            route: '/engine/bunker_checklist',
          ),
          _buildMenuCard(
            context: context,
            title: 'Letters of Protest',
            subtitle: 'Bunkering disputes & claims',
            icon: Icons.gavel,
            route: '/engine/lop',
          ),

          const SizedBox(height: 24),

          // --- ГРУППА 2: ENGINE OPERATIONS ---
          const Text('ENGINE OPERATIONS', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          _buildMenuCard(
            context: context,
            title: 'Fuel Daily Log',
            subtitle: 'Consumption & ROB (3 schemes)',
            icon: Icons.calculate,
            route: '/engine/fuel_log',
          ),
          _buildMenuCard(
            context: context,
            title: 'Lube Oil',
            subtitle: 'Feed rate, Top-up & ROB Tracker',
            icon: Icons.water_drop,
            route: '/engine/lube',
          ),
          _buildMenuCard(
            context: context,
            title: 'Pump Calculator',
            subtitle: 'Transfer time & overflow check',
            icon: Icons.water,
            route: '/engine/pump',
          ),
          _buildMenuCard(
            context: context,
            title: 'Voyage Plan',
            subtitle: 'Fuel requirement & arrival ROB',
            icon: Icons.map,
            route: '/engine/voyage',
          ),
          _buildMenuCard(
            context: context,
            title: 'Crew Tasks',
            subtitle: 'To-do list and assignments',
            icon: Icons.assignment,
            route: '/engine/tasks',
          ),
          _buildMenuCard(
            context: context,
            title: 'Night Orders',
            subtitle: 'Watch instructions for engineers',
            icon: Icons.nights_stay,
            route: '/engine/night_orders',
          ),
          _buildMenuCard(
            context: context,
            title: 'Engine Hours',
            subtitle: 'Machinery running hours & history',
            icon: Icons.timer,
            route: '/engine/hours',
          ),

          const SizedBox(height: 24),

          // --- ГРУППА 3: SAFETY & EMERGENCY ---
          const Text('SAFETY & EMERGENCY', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          _buildMenuCard(
            context: context,
            title: 'Emergency',
            subtitle: 'Contacts & Procedures',
            icon: Icons.warning_amber_rounded,
            route: '/engine/emergency',
          ),

          const SizedBox(height: 24),

          // --- ГРУППА 4: DOCUMENTS & ADMIN ---
          const Text('DOCUMENTS & ADMIN', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          _buildMenuCard(
            context: context,
            title: 'Delivery & Acceptance',
            subtitle: 'Checklists & Punch List',
            icon: Icons.assignment_turned_in,
            route: '/engine/delivery',
          ),
          _buildMenuCard(
            context: context,
            title: 'Warranty Claims',
            subtitle: 'Defect tracker & expiry alerts',
            icon: Icons.shield,
            route: '/engine/warranty',
          ),
          _buildMenuCard(
            context: context,
            title: 'Spares & Stores',
            subtitle: 'Inventory & Requisitions',
            icon: Icons.inventory_2,
            route: '/engine/spares',
          ),
          _buildMenuCard(
            context: context,
            title: 'Notes',
            subtitle: 'Quick reminders & inspector notes',
            icon: Icons.sticky_note_2,
            route: '/engine/notes',
          ),
          _buildMenuCard(
            context: context,
            title: 'Document Storage',
            subtitle: 'Scanned manuals & certificates',
            icon: Icons.folder_copy,
            route: '/engine/documents',
          ),
          _buildMenuCard(
            context: context,
            title: 'Backup & Restore',
            subtitle: 'Save or load all app data',
            icon: Icons.cloud_sync,
            route: '/engine/backup',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardSolid,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 28),
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
              const Icon(Icons.chevron_right, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}