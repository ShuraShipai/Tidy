import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../widgets/bonus_page_frame.dart';

class BonusToolsPage extends StatelessWidget {
  const BonusToolsPage({super.key});

  @override
  Widget build(BuildContext context) => BonusPageFrame(
    title: 'Optional Features',
    subtitle: 'Extra tools you can use when you need them.',
    backLabel: 'Settings',
    child: Column(
      children: [
        _ToolEntry(
          icon: Icons.lock_outline,
          title: 'Private Vault',
          detail: 'Keep chosen copies behind device authentication.',
          onTap: () => context.push('/bonus/vault'),
        ),
        const SizedBox(height: TidySpacing.md),
        _ToolEntry(
          icon: Icons.calendar_month_outlined,
          title: 'Calendar Cleanup',
          detail: 'Review old and repeated event occurrences.',
          onTap: () => context.push('/bonus/calendar'),
        ),
        const SizedBox(height: TidySpacing.md),
        _ToolEntry(
          icon: Icons.widgets_outlined,
          title: 'Home Screen Widgets',
          detail: 'Add a dated storage summary to your Home Screen.',
          onTap: () => context.push('/bonus/widgets'),
        ),
        const SizedBox(height: TidySpacing.md),
        _ToolEntry(
          icon: Icons.history,
          title: 'Cleanup History',
          detail: 'See completed actions saved on this iPhone.',
          onTap: () => context.push('/bonus/history'),
        ),
        const SizedBox(height: TidySpacing.lg),
        const Text(
          'These tools use local device data. They do not start a library scan automatically.',
        ),
      ],
    ),
  );
}

class _ToolEntry extends StatelessWidget {
  const _ToolEntry({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(TidySpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: TidySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: TidySpacing.xs),
                  Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}
