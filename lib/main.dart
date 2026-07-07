import 'package:flutter/material.dart';

void main() {
  runApp(const AtmoStyleApp());
}

class AtmoStyleApp extends StatelessWidget {
  const AtmoStyleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AtmoStyle',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepOrange),
      home: const _PlaceholderHome(),
    );
  }
}

/// Écran temporaire. Les vrais écrans (questions, Lookbook, Réglages,
/// Validation) arrivent dans une étape ultérieure — ce placeholder garde
/// juste le projet buildable dès maintenant.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('AtmoStyle — écrans à venir'),
      ),
    );
  }
}
