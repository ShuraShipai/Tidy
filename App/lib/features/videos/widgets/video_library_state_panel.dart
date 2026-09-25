import 'package:flutter/material.dart';
import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';
import '../../../core/widgets/tidy_glyph.dart';

class VideoLibraryStatePanel extends StatelessWidget {
  const VideoLibraryStatePanel({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.loading = false,
    this.dark = false,
    super.key,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;
  final bool dark;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(TidySpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const CircularProgressIndicator(color: TidyColors.primary)
          else
            const TidyGlyph(
              TidyGlyphName.video,
              size: 48,
              color: TidyColors.pink,
            ),
          const SizedBox(height: TidySpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: dark ? Colors.white : TidyColors.primaryText,
            ),
          ),
          const SizedBox(height: TidySpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dark ? Colors.white70 : TidyColors.secondaryText,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: TidySpacing.lg),
            TidyActionButton(
              label: actionLabel!,
              onPressed: onAction,
              style: TidyActionStyle.secondary,
            ),
          ],
        ],
      ),
    ),
  );
}
