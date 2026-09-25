import 'package:flutter/material.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../../../core/widgets/tidy_safety_note.dart';
import '../../widgets/settings_info_card.dart';
import '../../widgets/settings_page_top_bar.dart';

class HowCleaningWorksPage extends StatelessWidget {
  const HowCleaningWorksPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TidyPageBackground(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: TidySpacing.lg),
              child: SettingsPageTopBar(backLabel: 'Back'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  TidySpacing.lg,
                  TidySpacing.xs,
                  TidySpacing.lg,
                  TidySpacing.md,
                ),
                children: [
                  Text(
                    'A safer way to make space.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: TidySpacing.md),
                  const SettingsInfoCard(
                    icon: Icons.crop_free,
                    title: 'Find what’s there',
                    body: 'Scan your accessible library on this iPhone.',
                  ),
                  const SizedBox(height: TidySpacing.sm),
                  const SettingsInfoCard(
                    icon: Icons.photo_outlined,
                    title: 'Choose what goes',
                    body:
                        'Compare similar items and select only what you no longer need.',
                  ),
                  const SizedBox(height: TidySpacing.sm),
                  const SettingsInfoCard(
                    icon: Icons.verified_user_outlined,
                    title: 'Review it together',
                    body:
                        'Check every category, then explicitly confirm cleanup.',
                  ),
                  const SizedBox(height: TidySpacing.sm),
                  const SettingsInfoCard(
                    icon: Icons.check_circle_outline,
                    title: 'See the result',
                    body:
                        'Only successfully handled items count. Failed items stay available.',
                  ),
                  const TidySafetyNote(
                    text:
                        'Photos may stay in Recently Deleted before storage becomes available.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
