import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DeckMenuScreen extends StatelessWidget {
  const DeckMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deck Tools')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ElevatedButton(
            onPressed: () => context.push('/deck/gm_roll'),
            child: const Text('GM Estimate'),
          ),
        ],
      ),
    );
  }
}