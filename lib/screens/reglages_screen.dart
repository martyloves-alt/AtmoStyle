// Écran Réglages — le bouton programme désormais un vrai rappel quotidien
// (notification locale à horaire approximatif, pas une alarme exacte).

import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class ReglagesScreen extends StatefulWidget {
  const ReglagesScreen({super.key});

  @override
  State<ReglagesScreen> createState() => _ReglagesScreenState();
}

class _ReglagesScreenState extends State<ReglagesScreen> {
  bool _notificationsActives = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    if (_notificationsActives) {
      _onToggle(true);
    }
  }

  Future<void> _onToggle(bool value) async {
    setState(() => _isUpdating = true);

    final service = NotificationService();
    await service.init();

    if (value) {
      final granted = await service.requestPermission();
      if (granted) {
        await service.scheduleDailyReminder(hour: 20, minute: 0);
      } else {
        value = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Autorisation refusée : active les notifications dans les réglages du téléphone.",
              ),
            ),
          );
        }
      }
    } else {
      await service.cancelDailyReminder();
    }

    if (!mounted) return;
    setState(() {
      _notificationsActives = value;
      _isUpdating = false;
    });
  }

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
              onChanged: _isUpdating ? null : _onToggle,
            ),
          ],
        ),
      ),
    );
  }
}
