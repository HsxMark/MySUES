import 'package:flutter/material.dart';
import 'package:mysues/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const hideAppIntegrityWarningPreferenceKey =
    'hide_unofficial_distribution_warning_on_startup';
const officialAppDownloadUrl = 'https://syntrion.dev/mysues#download';

Future<void> openOfficialDownloadPage(BuildContext context) async {
  var launched = false;
  try {
    launched = await launchUrl(
      Uri.parse(officialAppDownloadUrl),
      mode: LaunchMode.externalApplication,
    );
  } catch (error) {
    debugPrint('Unable to open official download page: $error');
  }

  if (!launched && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(context.l10n.officialDownloadOpenFailed)),
    );
  }
}

Future<void> showAppIntegrityWarningDialog(
  BuildContext context, {
  SharedPreferences? preferences,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final hideWarning =
      prefs.getBool(hideAppIntegrityWarningPreferenceKey) ?? false;
  if (hideWarning || !context.mounted) return;

  var doNotRemindAgain = false;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final colorScheme = Theme.of(dialogContext).colorScheme;
            return AlertDialog(
              icon: Icon(
                Icons.gpp_bad_outlined,
                color: colorScheme.error,
                size: 32,
              ),
              title: Text(
                dialogContext.l10n.appIntegrityWarningTitle,
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dialogContext.l10n.appIntegrityWarningMessage),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: doNotRemindAgain,
                        onChanged: (value) {
                          setDialogState(() {
                            doNotRemindAgain = value ?? false;
                          });
                        },
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setDialogState(() {
                              doNotRemindAgain = !doNotRemindAgain;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              dialogContext.l10n.doNotRemindAtStartup,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => openOfficialDownloadPage(dialogContext),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(dialogContext.l10n.downloadOfficialVersion),
                ),
                FilledButton(
                  onPressed: () async {
                    if (doNotRemindAgain) {
                      await prefs.setBool(
                        hideAppIntegrityWarningPreferenceKey,
                        true,
                      );
                    }
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text(dialogContext.l10n.continueUsing),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

class AppIntegrityWarningCard extends StatelessWidget {
  const AppIntegrityWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.error.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.gpp_bad_outlined, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.appIntegrityWarningTitle,
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.appIntegrityWarningMessage,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => openOfficialDownloadPage(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(context.l10n.downloadOfficialVersion),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
