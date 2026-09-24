import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mysues/screens/settings/display_settings_screen.dart';
import 'package:mysues/screens/settings/notifications_screen.dart';
import 'package:mysues/l10n/l10n.dart';
import 'package:mysues/services/locale_service.dart';
import 'package:mysues/services/local_image_store.dart';
import 'package:mysues/services/notification_service.dart';
import 'package:mysues/services/theme_service.dart';
import 'package:mysues/services/widget_service.dart';
import 'package:mysues/widgets/material_you.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings), centerTitle: true),
      body: ListView(
        children: [
          AppSectionHeader(context.l10n.general),
          AppCardSection(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(context.l10n.notifications),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(context.l10n.appearanceAndDisplay),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DisplaySettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(context.l10n.language),
                subtitle: Text(
                  _languageName(context, LocaleService().language),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguagePicker(context),
              ),
            ],
          ),
          AppSectionHeader(context.l10n.dataAndPrivacy),
          AppCardSection(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined),
                title: Text(
                  context.l10n.clearAllData,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: Text(context.l10n.clearAllDataSubtitle),
                onTap: () => _showClearDataDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _languageName(BuildContext context, AppLanguage language) =>
      switch (language) {
        AppLanguage.system => context.l10n.languageSystem,
        AppLanguage.zhHans => context.l10n.languageChinese,
        AppLanguage.english => context.l10n.languageEnglish,
      };

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((language) {
            return ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(_languageName(sheetContext, language)),
              trailing: LocaleService().language == language
                  ? Icon(
                      Icons.check,
                      color: Theme.of(sheetContext).colorScheme.primary,
                    )
                  : null,
              onTap: () async {
                await LocaleService().setLanguage(language);
                await WidgetService.updateWidget();
                await NotificationService().rescheduleAll();
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.clearAllDataQuestion),
        content: Text(context.l10n.clearAllDataWarning),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showFinalClearDataDialog(context);
            },
            child: Text(context.l10n.confirmClear),
          ),
        ],
      ),
    );
  }

  void _showFinalClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.confirmAgain),
        content: Text(context.l10n.confirmClearFinal),
        actions: [
          // Swapped order: Confirm button first on the left, Cancel on the right
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.pop(context);
              _performClearData(context);
            },
            child: Text(context.l10n.confirmClear),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _performClearData(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cancel scheduled local reminders while the scheduled-ID lists are
      // still readable from preferences.
      try {
        await NotificationService().cancelCourseReminders();
        await NotificationService().cancelExamReminders();
      } catch (_) {
        // Best effort: the notification plugin may be unavailable on some
        // platforms or not yet initialized.
      }

      // Remove the app-owned images while the preferences still point at them;
      // their keys are dropped by prefs.clear() below.
      await _clearStoredImages();

      await prefs.clear();
      await _deleteLocalFiles();

      // The theme service caches these values in memory, so it has to forget
      // them explicitly or the UI keeps pointing at the files we just deleted.
      ThemeService().resetAfterExternalClear();

      // Refresh the home-screen widget so it no longer shows stale data.
      await WidgetService.updateWidget();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.dataClearedRestart)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.clearFailed(e.toString()))),
        );
      }
    }
  }

  /// Deletes the stored avatar and background image, including leftovers from
  /// earlier versions. Runs before the preferences are wiped because the stores
  /// resolve their file names from them.
  Future<void> _clearStoredImages() async {
    try {
      await LocalImageStore.avatar.clear();
    } catch (_) {
      // Best effort per store.
    }
    try {
      await LocalImageStore.background.clear();
    } catch (_) {
      // Best effort per store.
    }
  }

  /// Deletes the app-owned files stored in the documents directory: the user
  /// avatar, the custom background image, any persisted session cookies, and
  /// the WebView session cookies (mobile platforms).
  Future<void> _deleteLocalFiles() async {
    final Directory docDir = await getApplicationDocumentsDirectory();
    if (await docDir.exists()) {
      await for (final entity in docDir.list()) {
        final name = entity.path.split(RegExp(r'[/\\]')).last;
        try {
          if (entity is File &&
              (name.startsWith('user_avatar_') ||
                  name.startsWith('background_image'))) {
            await entity.delete();
          } else if (entity is Directory && name == '.cookies') {
            await entity.delete(recursive: true);
          }
        } catch (_) {
          // Best effort per file.
        }
      }
    }

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await WebViewCookieManager().clearCookies();
      } catch (_) {
        // Best effort; webview cookie manager may be unavailable.
      }
    }
  }
}
