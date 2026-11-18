import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../core/palette_state.dart';

class PdfCompressScreen extends StatefulWidget {
  const PdfCompressScreen({super.key});

  @override
  State<PdfCompressScreen> createState() => _PdfCompressScreenState();
}

class _PdfCompressScreenState extends State<PdfCompressScreen> {
  bool _busy = false;
  int _pages = 0;
  Uint8List? _result;
  int _originalSize = 0;
  String _name = '';
  String? _error;

  Future<void> _compress() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final selected = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (selected == null || !mounted) return;
      final file = selected.files.single;
      final path = file.path;
      if (path == null) throw const FormatException('Could not read this PDF.');
      final bytes = await File(path).readAsBytes();
      final capabilities = await Printing.info();
      if (!capabilities.canRaster) {
        throw const FormatException(
          'PDF processing is unavailable on this device.',
        );
      }
      if (!mounted) return;
      setState(() {
        _result = null;
        _pages = 0;
      });
      final document = pw.Document(compress: true);
      const dpi = 120.0;
      await for (final page in Printing.raster(bytes, dpi: dpi)) {
        if (!mounted) return;
        final jpeg = await compute(_encodePage, await page.toPng());
        final picture = pw.MemoryImage(jpeg);
        document.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              page.width * 72 / dpi,
              page.height * 72 / dpi,
              marginAll: 0,
            ),
            build: (_) => pw.Image(picture, fit: pw.BoxFit.fill),
          ),
        );
        setState(() => _pages++);
      }
      if (_pages == 0) {
        throw const FormatException('This PDF contains no readable pages.');
      }
      final output = await document.save();
      if (!mounted) return;
      final smaller = output.length < bytes.length;
      setState(() {
        _name = file.name.replaceFirst(
          RegExp(r'\.pdf$', caseSensitive: false),
          '',
        );
        _originalSize = bytes.length;
        _result = smaller ? output : bytes;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is FormatException ? error.message : 'Could not process this PDF. Check that it is readable and not password-protected.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final bytes = _result;
    if (_busy || bytes == null) return;
    setState(() => _busy = true);
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: '${_name}_compressed.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );
      if (path != null &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        await File(path).writeAsBytes(bytes, flush: true);
      }
      if (path != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('PDF saved.')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save the PDF. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _size(int bytes) => '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Compress PDF',
    section: AppSection.admin,
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Compress a PDF on this device and save a copy. Best suited to scanned documents.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Pages are converted to images. Selectable text, links, forms and digital signatures are flattened.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _compress,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Select PDF and compress'),
        ),
        if (_busy) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          if (_pages > 0) Text('Pages processed: $_pages'),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_result case final bytes?) ...[
          const SizedBox(height: 16),
          Text('$_name.pdf'),
          Text('Original: ${_size(_originalSize)}'),
          Text('Result: ${_size(bytes.length)}'),
          Text(
            bytes.length < _originalSize
                ? 'Size reduced by ${((1 - bytes.length / _originalSize) * 100).toStringAsFixed(1)}%.'
                : 'This PDF could not be made smaller. The original copy is ready to save.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save_alt),
            label: const Text('Save PDF'),
          ),
        ],
      ],
    ),
  );
}

Uint8List _encodePage(Uint8List png) {
  final decoded = image.decodePng(png);
  if (decoded == null) {
    throw const FormatException('Could not decode a PDF page.');
  }
  return Uint8List.fromList(image.encodeJpg(decoded, quality: 75));
}
