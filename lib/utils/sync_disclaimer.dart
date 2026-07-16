import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysues/l10n/l10n.dart';

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
          title: Text(context.l10n.disclaimer),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.thisFeatureProvidesAConvenientWayToSyncInformation,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () =>
                    setDialogState(() => dontShowAgain = !dontShowAgain),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: dontShowAgain,
                        onChanged: (v) =>
                            setDialogState(() => dontShowAgain = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.doNotShowAgain,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                if (dontShowAgain) {
                  prefs.setBool(hideKey, true);
                }
                Navigator.pop(ctx, true);
              },
              child: Text(context.l10n.iUnderstand),
            ),
          ],
        ),
      );
    },
  );

  return confirmed == true;
}
