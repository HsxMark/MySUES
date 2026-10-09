import 'package:flutter/material.dart';
import 'package:mysues/l10n/l10n.dart';
import 'package:mysues/screens/settings/fold_settings_screen.dart';
import 'package:mysues/services/fold_service.dart';
import 'package:mysues/widgets/material_you.dart';

/// The single entry point to the foldable settings.
///
/// Everything else lives one level down, and the whole section is hidden on
/// devices that do not fold.
class FoldSettingsSection extends StatelessWidget {
  const FoldSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FoldService();
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (!service.isFoldable) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSectionHeader(context.l10n.foldable),
            AppCardSection(
              children: [
                ListTile(
                  leading: const Icon(Icons.unfold_more),
                  title: Text(context.l10n.foldable),
                  subtitle: Text(
                    service.enabled ? context.l10n.foldOn : context.l10n.foldOff,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FoldSettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
