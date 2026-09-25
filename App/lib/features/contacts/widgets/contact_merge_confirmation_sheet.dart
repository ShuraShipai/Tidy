import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';
import '../../../core/widgets/tidy_glyph.dart';
import '../../../core/widgets/tidy_orb.dart';
import '../../../core/widgets/tidy_safety_note.dart';

class ContactMergeConfirmationSheet extends StatelessWidget {
  const ContactMergeConfirmationSheet({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TidySpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: TidyColors.secondaryText,
              borderRadius: BorderRadius.circular(TidyRadii.button),
            ),
          ),
          const SizedBox(height: 28),
          const TidyOrb(
            glyph: TidyGlyphName.contacts,
            tone: TidyOrbTone.green,
            size: 68,
          ),
          const SizedBox(height: 26),
          Text(
            'Merge these contacts?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'The two reviewed records will become the merged contact shown in your preview.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 26),
          const TidySafetyNote(
            text: 'Review all fields before combining records.',
          ),
          const SizedBox(height: 14),
          TidyActionButton(
            label: 'Merge Contacts',
            style: TidyActionStyle.destructive,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
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
