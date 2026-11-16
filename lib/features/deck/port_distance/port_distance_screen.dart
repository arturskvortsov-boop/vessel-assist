import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme.dart';
import '../../../core/dms_coordinate.dart';
import '../../../core/widgets/dms_coordinate_fields.dart';
import '../../../core/palette_state.dart';
import '../../../core/widgets/app_scaffold.dart';
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

enum _PositionSource { gps, manual }

class _PortDistanceScreenState extends State<PortDistanceScreen> {
  late final Future<_RouteData> _data = _RouteData.load();
  final _speed = TextEditingController();
  Port? _departure;
  Port? _arrival;
  String _departureCoordinates = '';
  String _arrivalCoordinates = '';
  SeaRoute? _result;
  String? _routeError;
  bool _includeTime = false;

  SeaPoint? _myPosition;
  bool _editingPosition = false;
  final _latitude = DmsCoordinate('N', 'S', 90);
  final _longitude = DmsCoordinate('E', 'W', 180);
  bool _locating = false;
  String? _locationError;

  @override
  void dispose() {
    _speed.dispose();
    for (final controller in [
      ..._latitude.controllers,
      ..._longitude.controllers,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Запрашивает текущую позицию с GPS и сохраняет её для отображения на карте.
  Future<void> _locateMe() async {
    setState(() {
      _locating = true;
      _editingPosition = false;
      _locationError = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permission denied.';
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      setState(() {
        _myPosition = (lat: pos.latitude, lon: pos.longitude);
        _locating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationError = e is String ? e : 'Could not get your position.';
      });
    }
  }

  void _choosePositionSource(_PositionSource source) {
    if (source == _PositionSource.gps) {
      _locateMe();
      return;
    }
    setState(() {
      _editingPosition = true;
      final point = _myPosition;
      if (point == null) {
        for (final controller in [
          ..._latitude.controllers,
          ..._longitude.controllers,
        ]) {
          controller.clear();
        }
        _latitude.hemisphere = 'N';
        _longitude.hemisphere = 'E';
      } else {
        _latitude.setDecimal(point.lat);
        _longitude.setDecimal(point.lon);
      }
      _locationError = null;
    });
  }

  void _setManualPosition(SeaPoint point) {
    FocusScope.of(context).unfocus();
    setState(() {
      _myPosition = point;
      _editingPosition = false;
    });
  }

  void _updatePort(bool departure, Port? port) {
    if ((departure ? _departure : _arrival) == port) return;
    setState(() {
      if (departure) {
        _departure = port;
        _departureCoordinates = '';
      } else {
        _arrival = port;
        _arrivalCoordinates = '';
      }
      _result = null;
      _routeError = null;
    });
  }

  void _calculate(SeaNetwork network) {
    final departure = _departure;
    final arrival = _arrival;
    final from =
        portPoint(departure?.coordinates ?? '') ??
        manualPortPoint(_departureCoordinates);
    final to =
        portPoint(arrival?.coordinates ?? '') ??
        manualPortPoint(_arrivalCoordinates);
    setState(() {
      _result = null;
      if (departure == null || arrival == null) {
        _routeError = 'Select both ports from the search results.';
      } else if (departure.code == arrival.code) {
        _routeError = 'Select two different ports.';
      } else if (from == null || to == null) {
        _routeError =
            'Enter valid coordinates for each port without a map position.';
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
        final exact = ports.where((port) => port.code.toLowerCase() == query);
        return exact
            .followedBy(
              ports.where(
                (port) =>
                    port.code.toLowerCase() != query &&
                    (port.code.toLowerCase().contains(query) ||
                        port.name.toLowerCase().contains(query) ||
                        port.searchString.contains(query)),
              ),
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

  Widget _coordinatesField(
    Port port, {
    required bool departure,
  }) => TextFormField(
    key: ValueKey((port.code, departure)),
    initialValue: departure ? _departureCoordinates : _arrivalCoordinates,
    decoration: InputDecoration(
      labelText: departure ? 'Departure coordinates' : 'Arrival coordinates',
      helperText:
          'Latitude and longitude in decimal degrees, separated by a space.',
      helperMaxLines: 2,
      hintText: '54.35 18.65',
    ),
    onChanged: (value) => setState(() {
      if (departure) {
        _departureCoordinates = value;
      } else {
        _arrivalCoordinates = value;
      }
      _result = null;
      _routeError = null;
    }),
  );

  @override
  Widget build(BuildContext context) {
    PaletteState.set(AppSection.bridge);
    return AppScaffold(
      title: 'Port Distance',
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
          final lat = _latitude.decimal;
          final lon = _longitude.decimal;
          final manualPosition = lat == null || lon == null
              ? null
              : (lat: lat, lon: lon);
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
                  if (_departure case final port?
                      when portPoint(port.coordinates) == null)
                    _coordinatesField(port, departure: true),
                  if (_arrival case final port?
                      when portPoint(port.coordinates) == null)
                    _coordinatesField(port, departure: false),
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
                  const SizedBox(height: 8),
                  PopupMenuButton<_PositionSource>(
                    enabled: !_locating,
                    onSelected: _choosePositionSource,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _PositionSource.gps,
                        child: Text('Use GPS'),
                      ),
                      PopupMenuItem(
                        value: _PositionSource.manual,
                        child: Text('Enter position manually'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _myPosition == null
                                ? Icons.my_location
                                : Icons.gps_fixed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _locating
                                ? 'Locating…'
                                : _myPosition == null
                                ? 'Show my position'
                                : 'Update my position',
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  if (_editingPosition) ...[
                    const SizedBox(height: 8),
                    DmsCoordinateFields(
                      label: 'Latitude',
                      coordinate: _latitude,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    DmsCoordinateFields(
                      label: 'Longitude',
                      coordinate: _longitude,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton(
                          onPressed: manualPosition == null
                              ? null
                              : () => _setManualPosition(manualPosition),
                          child: const Text('Set position'),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _editingPosition = false),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                  if (_myPosition case final point?) ...[
                    const SizedBox(height: 8),
                    Text('My position · ${formatPositionDms(point)}'),
                    if (result == null)
                      RouteMap(land: data.land, myPosition: point),
                  ],
                  if (_locationError case final locError?) ...[
                    const SizedBox(height: 8),
                    Text(
                      locError,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
                              myPosition: _myPosition,
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
