import 'package:flutter/material.dart';

class DeckMenuScreen extends StatelessWidget {
  const DeckMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deck Tools')),
      body: const Center(child: Text('Палубные модули')),
    );
  }
}