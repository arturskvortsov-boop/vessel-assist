import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/app_scaffold.dart';

const _stampColorKey = 'date_time_stamper_text_color';

enum _StampMode { date, time, both }

const _positions = [
  'Top left',
  'Top center',
  'Top right',
  'Middle left',
  'Center',
  'Middle right',
  'Bottom left',
  'Bottom center',
  'Bottom right',
];

const _colors = {
  'White': Colors.white,
  'Yellow': Color(0xFFFFD54F),
  'Red': Color(0xFFFF6B6B),
  'Blue': Color(0xFF64D8FF),
  'Black': Colors.black,
};

class DateTimeStamperScreen extends StatefulWidget {
  const DateTimeStamperScreen({super.key});

  @override
  State<DateTimeStamperScreen> createState() => _DateTimeStamperScreenState();
}

class _DateTimeStamperScreenState extends State<DateTimeStamperScreen> {
  final _picker = ImagePicker();
  final _photos = <XFile>[];
  final _dateFormat = DateFormat('dd.MM.yyyy');
  _StampMode _mode = _StampMode.date;
  DateTime? _date;
  TimeOfDay? _time;
  bool _busy = false;
  int _position = 8;
  Color _textColor = Colors.white;
  bool _bold = false;

  @override
  void initState() {
    super.initState();
    if (Hive.isBoxOpen('settings')) {
      final saved = Hive.box('settings').get(_stampColorKey);
      if (saved is int) _textColor = Color(saved);
    }
  }

  Future<void> _setTextColor(Color color) async {
    setState(() => _textColor = color);
    if (!Hive.isBoxOpen('settings')) return;
    try {
      await Hive.box('settings').put(_stampColorKey, color.toARGB32());
    } catch (_) {
      if (mounted) _notice('Could not remember the text color.');
    }
  }

