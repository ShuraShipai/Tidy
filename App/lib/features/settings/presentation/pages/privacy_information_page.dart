import 'package:flutter/material.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../widgets/settings_done_button.dart';
import '../../widgets/settings_info_card.dart';
import '../../widgets/settings_page_top_bar.dart';

class PrivacyInformationPage extends StatelessWidget {
  const PrivacyInformationPage({super.key});

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
                  TidySpacing.lg,
                ),
                children: [
                  Text(
                    'Built around privacy.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: TidySpacing.md),
                  const SettingsInfoCard(
                    icon: Icons.verified_user_outlined,
                    title: 'Your iPhone. Your information.',
                    body:
                        'Tidy analyzes accessible photos, videos, and contacts on this device. No account, cloud sync, or upload is used.',
                  ),
                  const SizedBox(height: TidySpacing.md),
                  const SettingsInfoCard(
                    title: 'Permission is your choice',
                    body:
                        'Use only the features you’re comfortable with. Change access at any time in iOS Settings.',
                  ),
                  const SizedBox(height: TidySpacing.md),
                  const SettingsInfoCard(
                    title: 'You approve every change',
                    body:
                        'Discovery never means deletion. Review your selection and confirm before anything is removed.',
                  ),
                ],
              ),
            ),
            SettingsDoneButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    ),
  );
}
