import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_config.dart';

class UpdateDialog extends StatelessWidget {
  final AppVersion update;

  const UpdateDialog({super.key, required this.update});

  Future<void> _launchUpdateUrl() async {
    final Uri url = Uri.parse(update.updateUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMandatory = update.isMandatory;

    return PopScope(
      canPop: !isMandatory, // Prevent dismissal if mandatory
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF0F172A),
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              isMandatory ? 'Critical Update' : 'Update Available',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${update.versionName}',
              style: const TextStyle(color: Color(0xFFD946EF), fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              update.updateMessage.isNotEmpty
                  ? update.updateMessage
                  : 'A new version of FaithStream is available. Update now to enjoy the latest features and improvements.',
              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
            ),
          ],
        ),
        actions: [
          if (!isMandatory)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later', style: TextStyle(color: Colors.white38)),
            ),
          ElevatedButton(
            onPressed: _launchUpdateUrl,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF040B1F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  static void show(BuildContext context, AppVersion update) {
    showDialog(
      context: context,
      barrierDismissible: !update.isMandatory,
      useRootNavigator: true, // Important: stay on top of route changes
      builder: (context) => UpdateDialog(update: update),
    );
  }
}
