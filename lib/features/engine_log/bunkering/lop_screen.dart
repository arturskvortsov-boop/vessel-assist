import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import '../../../core/theme.dart';
import '../../../core/widgets/signature_pad.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LopScreen extends StatefulWidget {
  const LopScreen({super.key});

  @override
  State<LopScreen> createState() => _LopScreenState();
}

class _LopScreenState extends State<LopScreen> {
  String _selectedType = 'Shortage';
  
  // Три отдельные подписи
  Uint8List? _masterSig;
  Uint8List? _chiefSig;
  Uint8List? _ackSig;

  // Общие контроллеры
  final _vesselCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _bargeCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
  final _qtyVlsfoCtrl = TextEditingController();
  final _qtyLsmgoCtrl = TextEditingController();
  
  // Специфичные контроллеры
  final _sealNosCtrl = TextEditingController();
  final _missingQtyCtrl = TextEditingController();
  final _charterersCtrl = TextEditingController();

  String _generatedText = '';

  final Map<String, String> _lopTypes = {
    'Shortage': '5a - Short delivery of bunkers',
    'BDN_Annex_VI': '5b - BDN non-compliance with Annex VI',
    'Seal_Numbers': '5c - Seal numbers not recorded in BDN',
    'Samples_Manifold': '5d - Samples not taken from ship manifold',
    'Sampling_Witness': '5e - Supplier not witnessed commercial sampling',
    'Barge_Coop': '5f - Bunker barge co-operation issue',
    'No_MSDS': '5g - MSDS not provided',
    'No_Lien_Stamp': '5h - Refusal to accept "No Lien Stamp"',
    'MARPOL_Violation': '5i - Supplier MARPOL violation (Sample)',
  };

