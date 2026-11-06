import 'package:flutter/material.dart';

class EngineLogScreen extends StatelessWidget {
  const EngineLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EngineLog')),
      body: const Center(child: Text('Модули машинного отделения')),
    );
  }
}