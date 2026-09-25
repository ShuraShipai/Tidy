import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_page_background.dart';

class BonusPageFrame extends StatelessWidget {
  const BonusPageFrame({
    required this.title,
    this.child,
    this.slivers,
    this.subtitle,
    this.footer,
    this.backLabel,
    this.onBack,
    super.key,
  }) : assert((child == null) != (slivers == null));

  final String title;
  final String? subtitle;
  final Widget? child;
  final List<Widget>? slivers;
  final Widget? footer;
  final String? backLabel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TidyPageBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (backLabel != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onBack ?? context.pop,
                  icon: const Icon(Icons.chevron_left),
                  label: Text(backLabel!),
                ),
              ),
            Expanded(child: _scrollContent(context)),
            if (footer != null)
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(
                  TidySpacing.lg,
                  TidySpacing.sm,
                  TidySpacing.lg,
                  TidySpacing.sm,
                ),
                child: footer!,
              ),
          ],
        ),
      ),
    ),
  );

  Widget _scrollContent(BuildContext context) {
    final heading = <Widget>[
      Text(title, style: Theme.of(context).textTheme.headlineLarge),
      if (subtitle != null) ...[
        const SizedBox(height: TidySpacing.xs),
        Text(subtitle!, style: Theme.of(context).textTheme.bodyLarge),
      ],
      const SizedBox(height: TidySpacing.lg),
    ];
    const padding = EdgeInsets.fromLTRB(
      TidySpacing.lg,
      TidySpacing.md,
      TidySpacing.lg,
      TidySpacing.lg,
    );
    if (slivers != null) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: padding,
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: heading,
              ),
            ),
          ),
          ...slivers!,
        ],
      );
    }
    return ListView(padding: padding, children: [...heading, child!]);
  }
}