  void _generateText() {
    final v = (TextEditingController c) => c.text;
    final date = v(_dateCtrl);
    final vessel = v(_vesselCtrl);
    final port = v(_portCtrl);
    final barge = v(_bargeCtrl);
    final supplier = v(_supplierCtrl);
    final qtyV = v(_qtyVlsfoCtrl);
    final qtyM = v(_qtyLsmgoCtrl);

    String header = 'To: Messrs. $supplier\n'
        'Vessel: $vessel\n'
        'Lying at: $port\n'
        'Barge: $barge\n'
        'Date: $date\n'
        'Bunkers Rcvd: $qtyV MT VLSFO + $qtyM MT LSMGO\n\n';

    String body = '';

    switch (_selectedType) {
      case 'Shortage':
        body = 'You are hereby advised that upon completion of bunkering the following grades /quantities of fuel were said to be supplied to the vessel:\n'
            '$qtyV Metric tons of VLSFO\n$qtyM Metric tons of LSMGO\n\n'
            'However, after careful measurement of the ships fuel tanks in still conditions, the total quantity of fuel supplied to the vessel was found to be:\n'
            '${v(_missingQtyCtrl)} Metric tons (actual received).\n\n'
            'I therefore place you on notice and hold you fully responsible for this short delivered quantity and request that you supply a further quantity, failing which I strongly protest and reserve my Owner\'s/Charterer\'s right to claim any difference between the quantity declared on the bunker receipt and quantity determined by accurate onboard measurements.\n\n'
            'Without prejudice\n\nMaster / Chief Engineer';
        break;
      case 'BDN_Annex_VI':
        body = 'You are hereby placed on notice and advised that the bunker delivery note (BDN) presented to me is incomplete and not compliant with MARPOL 73/78 Annex VI (Regulation 18 and / or 14.4).\n\n'
            'On behalf of my Owners, I formally protest and request that you provide a new bunker delivery note containing the correct information, failing which I reserve my Owners\' rights and hold you fully responsible and liable for any loss, delay, fines, costs and/or consequences arising or resulting from your refusal to provide documentation in accordance with MARPOL Annex VI.\n\n'
            'Without prejudice\n\nMaster / Chief Engineer';
        break;
      case 'Seal_Numbers':
        body = 'Sealed fuel samples were collected at the ships manifold by an approved method in accordance with international standards however supplier refused to record vessel\'s seal numbers in the BDN and refused to counter seal them.\n\n'
            'The Vessel\'s seal numbers that were refused to be recorded in the BDN are the following:\n'
            '${v(_sealNosCtrl)}\n\n'
            'On behalf of my Owners, I formally protest against supplier\'s above practice and I reserve my Owners\' rights of recourse to your company at a future date and hold you fully responsible and liable for any loss, delay, fines costs and/or consequences arising or resulting from the above practice.\n\n'
            'Without prejudice\n\nMaster / Chief Engineer';
        break;
      case 'Samples_Manifold':
        body = 'By this letter I wish to put into record and to advise whoever may be concerned that the suppliers of the aforementioned product were invited to draw the MARPOL sample from the receiving ships manifold according to MEPC.182(59).\n\n'
            'However, and despite our multiple efforts to convince the master of the supply barge to comply with our request, he has drawn the MARPOL sample from his barge manifold.\n\n'
            'This letter serves as our official protest to the above- mentioned practice.\n\n'
            'Without prejudice\n\nMaster / Chief Engineer';
        break;
      case 'Sampling_Witness':
        body = 'By this letter I wish to put into record and to advise whoever may be concerned that the supplier of the aforementioned product was invited to witness the drawing of the commercial samples from the receiving ships manifold (i.e. my vessels manifold) according to MEPC.182(59).\n\n'
            'However, and despite our multiple efforts to convince the master of the supply barge to comply with our request, he did not accept to witness the drawing of the commercial samples from our ships manifold.\n\n'
            'This letter serves as our official protest to the above- mentioned practice.\n\n'
            'Without prejudice\n\nMaster / Chief Engineer';
        break;
      case 'Barge_Coop':
        body = 'By this letter I wish to put into record and to advise whoever may be concerned that:\n'
            '- Bunker barge did not allow ships personnel on board to take soundings.\n'
            '- Ship\'s personnel attended the barge in order to obtain tank soundings however the barge was equipped only with reading gauges and as such the barges tanks could not be measured.\n'
            '- Ship\'s personnel attended the barge in order to obtain tank soundings however the barge could not provide proper and / or approved sounding tables.\n\n'
            'This letter serves as our official protest to the above- mentioned practice (s).\n\n'
            'Without prejudice\n\nMaster / Chief Engineer';
        break;
      case 'No_MSDS':
        body = 'By this letter I wish to put into record and to advise whoever may be concerned that despite our constant requests, the supplier failed to provide the vessel with Material Safety Data Sheets (MSDS) for the product that was supplied on board in accordance with MARPOL and standard working practices.\n\n'
            'This letter serves as our official protest to the above- mentioned practice (s).\n\n'
            'Without prejudice\n\nMaster / Chief Engineer';
        break;
      case 'No_Lien_Stamp':
        body = 'By this letter I wish to put into record and to advise you that the bunkers of $qtyV MT of VLSFO delivered on board my vessel $vessel on $date by bunker barge $barge, are being accepted for the account of the vessels Charterers ${v(_charterersCtrl)} and NOT for the account of the vessel or her Owners. Accordingly, no lien or other claim against said ship can arise therefrom.\n\n'
            'Without prejudice\n\nMaster / Chief Engineer';
        break;
      case 'MARPOL_Violation':
        body = 'According to MARPOL explicit provisions, the fuel supplier has the absolute responsibility to provide the vessel with a compliant statutory MARPOL sample and label.\n\n'
            'By this letter I wish to put into record and to advise whoever may be concerned that contrary to the MARPOL regulations:\n'
            'The supplier did not provide a MARPOL sample OR did not allow us to witness the sampling procedure. As such, the provided sample is of unknown source, and it is not considered to be final, binding and truly representative of the fuel as loaded.\n\n'
            'This letter serves as our official protest to the above- mentioned practice (s).\n\n'
            'Without prejudice\n\nMaster / Chief Engineer';
        break;
    }

    setState(() {
      _generatedText = header + body;
    });
  }

