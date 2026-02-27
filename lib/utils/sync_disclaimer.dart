import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shows the sync disclaimer dialog if the user hasn't opted to hide it.
/// Returns `true` if the user confirmed (or previously opted out), `false` otherwise.
Future<bool> showSyncDisclaimer(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  const hideKey = 'hide_sync_disclaimer';
  final hideDisclaimer = prefs.getBool(hideKey) ?? false;

  if (hideDisclaimer) return true;

  if (!context.mounted) return false;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      bool dontShowAgain = false;
      return StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('免责声明'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('本功能仅提供便捷的信息同步服务，导入的数据可能存在偏差。请仔细核对同步后的信息，一切以教务处网站显示为准。'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setDialogState(() => dontShowAgain = !dontShowAgain),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: dontShowAgain,
                        onChanged: (v) => setDialogState(() => dontShowAgain = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('不再显示', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (dontShowAgain) {
                  prefs.setBool(hideKey, true);
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('我已知悉'),
            ),
          ],
        ),
      );
    },
  );

  return confirmed == true;
}
