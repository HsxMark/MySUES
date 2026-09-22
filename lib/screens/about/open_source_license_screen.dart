import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mysues/l10n/l10n.dart';
import 'package:mysues/widgets/material_you.dart';

class OpenSourceLicenseScreen extends StatelessWidget {
  const OpenSourceLicenseScreen({super.key});

  static const _repositoryUrl = 'https://github.com/HsxMark/MySUES';

  Future<void> _launchRepository() async {
    final uri = Uri.parse(_repositoryUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('Could not open repository: $uri');
      }
    } catch (error) {
      debugPrint('Could not open repository: $uri ($error)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.openSource)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          AppCardSection(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppRadii.medium),
                      ),
                      child: Icon(
                        Icons.code_rounded,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'MySUES',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const AppStatusBadge(
                                label: 'GPL-3.0',
                                kind: AppStatusKind.info,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            context.l10n.contributionsAndBugReportsAreWelcome,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                leading: Icon(Icons.link_rounded, color: scheme.primary),
                title: Text(
                  'github.com/HsxMark/MySUES',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.open_in_new_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                onTap: _launchRepository,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