  Future<void> _exportPdf() async {
    if (_generatedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generate the text first!')));
      return;
    }

    final font = await PdfGoogleFonts.notoSerifRegular();
    final boldFont = await PdfGoogleFonts.notoSerifBold();
    final italicFont = await PdfGoogleFonts.notoSerifItalic();

    final pdf = pw.Document();

    // Функция для получения правильного названия формы
    String formTitle = '';
    String formNo = '';
    switch (_selectedType) {
      case 'Shortage': formTitle = '"Short Delivery of Bunkers"'; formNo = '5a'; break;
      case 'BDN_Annex_VI': formTitle = '"BDN Non-compliance with Annex VI"'; formNo = '5b'; break;
      case 'Seal_Numbers': formTitle = '"Seal Numbers Not Recorded in BDN"'; formNo = '5c'; break;
      case 'Samples_Manifold': formTitle = '"Samples Not Taken from Ship Manifold"'; formNo = '5d'; break;
      case 'Sampling_Witness': formTitle = '"Supplier Not Witnessed Sampling"'; formNo = '5e'; break;
      case 'Barge_Coop': formTitle = '"Bunker Barge Co-operation Issue"'; formNo = '5f'; break;
      case 'No_MSDS': formTitle = '"MSDS Not Provided"'; formNo = '5g'; break;
      case 'No_Lien_Stamp': formTitle = '"Refusal to Accept No Lien Stamp"'; formNo = '5h'; break;
      case 'MARPOL_Violation': formTitle = '"Supplier MARPOL Violation"'; formNo = '5i'; break;
    }

    pw.Widget buildDottedLine(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(label, style: pw.TextStyle(font: font, fontSize: 12)),
            pw.SizedBox(width: 5),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 2),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, style: pw.BorderStyle.dotted, width: 1)),
                ),
                child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 12)),
              ),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // --- НЕЙТРАЛЬНАЯ ШАПКА ШАБЛОНА ---
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('LETTER OF PROTEST', style: pw.TextStyle(font: boldFont, fontSize: 16, letterSpacing: 1.5)),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    formTitle, 
                    style: pw.TextStyle(
                      font: boldFont, 
                      fontSize: 12, 
                      decoration: pw.TextDecoration.underline
                    )
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text('Form Ref: F.BUNK.$formNo', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
            ),
            
            pw.SizedBox(height: 10),
            pw.Text('Form to be completed when required', style: pw.TextStyle(font: italicFont, fontSize: 10)),
            pw.SizedBox(height: 30),

            // --- ПОЛЯ ДЛЯ ЗАПОЛНЕНИЯ ---
            buildDottedLine('To:', ' ${_supplierCtrl.text}'),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 30, bottom: 4),
              child: pw.Text('(Name of Supplier)', style: pw.TextStyle(font: italicFont, fontSize: 10)),
            ),
            buildDottedLine('MV', ' ${_vesselCtrl.text}'),
            buildDottedLine('Bunker barge', ' ${_bargeCtrl.text}'),
            buildDottedLine('Port', ' ${_portCtrl.text}'),
            buildDottedLine('Date/Time', ' ${_dateCtrl.text}'),

            pw.SizedBox(height: 20),

            // --- ТЕЛО ПИСЬМА ---
            pw.Text(
              'You are hereby advised that upon completion of bunkering the following grades /quantities of fuel were said to be supplied to the vessel:',
              style: pw.TextStyle(font: font, fontSize: 12, lineSpacing: 1.5),
            ),
            pw.SizedBox(height: 15),
            
            buildDottedLine('', ' ${_qtyVlsfoCtrl.text} Metric tons of VLSFO (insert ISO grade) cst'),
            buildDottedLine('', ' ${_qtyLsmgoCtrl.text} Metric tons of LSMGO (insert ISO grade)'),

            pw.SizedBox(height: 15),
            pw.Text(
              'However, after careful measurement of the ships fuel tanks in still conditions, the total quantity of fuel supplied to the vessel was found to be:',
              style: pw.TextStyle(font: font, fontSize: 12, lineSpacing: 1.5),
            ),
            pw.SizedBox(height: 15),

            if (_selectedType == 'Shortage') ...[
              buildDottedLine('', ' ${_missingQtyCtrl.text} Metric tons of VLSFO (insert ISO grade) cst'),
              pw.SizedBox(height: 15),
              pw.Text(
                'I therefore place you on notice and hold you fully responsible for this short delivered quantity and request that you supply a further quantity of (insert quantity/grade), failing which I strongly protest and reserve my Owner\'s/Charterer\'s right to claim any difference between the quantity declared on the bunker receipt and quantity determined by accurate onboard measurements.',
                style: pw.TextStyle(font: font, fontSize: 12, lineSpacing: 1.5),
              ),
            ] else ...[
               pw.Text(
                _generatedText.split('\n\n').sublist(1).join('\n\n').split('Without prejudice').first.trim(),
                style: pw.TextStyle(font: font, fontSize: 12, lineSpacing: 1.5),
              ),
            ],

            pw.SizedBox(height: 40),

            // --- ПОДПИСИ ---
            pw.Text('Without prejudice', style: pw.TextStyle(font: italicFont, fontSize: 12)),
            pw.SizedBox(height: 20),
            
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (_masterSig != null)
                      pw.Image(pw.MemoryImage(_masterSig!), height: 50)
                    else
                      pw.SizedBox(height: 50),
                    pw.Container(width: 150, child: pw.Divider(color: PdfColors.black)),
                    pw.Text('Master', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                  ]
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (_chiefSig != null)
                      pw.Image(pw.MemoryImage(_chiefSig!), height: 50)
                    else
                      pw.SizedBox(height: 50),
                    pw.Container(width: 150, child: pw.Divider(color: PdfColors.black)),
                    pw.Text('Chief Engineer', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                  ]
                ),
              ]
            ),

            pw.SizedBox(height: 30),

            pw.Text('Acknowledged by (Name of person)', style: pw.TextStyle(font: boldFont, fontSize: 10)),
            pw.SizedBox(height: 5),
            if (_ackSig != null)
              pw.Image(pw.MemoryImage(_ackSig!), height: 50)
            else
              pw.SizedBox(height: 50),
            pw.Container(width: double.infinity, child: pw.Divider(color: PdfColors.black)),
            
            pw.SizedBox(height: 15),
            
            pw.Text('On behalf of (Name of company)', style: pw.TextStyle(font: boldFont, fontSize: 10)),
            pw.SizedBox(height: 20),
            pw.Container(width: double.infinity, child: pw.Divider(color: PdfColors.black)),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Letter of Protest'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
          bottom: const TabBar(
            indicatorColor: accent,
            labelColor: accent,
            unselectedLabelColor: textMuted,
            tabs: [Tab(text: 'TEMPLATES'), Tab(text: 'MY FORMS')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTemplateTab(),
            _buildMyFormsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateTab() {
    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _selectedType,
            dropdownColor: cardSolid,
            decoration: const InputDecoration(labelText: 'Protest Reason'),
            items: _lopTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedType = val!;
                _generatedText = ''; 
              });
            },
          ),
          const SizedBox(height: 16),
          
          _buildField('Vessel Name', _vesselCtrl),
          _buildField('Port', _portCtrl),
          _buildField('Bunker Barge Name', _bargeCtrl),
          _buildField('Supplier Name', _supplierCtrl),
          
          Row(
            children: [
              Expanded(child: _buildField('Qty VLSFO (MT)', _qtyVlsfoCtrl, isNum: true)),
              const SizedBox(width: 10),
              Expanded(child: _buildField('Qty LSMGO (MT)', _qtyLsmgoCtrl, isNum: true)),
            ],
          ),
          _buildField('Date', _dateCtrl),
          
          if (_selectedType == 'Shortage') _buildField('Actual Received Qty (MT)', _missingQtyCtrl),
          if (_selectedType == 'Seal_Numbers') _buildField('Vessel Seal Numbers (comma separated)', _sealNosCtrl),
          if (_selectedType == 'No_Lien_Stamp') _buildField('Charterers Name', _charterersCtrl),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _generateText,
            child: const Text('GENERATE TEXT'),
          ),

          if (_generatedText.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), border: Border.all(color: accent), borderRadius: BorderRadius.circular(12)),
              child: Text(_generatedText, style: const TextStyle(color: Color(0xFF4ADE80), fontFamily: 'monospace', fontSize: 13)),
            ),
            const SizedBox(height: 16),
            const Text('Signatures:', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildSigBtn('Master', _masterSig, (data) => setState(() => _masterSig = data)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSigBtn('Chief Eng', _chiefSig, (data) => setState(() => _chiefSig = data)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSigBtn('Acknowledged', _ackSig, (data) => setState(() => _ackSig = data)),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('EXPORT OFFICIAL PDF FORM'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ]
        ],
    );
  }

  Widget _buildMyFormsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('UPLOAD COMPANY PDF FORM'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<FileSystemEntity>>(
            future: _getSavedFiles(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No custom forms uploaded yet.', style: TextStyle(color: textMuted)));
              }
              final files = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  final fileName = file.path.split(Platform.pathSeparator).last;
                  return Card(
                    color: cardSolid,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                      title: Text(fileName, style: const TextStyle(color: text)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () async {
                              await file.delete();
                              setState(() {});
                            },
                          ),
                          const Icon(Icons.chevron_right, color: accent),
                        ],
                      ),
                      onTap: () => OpenFilex.open(file.path),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<List<FileSystemEntity>> _getSavedFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final customDir = Directory('${dir.path}/custom_forms');
    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }
    return customDir.list().toList();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final dir = await getApplicationDocumentsDirectory();
      final customDir = Directory('${dir.path}/custom_forms');
      if (!await customDir.exists()) await customDir.create(recursive: true);
      
      final fileName = result.files.single.name;
      await file.copy('${customDir.path}/$fileName');
      
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploaded: $fileName')));
    }
  }

  Widget _buildField(String label, TextEditingController ctrl, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
      ),
    );
  }

  // ВОТ ЭТОТ МЕТОД БЫЛ ПОТЕРЯН
  Widget _buildSigBtn(String label, Uint8List? currentSig, Function(Uint8List) onSigned) {
    return ElevatedButton(
      onPressed: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const SignatureScreen()));
        if (result != null) onSigned(result as Uint8List);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: currentSig != null ? Colors.green.withValues(alpha: 0.2) : border,
        foregroundColor: currentSig != null ? Colors.green : text,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        children: [
          Icon(currentSig != null ? Icons.check_circle : Icons.draw, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}