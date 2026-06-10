import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'theme.dart';

class UpdateService {
  static const _repo = 'Juneil-reedz/anonymous';
  static const _currentVersion = '1.0.1';
  static const _apkDownloadUrl =
      'https://github.com/$_repo/releases/latest/download/app-release.apk';

  static Future<void> checkAndPrompt(BuildContext context) async {
    if (kIsWeb) return;
    try {
      final res = await http
          .get(Uri.parse('https://api.github.com/repos/$_repo/releases/latest'),
              headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final data = json.decode(res.body) as Map<String, dynamic>;
      final tag = (data['tag_name'] as String? ?? '').replaceAll('v', '').trim();
      if (tag.isEmpty || !_isNewer(tag, _currentVersion)) return;
      if (!context.mounted) return;
      _showBanner(context, tag);
    } catch (_) {}
  }

  static bool _isNewer(String remote, String local) {
    final r = remote.split('.').map(int.tryParse).toList();
    final l = local.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final rv = i < r.length ? (r[i] ?? 0) : 0;
      final lv = i < l.length ? (l[i] ?? 0) : 0;
      if (rv > lv) return true;
      if (rv < lv) return false;
    }
    return false;
  }

  static void _showBanner(BuildContext context, String newVersion) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => _UpdateSheet(newVersion: newVersion),
    );
  }
}

class _UpdateSheet extends StatelessWidget {
  final String newVersion;
  const _UpdateSheet({required this.newVersion});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AnonTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AnonTheme.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AnonTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.system_update_rounded,
                    color: AnonTheme.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Update Available — v$newVersion',
                        style: const TextStyle(
                            color: AnonTheme.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    const Text('A new version of Anonymous is ready.',
                        style: TextStyle(color: AnonTheme.subtext, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Share.share(
                  'Download the latest Anonymous app (v$newVersion):\n${UpdateService._apkDownloadUrl}',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AnonTheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: Text('Download v$newVersion',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later',
                style: TextStyle(color: AnonTheme.subtext, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
