
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/app_scaffold.dart';

class PhotoCompressScreen extends StatefulWidget {
  const PhotoCompressScreen({super.key});

  @override
  State<PhotoCompressScreen> createState() => _PhotoCompressScreenState();
}

class _PhotoCompressScreenState extends State<PhotoCompressScreen> {
  List<XFile> _photos = [];
  int _maxSide = 1500;
  int _quality = 80;
  bool _busy = false;

  void _notice(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPhotos() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: kIsWeb,
      );
      if (mounted && result != null) setState(() => _photos = result.xFiles);
    } catch (_) {
      if (mounted) _notice('Could not open photos.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    final maxSide = _maxSide;
    final quality = _quality;
    final copies = <({String name, Uint8List bytes})>[];
    var failed = 0;
    try {
      for (final (index, photo) in _photos.indexed) {
        try {
          final bytes = await _compressFile(photo, maxSide, quality);
          final stem = photo.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
          final safeStem = stem.replaceAll(
            RegExp(r'[<>:"/\\|?*\x00-\x1f]'),
            '_',
          );
          copies.add((
            name: 'Compressed_${index + 1}_$safeStem.jpg',
            bytes: bytes,
          ));
        } catch (_) {
          failed++;
        }
        if (!mounted) return;
      }
      if (copies.isEmpty) {
        _notice('Could not compress the selected photos.');
        return;
      }

      final single = copies.length == 1;
      final bytes = single
          ? copies.single.bytes
          : await compute(_zipPhotos, copies);
      if (!mounted) return;
      final path = await FilePicker.platform.saveFile(
        fileName: single ? copies.single.name : 'Compressed_photos.zip',
        type: FileType.custom,
        allowedExtensions: [single ? 'jpg' : 'zip'],
        bytes: bytes,
      );
      if (!mounted || (path == null && !kIsWeb)) return;
      _notice(
        '${copies.length} photo(s) exported.'
        '${failed == 0 ? '' : ' $failed could not be processed.'}',
      );
    } catch (_) {
      if (mounted) _notice('Could not export photos.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
        return AppScaffold(
      title: 'Compress Photos',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickPhotos,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Select photos'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _maxSide,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Maximum long edge',
                ),
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('Original dimensions'),
                  ),
                  for (final size in [800, 1024, 1500, 1920, 2560])
                    DropdownMenuItem(value: size, child: Text('$size px')),
                ],
                onChanged: _busy
                    ? null
                    : (size) {
                        if (size != null) setState(() => _maxSide = size);
                      },
              ),
              const SizedBox(height: 16),
              Text('JPEG quality: $_quality%'),
              Slider(
                value: _quality.toDouble(),
                min: 10,
                max: 100,
                divisions: 90,
                label: '$_quality%',
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _quality = value.round()),
              ),
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
                onPressed: _busy || _photos.isEmpty ? null : _export,
                icon: const Icon(Icons.download_outlined),
                label: Text(_photos.length > 1 ? 'Save as ZIP' : 'Save JPEG'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Uint8List> _compressFile(XFile photo, int maxSide, int quality) async {
  final bytes = await photo.readAsBytes();
  final compressed = await compute(compressPhoto, (
    bytes: bytes,
    maxSide: maxSide,
    quality: quality,
  ));
  if (compressed != null) return compressed;

  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    try {
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (png != null) {
        final result = await compute(compressPhoto, (
          bytes: png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
          maxSide: maxSide,
          quality: quality,
        ));
        if (result != null) return result;
      }
      throw const FormatException('Could not decode photo');
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

Uint8List? compressPhoto(({Uint8List bytes, int maxSide, int quality}) input) {
  final decoded = img.decodeImage(input.bytes);
  if (decoded == null) return null;

  var photo = img.bakeOrientation(decoded);
  final longEdge = math.max(photo.width, photo.height);
  if (input.maxSide > 0 && longEdge > input.maxSide) {
    final scale = input.maxSide / longEdge;
    photo = img.copyResize(
      photo,
      width: math.max(1, (photo.width * scale).round()),
      height: math.max(1, (photo.height * scale).round()),
      interpolation: img.Interpolation.average,
    );
  }
  return img.encodeJpg(photo, quality: input.quality);
}

Uint8List _zipPhotos(List<({String name, Uint8List bytes})> photos) {
  final archive = Archive();
  for (final photo in photos) {
    archive.addFile(ArchiveFile(photo.name, photo.bytes.length, photo.bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}
