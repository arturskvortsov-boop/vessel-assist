import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/models/port.dart';
import '../port_distance/route_map.dart' show readLand;
import '../port_distance/sea_routes.dart';

class PortTimeZoneScreen extends StatefulWidget {
  const PortTimeZoneScreen({super.key});

  @override
  State<PortTimeZoneScreen> createState() => _PortTimeZoneScreenState();
}

class _PortTimeZoneScreenState extends State<PortTimeZoneScreen> {
  late final _data = _load();
  Port? _selected;
  String _manualCoordinates = '';
  tz.Location? _manualZone;

  void _selectPort(Port? port) => setState(() {
    _selected = port;
    _manualCoordinates = '';
    _manualZone = null;
  });

  Future<
    ({
      List<Port> ports,
      Map<String, dynamic> zones,
      List<List<List<SeaPoint>>> land,
    })
  >
  _load() async {
    final files = await Future.wait([
      rootBundle.loadString('assets/data/ports.json'),
      rootBundle.loadString('assets/data/port_time_zones.json'),
      rootBundle.loadString('assets/data/sea_routes/land.geojson'),
    ]);
    tzdata.initializeTimeZones();
    return (
      ports: [
        for (final item in jsonDecode(files[0])['ports'] as List)
          Port.fromJson(item as Map<String, dynamic>),
      ],
      zones: jsonDecode(files[1])['zones'] as Map<String, dynamic>,
      land: readLand(files[2]),
    );
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Port Time Zone',
    body: FutureBuilder(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load port data.'));
        }
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final port = _selected;
        final catalogPoint = port == null ? null : portPoint(port.coordinates);
        final point = catalogPoint ?? manualPortPoint(_manualCoordinates);
        final zoneId = data.zones[port?.code];
        final catalogZone = zoneId is String
            ? tz.timeZoneDatabase.locations[zoneId]
            : null;
        final location = catalogZone ?? _manualZone;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            Autocomplete<Port>(
              displayStringForOption: (port) => '${port.name} (${port.code})',
              optionsBuilder: (value) {
                final query = value.text.trim().toLowerCase();
                if (query.isEmpty) return const <Port>[];
                return data.ports
                    .where(
                      (port) =>
                          port.code.toLowerCase() == query ||
                          port.name.toLowerCase().startsWith(query),
                    )
                    .followedBy(
                      data.ports.where(
                        (port) =>
                            !port.name.toLowerCase().startsWith(query) &&
                            port.code.toLowerCase() != query &&
                            (port.name.toLowerCase().contains(query) ||
                                port.code.toLowerCase().startsWith(query) ||
                                port.searchString.contains(query)),
                      ),
                    )
                    .take(30);
              },
              onSelected: _selectPort,
              fieldViewBuilder: (context, controller, focus, submit) =>
                  TextField(
                    controller: controller,
                    focusNode: focus,
                    onSubmitted: (_) => submit(),
                    onChanged: (_) {
                      if (_selected != null) _selectPort(null);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Search port by name or UN/LOCODE',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
            ),
            if (port != null) ...[
              const SizedBox(height: 16),
              Text(
                '${port.name} · ${port.code}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (catalogZone == null)
                Autocomplete<String>(
                  key: ValueKey(port.code),
                  optionsBuilder: (value) {
                    final query = value.text.trim().toLowerCase();
                    if (query.isEmpty) return const <String>[];
                    final zones = tz.timeZoneDatabase.locations.keys;
                    return zones
                        .where((zone) => zone.toLowerCase() == query)
                        .followedBy(
                          zones.where(
                            (zone) =>
                                zone.toLowerCase() != query &&
                                zone
                                    .toLowerCase()
                                    .replaceAll('_', ' ')
                                    .contains(query),
                          ),
                        )
                        .take(20);
                  },
                  onSelected: (zone) =>
                      setState(() => _manualZone = tz.getLocation(zone)),
                  fieldViewBuilder: (context, controller, focus, submit) =>
                      TextField(
                        controller: controller,
                        focusNode: focus,
                        onSubmitted: (_) => submit(),
                        onChanged: (_) {
                          if (_manualZone != null) {
                            setState(() => _manualZone = null);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Select time zone manually',
                          helperText: 'No time zone in the catalog. Search for a city or IANA time zone.',
                          helperMaxLines: 2,
                        ),
                      ),
                ),
              if (location != null)
                _PortClock(key: ValueKey(location.name), location: location),
              if (catalogPoint == null)
                TextFormField(
                  key: ValueKey((port.code, 'coordinates')),
                  onChanged: (value) =>
                      setState(() => _manualCoordinates = value),
                  decoration: const InputDecoration(
                    labelText: 'Port coordinates',
                    hintText: '54.35 18.65',
                    helperText: 'Latitude and longitude in decimal degrees, separated by a space.',
                    helperMaxLines: 2,
                  ),
                ),
              if (point != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  image: true,
                  label: 'Map showing ${port.name}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 260,
                      child: CustomPaint(painter: _PortMap(data.land, point)),
                    ),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    ),
  );
}

class _PortClock extends StatefulWidget {
  const _PortClock({super.key, required this.location});

  final tz.Location location;

  @override
  State<_PortClock> createState() => _PortClockState();
}

class _PortClockState extends State<_PortClock> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = tz.TZDateTime.now(widget.location);
    final minutes = local.timeZoneOffset.inMinutes.abs();
    final sign = local.timeZoneOffset.isNegative ? '−' : '+';
    final hoursText = (minutes ~/ 60).toString().padLeft(2, '0');
    final minutesText = (minutes % 60).toString().padLeft(2, '0');
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule),
        title: Text(
          DateFormat('HH:mm:ss').format(local),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        subtitle: Text(
          '${DateFormat('dd MMM yyyy').format(local)} · Local time\n'
          '${widget.location.name} · UTC$sign$hoursText:$minutesText',
        ),
      ),
    );
  }
}

class _PortMap extends CustomPainter {
  const _PortMap(this.land, this.point);

  final List<List<List<SeaPoint>>> land;
  final SeaPoint point;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final center = bounds.center;
    final scale = math.min(size.width / 360, size.height / 180);
    Offset project(SeaPoint p) =>
        center + Offset(p.lon * scale, -p.lat * scale);
    canvas.drawRect(bounds, Paint()..color = const Color(0xFF091D30));
    final fill = Paint()..color = const Color(0xFF28485A);
    for (final polygon in land) {
      final path = Path()..fillType = PathFillType.evenOdd;
      for (final ring in polygon) {
        path.addPolygon([for (final p in ring) project(p)], true);
      }
      canvas.drawPath(path, fill);
    }
    final pin = project(point);
    canvas.drawCircle(pin, 10, Paint()..color = const Color(0x664DDEDF));
    canvas.drawCircle(pin, 5, Paint()..color = const Color(0xFF63F0EA));
  }

  @override
  bool shouldRepaint(covariant _PortMap oldDelegate) =>
      oldDelegate.point != point || oldDelegate.land != land;
}
