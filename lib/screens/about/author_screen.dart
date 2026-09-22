import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mysues/l10n/l10n.dart';
import 'package:mysues/widgets/material_you.dart';

class AuthorScreen extends StatelessWidget {
  const AuthorScreen({super.key});

  static const _avatarAsset = 'assets/images/author_avatar.png';
  static const _githubUrl = 'https://github.com/HsxMark';

  Future<void> _launchGitHub() async {
    final uri = Uri.parse(_githubUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('Could not open author GitHub profile: $uri');
      }
    } catch (error) {
      debugPrint('Could not open author GitHub profile: $uri ($error)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.author)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          AppCardSection(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Container(
                  width: 88,
                  height: 88,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainerHighest,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage(_avatarAsset),
                  ),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                leading: Icon(Icons.code_rounded, color: scheme.primary),
                title: Text(
                  'GitHub',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'github.com/HsxMark',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  Icons.open_in_new_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                onTap: _launchGitHub,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
