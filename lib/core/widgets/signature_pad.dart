import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../theme.dart';

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black, // Черная ручка
    exportBackgroundColor: Colors.transparent, // Прозрачный фон для PDF
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Sign Document'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Please sign below using your finger.', style: TextStyle(color: textMuted)),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, // Белый фон для рисования
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _controller.clear(),
                    style: ElevatedButton.styleFrom(backgroundColor: border, foregroundColor: text),
                    child: const Text('CLEAR'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_controller.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign first.')));
                        return;
                      }
                      final Uint8List? data = await _controller.toPngBytes();
                      if (data != null) {
                        Navigator.pop(context, data); // Возвращаем картинку назад
                      }
                    },
                    child: const Text('SAVE'),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}