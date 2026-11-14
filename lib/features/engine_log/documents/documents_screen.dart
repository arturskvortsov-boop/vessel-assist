import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme.dart';
import '../../../core/palette_state.dart';
import '../../../core/widgets/app_scaffold.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    if (kIsWeb) {
      setState(() {
        _isLoading = false;
        _files = [];
      });
      return;
    }

    setState(() => _isLoading = true);
    final dir = await getApplicationDocumentsDirectory();
    final customDir = Directory('${dir.path}/manuals_and_certs');
    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }
    final files = await customDir.list().toList();
    setState(() {
      _files = files;
      _isLoading = false;
    });
  }

  Future<Directory> _getDocsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final customDir = Directory('${dir.path}/manuals_and_certs');
    if (!await customDir.exists()) await customDir.create(recursive: true);
    return customDir;
  }

  Future<void> _pickPdf() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage is only available on mobile devices (Android/iOS).')));
      return;
    }
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final dir = await _getDocsDir();
      final fileName = result.files.single.name;
      await file.copy('${dir.path}/$fileName');
      _loadFiles();
    }
  }

  Future<void> _scanDocument() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera and storage are only available on mobile devices.')));
      return;
    }
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    
    if (image != null) {
      // Конвертируем фото в PDF
      final pdf = pw.Document();
      final imageBytes = await image.readAsBytes();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      final dir = await _getDocsDir();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfPath = '${dir.path}/Scan_$timestamp.pdf';
      final file = File(pdfPath);
      await file.writeAsBytes(await pdf.save());

      _loadFiles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document scanned and saved as PDF!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
        PaletteState.set(AppSection.admin);
        return AppScaffold(
            title: 'Document Storage',
      section: AppSection.admin,
      background: AppBackground.neutral,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickPdf,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('UPLOAD'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50), backgroundColor: border, foregroundColor: text),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scanDocument,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('SCAN'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50), backgroundColor: accent, foregroundColor: bg),
                  ),
                ),
              ],
            ),
          ),
          _isLoading 
            ? Center(child: CircularProgressIndicator(color: accent))
            : Expanded(
                child: _files.isEmpty
                    ? const Center(child: Text('No documents stored yet.', style: TextStyle(color: textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          final fileName = file.path.split(Platform.pathSeparator).last;
                          final isPdf = fileName.toLowerCase().endsWith('.pdf');

                          return Card(
                            color: cardSolid,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                isPdf ? Icons.picture_as_pdf : Icons.image,
                                color: isPdf ? Colors.redAccent : accent,
                              ),
                              title: Text(fileName, style: const TextStyle(color: text, fontSize: 14)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.grey),
                                    onPressed: () async {
                                      await file.delete();
                                      _loadFiles();
                                    },
                                  ),
                                  Icon(Icons.chevron_right, color: accent),
                                ],
                              ),
                              onTap: () => OpenFilex.open(file.path),
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
