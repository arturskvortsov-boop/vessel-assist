import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          ListTile(
            tileColor: const Color(0xFF0D1627),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.storage, color: Color(0xFF38BDF8)),
            title: const Text('Tank Status', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Volumes & ROB', style: TextStyle(color: Color(0xFF8B9BB4))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF38BDF8)),
            onTap: () => context.push('/engine/tanks'),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: const Color(0xFF0D1627),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.calculate, color: Color(0xFF38BDF8)),
            title: const Text('Fuel Daily Log', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Consumption & ROB', style: TextStyle(color: Color(0xFF8B9BB4))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF38BDF8)),
            onTap: () => context.push('/engine/fuel_log'),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: const Color(0xFF0D1627),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.menu_book, color: Color(0xFF38BDF8)),
            title: const Text('ORB Generator', style: TextStyle(color: Colors.white)),
            subtitle: const Text('MARPOL Record Book', style: TextStyle(color: Color(0xFF8B9BB4))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF38BDF8)),
            onTap: () => context.push('/engine/orb'),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: const Color(0xFF0D1627),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.checklist, color: Color(0xFF38BDF8)),
            title: const Text('Bunkering Checklists', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Before, During & After loading', style: TextStyle(color: Color(0xFF8B9BB4))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF38BDF8)),
            onTap: () => context.push('/engine/bunker_checklist'),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: const Color(0xFF0D1627),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.gavel, color: Color(0xFF38BDF8)),
            title: const Text('Letter of Protest', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Bunkering disputes & claims', style: TextStyle(color: Color(0xFF8B9BB4))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF38BDF8)),
            onTap: () => context.push('/engine/lop'),
          ),
        ],
      ),
    );
  }
}