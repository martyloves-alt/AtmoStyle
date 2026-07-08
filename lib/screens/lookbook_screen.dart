import 'package:flutter/material.dart';
import '../models/atmostyle_contract.dart';
import 'reglages_screen.dart';
import 'validation_screen.dart';

class LookbookScreen extends StatelessWidget {
  const LookbookScreen({super.key, required this.output});

  final EngineOutput output;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ton look du jour'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReglagesScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(output.weatherHeadline, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Image générée par IA — à venir',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(output.outfitSummary, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            ...output.garmentPieces.map(
              (piece) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6),
                    const SizedBox(width: 8),
                    Expanded(child: Text(piece)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(output.accessoryNote, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(output.fragranceNote, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ValidationScreen(output: output)),
              ),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Commander la confection'),
            ),
          ],
        ),
      ),
    );
  }
}