  Future<void> _pickCustomColor() async {
    var hsv = HSVColor.fromColor(_textColor);
    final chosen = await showDialog<Color>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) {
          final color = hsv.toColor();
          final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
          final hex = (color.toARGB32() & 0xFFFFFF)
              .toRadixString(16)
              .padLeft(6, '0')
              .toUpperCase();
          return AlertDialog(
            title: const Text('Custom text color'),
            scrollable: true,
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 180,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Semantics(
                              label: 'Selected color #$hex',
                              child: ColoredBox(color: color),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                void select(Offset point) {
                                  final s = (point.dx / constraints.maxWidth)
                                      .clamp(0.0, 1.0);
                                  final v =
                                      1 -
                                      (point.dy / constraints.maxHeight).clamp(
                                        0.0,
                                        1.0,
                                      );
                                  update(() {
                                    hsv = hsv.withSaturation(s).withValue(v);
                                  });
                                }

                                return MouseRegion(
                                  cursor: SystemMouseCursors.precise,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapUp: (event) =>
                                        select(event.localPosition),
                                    onPanStart: (event) =>
                                        select(event.localPosition),
                                    onPanUpdate: (event) =>
                                        select(event.localPosition),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.white, hueColor],
                                            ),
                                          ),
                                        ),
                                        const DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black,
                                              ],
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment(
                                            hsv.saturation * 2 - 1,
                                            1 - hsv.value * 2,
                                          ),
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black54,
                                                  blurRadius: 3,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const Positioned(
                        left: 12,
                        right: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFF0000),
                                Color(0xFFFFFF00),
                                Color(0xFF00FF00),
                                Color(0xFF00FFFF),
                                Color(0xFF0000FF),
                                Color(0xFFFF00FF),
                                Color(0xFFFF0000),
                              ],
                            ),
                          ),
                          child: SizedBox(height: 8),
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          thumbColor: hueColor,
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                            elevation: 2,
                          ),
                        ),
                        child: Semantics(
                          label: 'Hue',
                          child: Slider(
                            value: hsv.hue,
                            max: 360,
                            onChanged: (hue) =>
                                update(() => hsv = hsv.withHue(hue)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Center(child: Text('#$hex')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, color),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
    if (chosen != null && mounted) await _setTextColor(chosen);
  }

  bool get _hasGallery =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String? get _stamp {
    final date = _date;
    final time = _time;
    if ((_mode != _StampMode.time && date == null) ||
        (_mode != _StampMode.date && time == null)) {
      return null;
    }
    return [
      if (_mode != _StampMode.time) _dateFormat.format(date!),
      if (_mode != _StampMode.date) _formatTime(time!),
    ].join(' ');
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  void _notice(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addPhotos({required bool fromFiles}) async {
    setState(() => _busy = true);
    try {
      final List<XFile> photos;
      if (fromFiles) {
        final selection = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          withData: kIsWeb,
        );
        photos = selection?.xFiles ?? [];
      } else {
        photos = await _picker.pickMultiImage(requestFullMetadata: false);
      }
      if (mounted) setState(() => _photos.addAll(photos));
    } catch (_) {
      if (mounted) _notice('Could not open photos.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time != null && mounted) setState(() => _time = time);
  }

  Future<void> _export({required bool gallery}) async {
    final stamp = _stamp;
    if (_busy || stamp == null || _photos.isEmpty) return;
    setState(() => _busy = true);
    final position = _position;
    final color = _textColor.toARGB32();
    final bold = _bold;
    var saved = 0;
    var failed = 0;
    try {
      if (gallery && !await Gal.hasAccess() && !await Gal.requestAccess()) {
        if (mounted) _notice('Allow photo access to save to the gallery.');
        return;
      }
      final copies = <({String name, Uint8List bytes})>[];
      final batch = DateTime.now().millisecondsSinceEpoch;
      for (final (index, photo) in _photos.indexed) {
        if (!mounted) return;
        try {
          final bytes = await _stampFile(photo, stamp, position, color, bold);
          if (!mounted) return;
          if (bytes == null) {
            failed++;
            continue;
          }
          final name = 'Stamped_${batch}_${index + 1}';
          if (gallery) {
            await Gal.putImageBytes(bytes, name: name);
            saved++;
          } else {
            copies.add((name: name, bytes: bytes));
          }
        } catch (_) {
          failed++;
        }
      }
      if (!mounted) return;
      if (!gallery && copies.isNotEmpty) {
        final single = copies.length == 1;
        final bytes = single
            ? copies.single.bytes
            : await compute(_zipPhotos, copies);
        if (!mounted) return;
        final path = await FilePicker.platform.saveFile(
          fileName: single
              ? '${copies.single.name}.jpg'
              : 'Stamped_photos_$batch.zip',
          type: FileType.custom,
          allowedExtensions: [single ? 'jpg' : 'zip'],
          bytes: bytes,
        );
        if (path == null && !kIsWeb) return;
        saved = copies.length;
      }
      if (!mounted) return;
      _notice(
        saved == 0
            ? 'No photos were saved. Try JPG or PNG files.'
            : '$saved photo(s) exported.${failed > 0 ? ' $failed could not be processed or saved.' : ''}',
      );
    } catch (_) {
      if (mounted) _notice('Could not export photos.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _stampPosition(String? stamp) {
    final theme = Theme.of(context);
    final sample =
        stamp ??
        switch (_mode) {
          _StampMode.date => '12.11.2026',
          _StampMode.time => '14:30',
          _StampMode.both => '12.11.2026 14:30',
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stamp position'),
        const Text('Tap a cell to move the stamp'),
        const SizedBox(height: 8),
        SizedBox(
          width: 340,
          height: 126,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  for (var row = 0; row < 3; row++)
                    Expanded(
                      child: Row(
                        children: [
                          for (var column = 0; column < 3; column++)
                            Expanded(
                              child: Semantics(
                                selected: _position == row * 3 + column,
                                child: Tooltip(
                                  message: _positions[row * 3 + column],
                                  child: InkWell(
                                    onTap: _busy
                                        ? null
                                        : () => setState(
                                            () => _position = row * 3 + column,
                                          ),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: _position == row * 3 + column
                                            ? theme.colorScheme.primary
                                                  .withValues(alpha: 0.15)
                                            : theme.colorScheme.surface,
                                        border: Border.all(
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Align(
                    alignment: Alignment(
                      (_position % 3 - 1).toDouble(),
                      (_position ~/ 3 - 1).toDouble(),
                    ),
                    child: Text(
                      sample,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 11,
                        fontWeight: _bold ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stamp = _stamp;
    final canExport = !_busy && _photos.isNotEmpty && stamp != null;
        return AppScaffold(
      title: 'Date & Time Stamper',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _addPhotos(fromFiles: false),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Add from gallery'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _addPhotos(fromFiles: true),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Add from files'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedButton<_StampMode>(
                segments: const [
                  ButtonSegment(value: _StampMode.date, label: Text('Date')),
                  ButtonSegment(value: _StampMode.time, label: Text('Time')),
                  ButtonSegment(
                    value: _StampMode.both,
                    label: Text('Date & time'),
                  ),
                ],
                selected: {_mode},
                showSelectedIcon: false,
                onSelectionChanged: _busy
                    ? null
                    : (value) => setState(() => _mode = value.single),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_mode != _StampMode.time) ...[
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pickDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        _date == null
                            ? 'Select date'
                            : _dateFormat.format(_date!),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _date = DateTime.now()),
                      child: const Text('Today'),
                    ),
                  ],
                  if (_mode != _StampMode.date)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pickTime,
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        _time == null ? 'Select time' : _formatTime(_time!),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _stampPosition(stamp),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  avatar: const Icon(Icons.format_bold),
                  label: const Text('Bold'),
                  selected: _bold,
                  onSelected: _busy
                      ? null
                      : (value) => setState(() => _bold = value),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Text color'),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in _colors.entries)
                    ChoiceChip(
                      label: Text(option.key),
                      avatar: CircleAvatar(
                        backgroundColor: option.value,
                        radius: 8,
                      ),
                      selected: _textColor == option.value,
                      onSelected: _busy
                          ? null
                          : (_) => _setTextColor(option.value),
                    ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pickCustomColor,
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('Custom color'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_busy) const LinearProgressIndicator(),
              for (final photo in _photos)
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: Text(
                    photo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove photo',
                    onPressed: _busy
                        ? null
                        : () => setState(() => _photos.remove(photo)),
                    icon: const Icon(Icons.close),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: canExport ? () => _export(gallery: false) : null,
                icon: const Icon(Icons.download_outlined),
                label: Text(
                  _photos.length > 1 ? 'Save ZIP to files' : 'Save to files',
                ),
              ),
              if (_hasGallery)
                OutlinedButton.icon(
                  onPressed: canExport ? () => _export(gallery: true) : null,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Save to gallery'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Uint8List?> _stampFile(
  XFile photo,
  String stamp,
  int position,
  int color,
  bool bold,
) async {
  final input = await photo.readAsBytes();
  final stamped = await compute(stampPhoto, (
    bytes: input,
    stamp: stamp,
    position: position,
    color: color,
    bold: bold,
  ));
  if (stamped != null) return stamped;

  // Try the platform decoder for formats the Dart image library cannot read.
  final codec = await ui.instantiateImageCodec(input);
  try {
    final frame = await codec.getNextFrame();
    try {
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return null;
      return await compute(stampPhoto, (
        bytes: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        stamp: stamp,
        position: position,
        color: color,
        bold: bold,
      ));
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

Uint8List? stampPhoto(
  ({Uint8List bytes, String stamp, int position, int color, bool bold}) input,
) {
  final decoded = img.decodeImage(input.bytes);
  if (decoded == null) return null;
  final photo = img
      .bakeOrientation(decoded)
      .convert(format: img.Format.uint8, numChannels: 3);
  final font = img.arial48;
  final width = input.stamp.codeUnits.fold<int>(
    0,
    (sum, code) => sum + (font.characters[code]?.xAdvance ?? 0),
  );
  final weight = input.bold ? 3 : 0;
  final label = img.Image(
    width: width + 32 + weight,
    height: font.lineHeight + 32,
  );
  for (var offset = 0; offset <= weight; offset++) {
    img.drawString(
      label,
      input.stamp,
      font: font,
      x: 16 + offset,
      y: 16,
      color: img.ColorRgb8(255, 255, 255),
    );
  }
  final shortSide = math.min(photo.width, photo.height);
  final margin = (shortSide * 0.025).floor();
  final scale = math.min(
    (photo.width - 2 * margin) / label.width,
    shortSide * 0.065 / label.height,
  );
  final resized = img.copyResize(
    label,
    width: math.max(1, (label.width * scale).floor()),
    height: math.max(1, (label.height * scale).floor()),
    interpolation: img.Interpolation.linear,
  );
  // Treat the resized glyphs as a coverage mask so the photo shows through.
  final overlay = img.Image(
    width: resized.width,
    height: resized.height,
    numChannels: 4,
  );
  final red = (input.color >> 16) & 255;
  final green = (input.color >> 8) & 255;
  final blue = input.color & 255;
  for (final pixel in resized) {
    if (pixel.r != 0) {
      overlay.setPixelRgba(pixel.x, pixel.y, red, green, blue, pixel.r);
    }
  }
  img.compositeImage(
    photo,
    overlay,
    dstX:
        margin +
        ((photo.width - resized.width - 2 * margin) *
            (input.position % 3) ~/
            2),
    dstY:
        margin +
        ((photo.height - resized.height - 2 * margin) *
            (input.position ~/ 3) ~/
            2),
  );
  return img.encodeJpg(photo, quality: 95);
}

Uint8List _zipPhotos(List<({String name, Uint8List bytes})> photos) {
  final archive = Archive();
  for (final photo in photos) {
    archive.addFile(
      ArchiveFile('${photo.name}.jpg', photo.bytes.length, photo.bytes),
    );
  }
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}
