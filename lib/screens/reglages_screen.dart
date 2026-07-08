// Écran Réglages — le bouton existe, mais rien n'est encore programmé
// réellement : la planification de notification/alarme Android arrive
// dans l'étape suivante.

import 'package:flutter/material.dart';

class ReglagesScreen extends StatefulWidget {
  const ReglagesScreen({super.key});

  @override
  State<ReglagesScreen> createState() => _ReglagesScreenState();
}

class _ReglagesScreenState extends State<ReglagesScreen> {
  bool _notificationsActives = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Notifications proactives'),
              subtitle: const Text(
                "Alertes de la veille : la tenue du lendemain, tous les soirs à 20h00.",
              ),
              value: _notificationsActives,
              onChanged: (v) => setState(() => _notificationsActives = v),
            ),
          ],
        ),
      ),
    );
  }
}
