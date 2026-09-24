import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_glyph.dart';
import '../models/scan_snapshot.dart';

class ScanStageList extends StatelessWidget {
  const ScanStageList({required this.snapshot, super.key});

  final ScanSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final contactsStage = snapshot.currentStage == 'contacts';
    final mediaStage = snapshot.currentStage == 'media';
    return Column(
      children: [
        for (final category in CleanupCategory.values) ...[
          SizedBox(
            height: 44,
            child: Row(
              children: [
                _stageGlyph(category, contactsStage, mediaStage),
                const SizedBox(width: TidySpacing.sm),
                Expanded(
                  child: Text(
                    _stageLabel(category, contactsStage, mediaStage),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _label(CleanupCategory category) => switch (category) {
    CleanupCategory.similarPhotos => 'Similar photos',
    CleanupCategory.screenshots => 'Screenshots',
    CleanupCategory.largeVideos => 'Large videos',
    CleanupCategory.duplicateContacts => 'Duplicate contacts',
  };

  Widget _stageGlyph(
    CleanupCategory category,
    bool contactsStage,
    bool mediaStage,
  ) {
    if (contactsStage && category != CleanupCategory.duplicateContacts) {
      return const TidyGlyph(
        TidyGlyphName.check,
        size: 21,
        color: TidyColors.emerald,
      );
    }
    if (contactsStage && category == CleanupCategory.duplicateContacts) {
      return const TidyGlyph(
        TidyGlyphName.contacts,
        size: 21,
        color: TidyColors.primary,
      );
    }
    if (mediaStage && category == CleanupCategory.duplicateContacts) {
      return const TidyGlyph(
        TidyGlyphName.contacts,
        size: 21,
        color: TidyColors.secondaryText,
      );
    }
    final glyph = switch (category) {
      CleanupCategory.similarPhotos ||
      CleanupCategory.screenshots => TidyGlyphName.photo,
      CleanupCategory.largeVideos => TidyGlyphName.video,
      CleanupCategory.duplicateContacts => TidyGlyphName.contacts,
    };
    return TidyGlyph(
      glyph,
      size: 21,
      color: mediaStage ? TidyColors.primary : TidyColors.secondaryText,
    );
  }

  String _stageLabel(
    CleanupCategory category,
    bool contactsStage,
    bool mediaStage,
  ) {
    if (contactsStage && category == CleanupCategory.duplicateContacts) {
      return 'Duplicate contacts · scanning…';
    }
    if (contactsStage) return _label(category);
    if (mediaStage && category == CleanupCategory.duplicateContacts) {
      return 'Duplicate contacts · waiting';
    }
    if (mediaStage && category == CleanupCategory.largeVideos) {
      return 'Large videos · scanning…';
    }
    if (mediaStage && category == CleanupCategory.screenshots) {
      return 'Screenshots';
    }
    if (mediaStage && category == CleanupCategory.similarPhotos) {
      return 'Similar photos';
    }
    return _label(category);
  }
}
