import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysues/screens/settings/display_settings_screen.dart';
import 'package:mysues/screens/settings/notifications_screen.dart';
import 'package:mysues/l10n/l10n.dart';
import 'package:mysues/services/locale_service.dart';
import 'package:mysues/services/notification_service.dart';
import 'package:mysues/services/widget_service.dart';
import 'package:mysues/l10n/legacy_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: LText(context.l10n.settings), centerTitle: true),
      body: ListView(
        children: [
          _buildGroupTitle(context, context.l10n.general),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: LText(context.l10n.notifications),
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
            title: LText(context.l10n.appearanceAndDisplay),
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
            title: LText(context.l10n.language),
            subtitle: LText(_languageName(context, LocaleService().language)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context),
          ),
          const Divider(),
          _buildGroupTitle(context, context.l10n.dataAndPrivacy),
          ListTile(
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.red,
            ),
            title: LText(
              context.l10n.clearAllData,
              style: const TextStyle(color: Colors.red),
            ),
            subtitle: LText(context.l10n.clearAllDataSubtitle),
            onTap: () => _showClearDataDialog(context),
          ),
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
            return RadioListTile<AppLanguage>(
              value: language,
              groupValue: LocaleService().language,
              title: LText(_languageName(sheetContext, language)),
              onChanged: (value) async {
                if (value == null) return;
                await LocaleService().setLanguage(value);
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

  Widget _buildGroupTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: LText(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: LText(context.l10n.clearAllDataQuestion),
        content: LText(context.l10n.clearAllDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: LText(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showFinalClearDataDialog(context);
            },
            child: LText(
              context.l10n.confirmClear,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: LText(context.l10n.confirmAgain),
        content: LText(context.l10n.confirmClearFinal),
        actions: [
          // Swapped order: Confirm button first on the left, Cancel on the right
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performClearData(context);
            },
            child: LText(
              context.l10n.confirmClear,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: LText(context.l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _performClearData(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // TODO: Add clearing of any local files/databases here if implemented later

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: LText(context.l10n.dataClearedRestart)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: LText(context.l10n.clearFailed(e.toString()))),
        );
      }
    }
  }
}
