import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../domain/models/port.dart';

class PortsScreen extends StatefulWidget {
  const PortsScreen({super.key});

  @override
  State<PortsScreen> createState() => _PortsScreenState();
}

class _PortsScreenState extends State<PortsScreen> {
  List<Port> _allPorts = [];
  List<Port> _filteredPorts = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPorts();
  }

  Future<void> _loadPorts() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/ports.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List<dynamic> portsJson = data['ports'];
      
      setState(() {
        _allPorts = portsJson.map((p) => Port.fromJson(p)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading ports: $e')));
      }
    }
  }

  void _search(String query) {
    if (query.length < 2) {
      setState(() => _filteredPorts = []);
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      // Ищем по строке поиска и ограничиваем результат 50 портами для скорости
      _filteredPorts = _allPorts
          .where((p) => p.searchString.contains(lowerQuery))
          .take(50)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Port Codes'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accent))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _search,
                    decoration: InputDecoration(
                      hintText: 'Search port name, UN/LOCODE or country...',
                      prefixIcon: const Icon(Icons.search, color: accent),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _search('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredPorts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.travel_explore, size: 60, color: accent.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              const Text(
                                'Enter at least 2 characters.\nTry Rotterdam, NLRTM or NL RTM.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: textMuted, height: 1.5),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredPorts.length,
                          itemBuilder: (context, index) {
                            final port = _filteredPorts[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: cardSolid,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: border),
                              ),
                              child: ListTile(
                                title: Text(port.name, style: const TextStyle(color: text, fontWeight: FontWeight.bold)),
                                subtitle: Text('${port.country} • ${port.coordinates}', style: const TextStyle(color: textMuted, fontSize: 12)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(port.code, style: const TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                onTap: () {
                                  // Копируем код порта в буфер обмена при нажатии
                                  Clipboard.setData(ClipboardData(text: port.code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Copied code: ${port.code}')),
                                  );
                                },
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