import 'package:flutter/material.dart';
import 'screens/demarrage_screen.dart';

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
      home: const DemarrageScreen(),
    );
  }
}
