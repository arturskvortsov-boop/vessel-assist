import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../core/dms_coordinate.dart';
import '../deck/port_distance/route_map.dart' show readLand;
import '../deck/port_distance/sea_routes.dart';
import 'passage_map.dart';
import 'passage_route.dart';

typedef _PositionFix = ({
  SeaPoint point,
  DateTime time,
  double? accuracy,
  double? speed,
});

class PassagePlannerScreen extends StatefulWidget {
  const PassagePlannerScreen({super.key});

  @override
  State<PassagePlannerScreen> createState() => _PassagePlannerScreenState();
}

class _PassagePlannerScreenState extends State<PassagePlannerScreen> {
  static const _storageKey = 'passage_planner_route_v1';
  static const _libraryKey = 'passage_planner_library_v1';
  List<PassageRoute> _savedRoutes = [];
  final _speed = TextEditingController();
  final _utc = DateFormat('yyyy-MM-dd HH:mm');
  late final Future<List<List<List<SeaPoint>>>> _land;
  PassageRoute _route = PassageRoute('Untitled route', const []);
  _PositionFix? _position;
  int? _next;
  bool _busy = false;
  bool _fitRoute = true;
  int _mapRevision = 0;

  @override
  void initState() {
    super.initState();
    _land = rootBundle
        .loadString('assets/data/sea_routes/land.geojson')
        .then(readLand);
    final library = _settings?.get(_libraryKey);
    if (library is String) {
      try {
        _savedRoutes = [
          for (final item in jsonDecode(library) as List)
            PassageRoute.fromJson(item as Map<String, dynamic>),
        ];
      } catch (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _notice('Could not read the saved route library.');
        });
      }
    }
    final stored = _settings?.get(_storageKey);
    if (stored is String) {
      try {
        _route = PassageRoute.fromJson(
          jsonDecode(stored) as Map<String, dynamic>,
        );
      } catch (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _notice('Could not read the saved route.');
        });
      }
    }
  }

  Box<dynamic>? get _settings =>
      Hive.isBoxOpen('settings') ? Hive.box('settings') : null;

  @override
  void dispose() {
    _speed.dispose();
    super.dispose();
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveRoute(
    PassageRoute route, {
    int? next,
    bool resetMap = false,
  }) async {
    setState(() {
      _route = route;
      _next = next;
      if (resetMap) {
        _fitRoute = true;
        _mapRevision++;
      }
    });
    try {
      await _settings?.put(_storageKey, jsonEncode(route.toJson()));
    } catch (_) {
      if (mounted) _notice('Could not save this route on the device.');
    }
  }

  Future<void> _saveToLibrary() async {
    var name = _route.name == 'Untitled route' ? '' : _route.name;
    final selectedName = await showDialog<String>(
      context: context,
      builder: (context) {
        final form = GlobalKey<FormState>();
        return AlertDialog(
          title: const Text('Save route'),
          content: Form(
            key: form,
            child: TextFormField(
              initialValue: name,
              autofocus: true,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Route name'),
              onChanged: (value) => name = value,
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter a route name.' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(context, name.trim());
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (!mounted || selectedName == null) return;
    final existing = _savedRoutes.indexWhere(
      (route) => route.name.toLowerCase() == selectedName.toLowerCase(),
    );
    if (existing >= 0) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace saved route?'),
          content: Text(
            'A route named "${_savedRoutes[existing].name}" already exists.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (!mounted || replace != true) return;
    }

    final route = PassageRoute(selectedName, _route.waypoints);
    final updated = [..._savedRoutes];
    if (existing < 0) {
      updated.insert(0, route);
    } else {
      updated[existing] = route;
    }
    setState(() => _busy = true);
    try {
      final settings = _settings;
      if (settings == null) throw StateError('Local storage is unavailable.');
      await settings.put(
        _libraryKey,
        jsonEncode([for (final item in updated) item.toJson()]),
      );
      if (!mounted) return;
      setState(() => _savedRoutes = updated);
      await _saveRoute(route, next: _next);
      if (mounted) _notice('Route saved.');
    } catch (_) {
      if (mounted) _notice('Could not save this route on the device.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSavedRoute() async {
    final route = await showDialog<PassageRoute>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved routes'),
        scrollable: true,
        content: SizedBox(
          width: 420,
          child: _savedRoutes.isEmpty
              ? const Text('No saved routes yet.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final route in _savedRoutes)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.route_outlined),
                        title: Text(route.name),
                        subtitle: Text(
                          '${route.waypoints.length} waypoints · ${route.totalDistance.toStringAsFixed(1)} NM',
                        ),
                        onTap: () => Navigator.pop(context, route),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (mounted && route != null) await _saveRoute(route, resetMap: true);
  }

  Future<void> _importRoute() async {
    setState(() => _busy = true);
    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['rt3'],
        withData: kIsWeb,
      );
      if (!mounted || selection == null) return;
      final file = selection.files.single;
      if (file.size > 2 * 1024 * 1024) {
        throw const FormatException('The RT3 file is too large.');
      }
      final fallbackName = file.name.replaceFirst(
        RegExp(r'\.rt3$', caseSensitive: false),
        '',
      );
      final route = parseRt3(
        await selection.xFiles.single.readAsBytes(),
        fallbackName: fallbackName,
      );
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(route.name),
          scrollable: true,
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${route.waypoints.length} waypoints · ${route.totalDistance.toStringAsFixed(1)} NM',
                ),
                Text(
                  '${route.waypoints.first.name} → ${route.waypoints.last.name}',
                ),
                const SizedBox(height: 12),
                SizedBox(height: 200, child: _map(route: route, preview: true)),
                const SizedBox(height: 8),
                const Text('Schematic map — not for navigation.'),
                if (_route.waypoints.isNotEmpty)
                  const Text(
                    'Opening will replace the current route on the map.',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open route'),
            ),
          ],
        ),
      );
      if (mounted && confirmed == true) await _saveRoute(route, resetMap: true);
    } on FormatException catch (error) {
      if (mounted) _notice(error.message);
    } catch (_) {
      if (mounted) _notice('Could not import this RT3 route.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editWaypoint({int? index, SeaPoint? mapPoint}) async {
    if (_busy) return;
    final old = index == null ? null : _route.waypoints[index];
    final waypoint = await showDialog<PassageWaypoint>(
      context: context,
      builder: (_) => _PointDialog(
        title: index == null
            ? 'Add waypoint'
            : mapPoint == null
            ? 'Edit waypoint'
            : 'Confirm waypoint position',
        confirmMove: index != null && mapPoint != null,
        initial: mapPoint ?? old?.point,
        name: old?.name ?? 'WP ${_route.waypoints.length + 1}',
      ),
    );
    if (!mounted || waypoint == null) return;
    final waypoints = [..._route.waypoints];
    if (index == null) {
      waypoints.add(waypoint);
    } else {
      waypoints[index] = waypoint;
    }
    await _saveRoute(
      PassageRoute(_route.name, waypoints),
      next: _next,
      resetMap: true,
    );
  }

  void _moveWaypoint(int from, int to) {
    final points = [..._route.waypoints];
    final selected = _next == null ? null : points[_next!];
    points.insert(to, points.removeAt(from));
    _saveRoute(
      PassageRoute(_route.name, points),
      next: selected == null ? null : points.indexOf(selected),
    );
  }

  Future<void> _clearWaypoints() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all waypoints?'),
        content: const Text('This removes all points from the current route.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear waypoints'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _saveRoute(PassageRoute('Untitled route', const []), resetMap: true);
  }

  void _removeWaypoint(int index) {
    final points = [..._route.waypoints];
    final selected = _next == null ? null : points[_next!];
    final removed = points.removeAt(index);
    _saveRoute(
      PassageRoute(_route.name, points),
      next: selected == null || identical(removed, selected)
          ? null
          : points.indexOf(selected),
      resetMap: true,
    );
  }

  Future<void> _manualPosition() async {
    final point = await showDialog<PassageWaypoint>(
      context: context,
      builder: (_) =>
          _PointDialog(title: 'Enter position', initial: _position?.point),
    );
    if (!mounted || point == null) return;
    setState(() {
      _position = (
        point: point.point,
        time: DateTime.now().toUtc(),
        accuracy: null,
        speed: null,
      );
      _mapRevision++;
    });
  }

  Future<void> _gpsPosition() async {
    setState(() => _busy = true);
    try {
      if (!kIsWeb) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            _notice('Allow location access or enter the position manually.');
          }
          return;
        }
      }
      final fix = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      if (!validPassagePoint(fix.latitude, fix.longitude)) {
        _notice('The device returned invalid coordinates.');
        return;
      }
      setState(() {
        _position = (
          point: (lat: fix.latitude, lon: fix.longitude),
          time: fix.timestamp.toUtc(),
          accuracy: fix.accuracy.isFinite && fix.accuracy >= 0
              ? fix.accuracy
              : null,
          speed: fix.speed.isFinite && fix.speed > 0
              ? fix.speed * 3600 / 1852
              : null,
        );
        _mapRevision++;
      });
    } catch (_) {
      if (mounted) {
        _notice(
          'Position unavailable. Check location permissions or enter it manually.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _map({required PassageRoute route, bool preview = false}) =>
      FutureBuilder<List<List<List<SeaPoint>>>>(
        future: _land,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Map unavailable.'));
          }
          final land = snapshot.data;
          if (land == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return PassageMap(
            key: ValueKey(_mapRevision),
            land: land,
            waypoints: route.waypoints,
            position: preview ? null : _position?.point,
            next: preview ? null : _next,
            fitRoute: preview || _fitRoute,
            onMove: preview || _busy
                ? null
                : (index, point) =>
                      _editWaypoint(index: index, mapPoint: point),
            onAdd: preview || _busy
                ? null
                : (point) => _editWaypoint(mapPoint: point),
          );
        },
      );

  String _coordinates(SeaPoint point) =>
      '${point.lat.toStringAsFixed(5)}°, ${point.lon.toStringAsFixed(5)}°';

  @override
  Widget build(BuildContext context) {
    final points = _route.waypoints;
    final position = _position;
    final next = _next;
    final remaining = position != null && next != null
        ? _route.remainingDistance(position.point, next)
        : null;
    final speedText = _speed.text.trim();
    final manualSpeed = double.tryParse(speedText.replaceAll(',', '.'));
    final validSpeed =
        manualSpeed != null && manualSpeed.isFinite && manualSpeed > 0;
    final sog = speedText.isEmpty
        ? position?.speed
        : (validSpeed ? manualSpeed : null);
    final hours = remaining != null && sog != null ? remaining / sog : null;
    final eta = hours != null && hours.isFinite && hours <= 87600
        ? position!.time.add(Duration(seconds: (hours * 3600).round()))
        : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Passage Planner')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(_route.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _importRoute,
                    icon: const Icon(Icons.file_open_outlined),
                    label: const Text('Import RT3'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _editWaypoint(),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Add waypoint'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy || points.isEmpty ? null : _saveToLibrary,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save route'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _openSavedRoute,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Saved routes'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy || points.isEmpty ? null : _clearWaypoints,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Clear waypoints'),
                  ),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _fitRoute = !_fitRoute;
                      _mapRevision++;
                    }),
                    child: Text(_fitRoute ? 'World view' : 'Fit route'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(height: 320, child: _map(route: _route)),
              const SizedBox(height: 6),
              const Text(
                'Schematic map — not for navigation. Hold a waypoint and drag to move it. Hold an empty area to add one.',
              ),
              const SizedBox(height: 16),
              Text(
                'Update position',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _busy ? null : _manualPosition,
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: const Text('Enter manually'),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : _gpsPosition,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use GPS'),
                  ),
                ],
              ),
              if (_busy) const LinearProgressIndicator(),
              if (position != null)
                Text(
                  [
                    position.accuracy == null
                        ? 'Position'
                        : 'Device position ±${position.accuracy!.round()} m',
                    _coordinates(position.point),
                    '${_utc.format(position.time)} UTC',
                    if (position.speed != null)
                      'SOG ${position.speed!.toStringAsFixed(2)} kn',
                  ].join(' · '),
                ),
              const SizedBox(height: 12),
              if (points.isNotEmpty)
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Next waypoint'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: next,
                      isExpanded: true,
                      isDense: true,
                      hint: const Text('Select next waypoint for ETA'),
                      items: [
                        for (final (index, point) in points.indexed)
                          DropdownMenuItem(
                            value: index,
                            child: Text(
                              '${index + 1}. ${point.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _next = value),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _speed,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Manual speed (optional)',
                  suffixText: 'kn',
                  helperText: 'Leave blank to use GPS speed.',
                  errorText: speedText.isNotEmpty && !validSpeed
                      ? 'Enter a speed greater than zero.'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Total Dist: ${points.length < 2 ? '—' : '${_route.totalDistance.toStringAsFixed(1)} NM'}',
                      ),
                      Text(
                        'Remaining Dist: ${remaining == null ? '—' : '${remaining.toStringAsFixed(1)} NM'}',
                      ),
                      Text(
                        'ETA: ${eta == null ? '—' : '${_utc.format(eta)} UTC'}',
                      ),
                    ],
                  ),
                ),
              ),
              if (points.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Waypoints',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final (index, point) in points.indexed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(point.name),
                    subtitle: Text(
                      [
                        _coordinates(point.point),
                        if (index > 0)
                          '${distanceNm(points[index - 1].point, point.point).toStringAsFixed(1)} NM from previous',
                      ].join(' · '),
                    ),
                    onTap: _busy ? null : () => _editWaypoint(index: index),
                    trailing: PopupMenuButton<String>(
                      enabled: !_busy,
                      tooltip: 'Waypoint actions',
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        if (index > 0)
                          const PopupMenuItem(
                            value: 'up',
                            child: Text('Move up'),
                          ),
                        if (index < points.length - 1)
                          const PopupMenuItem(
                            value: 'down',
                            child: Text('Move down'),
                          ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove'),
                        ),
                      ],
                      onSelected: (action) {
                        switch (action) {
                          case 'edit':
                            _editWaypoint(index: index);
                          case 'up':
                            _moveWaypoint(index, index - 1);
                          case 'down':
                            _moveWaypoint(index, index + 1);
                          case 'remove':
                            _removeWaypoint(index);
                        }
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PointDialog extends StatefulWidget {
  const _PointDialog({
    required this.title,
    this.initial,
    this.name,
    this.confirmMove = false,
  });

  final String title;
  final SeaPoint? initial;
  final String? name;
  final bool confirmMove;

  @override
  State<_PointDialog> createState() => _PointDialogState();
}

class _PointDialogState extends State<_PointDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  final _lat = DmsCoordinate('N', 'S', 90);
  final _lon = DmsCoordinate('E', 'W', 180);
  bool _coordinateError = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _lat.setDecimal(initial.lat);
      _lon.setDecimal(initial.lon);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      ..._lat.controllers,
      ..._lon.controllers,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _coordinate(String label, DmsCoordinate coordinate) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Row(
        children: [
          for (final (controller, unit) in [
            (coordinate.degrees, 'Deg °'),
            (coordinate.minutes, 'Min ′'),
            (coordinate.seconds, 'Sec ″'),
          ]) ...[
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: unit,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() => _coordinateError = false),
              ),
            ),
            const SizedBox(width: 6),
          ],
          SizedBox(
            width: 55,
            child: DropdownButtonFormField<String>(
              initialValue: coordinate.hemisphere,
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 6),
              ),
              items: [
                for (final direction in [
                  coordinate.positive,
                  coordinate.negative,
                ])
                  DropdownMenuItem(value: direction, child: Text(direction)),
              ],
              onChanged: (value) {
                if (value != null) coordinate.hemisphere = value;
              },
            ),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    scrollable: true,
    content: Form(
      key: _form,
      child: SizedBox(
        width: 330,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.name != null) ...[
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Waypoint name'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter a name.' : null,
              ),
              const SizedBox(height: 12),
            ],
            _coordinate('Latitude', _lat),
            const SizedBox(height: 12),
            _coordinate('Longitude', _lon),
            if (_coordinateError)
              Text(
                'Enter valid degrees, minutes and seconds.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final lat = _lat.decimal;
          final lon = _lon.decimal;
          final validName = _form.currentState!.validate();
          setState(() => _coordinateError = lat == null || lon == null);
          if (!validName || lat == null || lon == null) return;
          Navigator.pop(
            context,
            PassageWaypoint(_name.text.trim(), (lat: lat, lon: lon)),
          );
        },
        child: Text(widget.confirmMove ? 'Confirm position' : 'Save'),
      ),
    ],
  );
}
