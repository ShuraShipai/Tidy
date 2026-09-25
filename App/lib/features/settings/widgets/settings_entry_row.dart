import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';

class SettingsEntryRow extends StatelessWidget {
  const SettingsEntryRow({
    required this.icon,
    required this.label,
    this.status,
    this.onTap,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? status;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Material(
    color: TidyColors.surface,
    child: InkWell(
      onTap: enabled ? onTap : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TidySpacing.md,
            vertical: TidySpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: TidyColors.violetDeep),
              const SizedBox(width: TidySpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (status != null)
                Padding(
                  padding: const EdgeInsets.only(right: TidySpacing.xs),
                  child: Text(
                    status!,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              Icon(
                Icons.chevron_right,
                size: 19,
                color: TidyColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
