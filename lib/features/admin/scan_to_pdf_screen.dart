import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/widgets/app_scaffold.dart';
import 'scan_camera_stub.dart'
    if (dart.library.js_interop) 'scan_camera_web.dart';

class ScanToPdfScreen extends StatefulWidget {
  const ScanToPdfScreen({super.key});

  @override
  State<ScanToPdfScreen> createState() => _ScanToPdfScreenState();
}

class _ScanToPdfScreenState extends State<ScanToPdfScreen> {
  final _picker = ImagePicker();
  final _pages = <_ScanPage>[];
  bool _busy = false;

  bool get _supportsCamera =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  void _notice(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addPages({required bool camera}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final List<XFile> files;
      if (camera) {
        final photo = kIsWeb
            ? await takeBrowserPhoto(context)
            : await _picker.pickImage(
                source: ImageSource.camera,
                maxWidth: 2400,
                maxHeight: 2400,
                requestFullMetadata: false,
              );
        files = [?photo];
      } else {
        files = await _picker.pickMultiImage(
          maxWidth: 2400,
          maxHeight: 2400,
          requestFullMetadata: false,
        );
      }

      final pages = <_ScanPage>[];
      var unreadable = 0;
      for (final file in files) {
        if (!mounted) return;
        try {
          final bytes = await compute(_prepareImage, await file.readAsBytes());
          if (bytes == null) {
            unreadable++;
          } else {
            pages.add(_ScanPage(file.name, bytes));
          }
        } catch (_) {
          unreadable++;
        }
      }
      if (!mounted) return;
      setState(() => _pages.addAll(pages));
      if (unreadable > 0) {
        _notice('Could not read $unreadable image(s). Try JPG or PNG.');
      }
    } catch (_) {
      if (mounted) {
        _notice(
          camera ? 'Could not open the camera.' : 'Could not open photos.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _pages.isEmpty) return;
    setState(() => _busy = true);
    try {
      final bytes = await compute(
        _makePdf,
        _pages.map((page) => page.bytes).toList(),
      );
      if (!mounted) return;
      final timestamp = DateTime.now()
          .toIso8601String()
          .substring(0, 19)
          .replaceAll(':', '-');
      final path = await FileSaver.instance.saveFile(
        name: 'Scan_$timestamp',
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (mounted) {
        _notice(kIsWeb ? 'PDF download started.' : 'PDF saved to $path');
      }
    } catch (_) {
      if (mounted) _notice('Could not save the PDF.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
        return AppScaffold(
      title: 'Scan to PDF',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_supportsCamera)
                      OutlinedButton.icon(
                        onPressed: _busy ? null : () => _addPages(camera: true),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Take photo'),
                      ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _addPages(camera: false),
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Add photos'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_busy) const LinearProgressIndicator(),
                Expanded(
                  child: _pages.isEmpty
                      ? const Center(
                          child: Text('Add photos to create PDF pages.'),
                        )
                      : ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: _pages.length,
                          onReorderItem: (oldIndex, newIndex) {
                            if (_busy) return;
                            setState(() {
                              final page = _pages.removeAt(oldIndex);
                              _pages.insert(newIndex, page);
                            });
                          },
                          itemBuilder: (context, index) {
                            final page = _pages[index];
                            return ListTile(
                              key: ObjectKey(page),
                              leading: Image.memory(
                                page.bytes,
                                width: 52,
                                height: 52,
                                cacheWidth: 104,
                                fit: BoxFit.contain,
                              ),
                              title: Text('Page ${index + 1}'),
                              subtitle: Text(
                                page.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Remove page',
                                    onPressed: _busy
                                        ? null
                                        : () => setState(
                                            () => _pages.remove(page),
                                          ),
                                    icon: const Icon(Icons.close),
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    enabled: !_busy,
                                    child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.drag_handle,
                                        semanticLabel: 'Reorder page',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                FilledButton.icon(
                  onPressed: _busy || _pages.isEmpty ? null : _save,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Save PDF'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanPage {
  const _ScanPage(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

Uint8List? _prepareImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  var image = img.bakeOrientation(decoded);
  if (image.width > 2400 || image.height > 2400) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: 2400,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: 2400,
            interpolation: img.Interpolation.average,
          );
  }
  if (image.hasAlpha) {
    final background = img.Image(width: image.width, height: image.height);
    img.fill(background, color: img.ColorRgb8(255, 255, 255));
    image = img.compositeImage(background, image);
  }
  return img.encodeJpg(image, quality: 90);
}

Future<Uint8List> _makePdf(List<Uint8List> images) async {
  final pdf = pw.Document();
  for (final bytes in images) {
    final image = pw.MemoryImage(bytes);
    final format = image.width! > image.height!
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(12),
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );
  }
  return pdf.save();
}
