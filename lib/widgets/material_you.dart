import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

export '../theme/app_tokens.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.page,
      AppSpacing.xl,
      AppSpacing.page,
      AppSpacing.sm,
    ),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class AppCardSection extends StatelessWidget {
  const AppCardSection({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
    child: Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Divider(indent: 16, endIndent: 16),
          ],
        ],
      ),
    ),
  );
}

enum AppNoticeKind { info, warning, error, success }

class AppNoticeBanner extends StatelessWidget {
  const AppNoticeBanner({
    required this.message,
    this.kind = AppNoticeKind.info,
    this.icon,
    super.key,
  });

  final String message;
  final AppNoticeKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = context.statusColors;
    final (background, foreground, defaultIcon) = switch (kind) {
      AppNoticeKind.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline,
      ),
      AppNoticeKind.warning => (
        status.warningContainer,
        status.onWarningContainer,
        Icons.warning_amber_rounded,
      ),
      AppNoticeKind.success => (
        status.successContainer,
        status.onSuccessContainer,
        Icons.check_circle_outline,
      ),
      AppNoticeKind.info => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.info_outline,
      ),
    };
    return Material(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon ?? defaultIcon, size: 20, color: foreground),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AppStatusKind { neutral, info, warning, error, success }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    required this.label,
    this.kind = AppStatusKind.neutral,
    super.key,
  });

  final String label;
  final AppStatusKind kind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = context.statusColors;
    final (background, foreground) = switch (kind) {
      AppStatusKind.error => (scheme.errorContainer, scheme.onErrorContainer),
      AppStatusKind.warning => (
        status.warningContainer,
        status.onWarningContainer,
      ),
      AppStatusKind.success => (
        status.successContainer,
        status.onSuccessContainer,
      ),
      AppStatusKind.info => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      AppStatusKind.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
