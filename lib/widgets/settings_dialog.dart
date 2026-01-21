import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _notificationsEnabled;
  late bool _vibrationEnabled;

  @override
  void initState() {
    super.initState();
    final service = NotificationService();
    _notificationsEnabled = service.notificationsEnabled;
    _vibrationEnabled = service.vibrationEnabled;
  }

  Future<void> _save() async {
    await NotificationService().saveSettings(
      notificationsEnabled: _notificationsEnabled,
      vibrationEnabled: _vibrationEnabled,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Preferencias guardadas'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '⚙️ Ajustes',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: Text(
              'Notificaciones',
              style: GoogleFonts.poppins(),
            ),
            subtitle: Text(
              'Activar alertas en el teléfono',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: Text(
              'Vibración',
              style: GoogleFonts.poppins(),
            ),
            subtitle: Text(
              'Vibrar al recibir notificación',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            value: _vibrationEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                  }
                : null, // Disable if notifications are off
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
