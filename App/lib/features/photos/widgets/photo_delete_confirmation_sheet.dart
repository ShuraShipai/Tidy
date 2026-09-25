import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_sizes.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';
import '../../../core/widgets/tidy_glyph.dart';
import '../../../core/widgets/tidy_orb.dart';
import '../../../core/widgets/tidy_safety_note.dart';

/// Final app confirmation for the exact frozen photo selection.
class PhotoDeleteConfirmationSheet extends StatelessWidget {
  const PhotoDeleteConfirmationSheet({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final itemLabel = count == 1 ? 'item' : 'items';
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TidySpacing.lg,
          TidySpacing.sm,
          TidySpacing.lg,
          TidySpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: TidySizes.sheetHandleWidth,
              height: TidySizes.sheetHandleHeight,
              decoration: BoxDecoration(
                color: TidyColors.sheetHandle,
                borderRadius: BorderRadius.circular(
                  TidySizes.sheetHandleHeight,
                ),
              ),
            ),
            const SizedBox(height: TidySpacing.lg),
            const TidyOrb(
              glyph: TidyGlyphName.trash,
              tone: TidyOrbTone.pink,
              size: TidySizes.companionOrb,
            ),
            const SizedBox(height: TidySpacing.md),
            Text(
              'Clean selected items?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: TidySizes.sheetTitleText,
              ),
            ),
            const SizedBox(height: TidySpacing.sm),
            Text(
              '$count selected $itemLabel will move to Recently Deleted. Review your selection before continuing.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: TidyColors.secondaryText),
            ),
            const SizedBox(height: TidySpacing.sm),
            const TidySafetyNote(
              text:
                  'iOS Photos asks for approval before deleting library items.',
            ),
            const SizedBox(height: TidySpacing.sm),
            TidyActionButton(
              label: 'Clean $count ${count == 1 ? 'Item' : 'Items'}',
              style: TidyActionStyle.destructive,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: TidySpacing.actionGap),
            TidyActionButton(
              label: 'Cancel',
              style: TidyActionStyle.secondary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
