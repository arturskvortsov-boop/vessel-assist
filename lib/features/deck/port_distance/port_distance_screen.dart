import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../../../domain/models/port.dart';
import 'route_map.dart';
import 'sea_routes.dart';

class PortDistanceScreen extends StatefulWidget {
  const PortDistanceScreen({super.key});

  @override
  State<PortDistanceScreen> createState() => _PortDistanceScreenState();
}

class _RouteData {
  final List<Port> ports;
  final SeaNetwork network;
  final List<List<List<SeaPoint>>> land;

  const _RouteData(this.ports, this.network, this.land);

  static Future<_RouteData> load() async {
    final sources = await Future.wait([
      rootBundle.loadString('assets/data/ports.json'),
      rootBundle.loadString('assets/data/sea_routes/network.geojson'),
      rootBundle.loadString('assets/data/sea_routes/land.geojson'),
    ]);
    final ports = [
      for (final entry in jsonDecode(sources[0])['ports'] as List)
        Port.fromJson(entry as Map<String, dynamic>),
    ];
    return _RouteData(
      ports,
      SeaNetwork.fromGeoJson(sources[1]),
      readLand(sources[2]),
    );
  }
}

class _PortDistanceScreenState extends State<PortDistanceScreen> {
  late final Future<_RouteData> _data = _RouteData.load();
  final _speed = TextEditingController();
  Port? _departure;
  Port? _arrival;
  SeaRoute? _result;
  String? _routeError;
  bool _includeTime = false;

  @override
  void dispose() {
    _speed.dispose();
    super.dispose();
  }

  void _updatePort(bool departure, Port? port) {
    if ((departure ? _departure : _arrival) == port) return;
    setState(() {
      if (departure) {
        _departure = port;
      } else {
        _arrival = port;
      }
      _result = null;
      _routeError = null;
    });
  }

  void _calculate(SeaNetwork network) {
    final departure = _departure;
    final arrival = _arrival;
    final from = portPoint(departure?.coordinates ?? '');
    final to = portPoint(arrival?.coordinates ?? '');
    setState(() {
      _result = null;
      if (departure == null || arrival == null) {
        _routeError = 'Select both ports from the search results.';
      } else if (departure.code == arrival.code) {
        _routeError = 'Select two different ports.';
      } else if (from == null || to == null) {
        _routeError = 'Coordinates are unavailable for one of these ports.';
      } else {
        _result = network.shortestRoute(from, to);
        _routeError = _result == null
            ? 'No sea route available for these ports.'
            : null;
      }
    });
  }

  int? _timeMinutes(double distance) {
    final speed = double.tryParse(_speed.text.trim().replaceAll(',', '.'));
    if (speed == null || !speed.isFinite || speed <= 0) return null;
    final minutes = distance / speed * 60;
    if (!minutes.isFinite || minutes > 9007199254740991) return null;
    return minutes.round();
  }

  String _formatTime(int minutes) {
    if (minutes == 0) return '< 1 min';
    return [
      if (minutes >= 1440) '${minutes ~/ 1440} d',
      if (minutes % 1440 >= 60) '${minutes % 1440 ~/ 60} h',
      if (minutes % 60 != 0) '${minutes % 60} min',
    ].join(' ');
  }

  Widget _portField(List<Port> ports, {required bool departure}) {
    return Autocomplete<Port>(
      displayStringForOption: (port) => '${port.name} (${port.code})',
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.length < 2) return const <Port>[];
        return ports
            .where(
              (port) =>
                  port.code.toLowerCase().contains(query) ||
                  port.name.toLowerCase().contains(query) ||
                  port.searchString.contains(query),
            )
            .take(12);
      },
      onSelected: (port) => _updatePort(departure, port),
      fieldViewBuilder: (context, controller, focus, submit) {
        return TextField(
          controller: controller,
          focusNode: focus,
          onChanged: (_) => _updatePort(departure, null),
          onSubmitted: (_) => submit(),
          decoration: InputDecoration(
            labelText: departure ? 'Departure port' : 'Arrival port',
            hintText: 'Port name or UN/LOCODE',
            prefixIcon: const Icon(Icons.search),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Port Distance')),
      body: FutureBuilder(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load offline sea route data.'),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = _result;
          final minutes = result == null ? null : _timeMinutes(result.miles);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Distance only')),
                      ButtonSegment(
                        value: true,
                        label: Text('Distance & time'),
                      ),
                    ],
                    selected: {_includeTime},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) =>
                        setState(() => _includeTime = selection.single),
                  ),
                  const SizedBox(height: 16),
                  _portField(data.ports, departure: true),
                  const SizedBox(height: 12),
                  _portField(data.ports, departure: false),
                  if (_includeTime) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _speed,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Speed (kn)',
                        errorText: result != null && minutes == null
                            ? 'Enter a valid speed greater than 0 kn.'
                            : null,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      _calculate(data.network);
                    },
                    child: const Text('Calculate'),
                  ),
                  if (_routeError case final error?) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (result != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: cardSolid,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sea distance · ≈ ${result.miles.toStringAsFixed(1)} NM',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (_includeTime && minutes != null) ...[
                              const SizedBox(height: 6),
                              Text('Time at sea · ≈ ${_formatTime(minutes)}'),
                            ],
                            const SizedBox(height: 16),
                            RouteMap(
                              route: result,
                              land: data.land,
                              departureCode: _departure!.code,
                              arrivalCode: _arrival!.code,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Approximate route and estimates. For reference only. '
                              'Do not use for navigation.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
