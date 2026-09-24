import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_sizes.dart';
import '../../../../core/widgets/tidy_glyph.dart';
import '../../widgets/onboarding_action_bar.dart';
import '../../widgets/onboarding_benefits.dart';
import '../../widgets/onboarding_message.dart';
import '../../widgets/onboarding_page_frame.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) => OnboardingPageFrame(
    body: const OnboardingMessage(
      title: 'Make space.\nKeep what matters.',
      description:
          'Find similar photos, screenshots, large videos and duplicate contacts — safely on your iPhone.',
      glyph: TidyGlyphName.storage,
      showCompanions: true,
      titleSize: TidySizes.welcomeText,
      child: OnboardingBenefits(),
    ),
    actions: OnboardingActionBar(
      primaryLabel: 'Continue',
      onPrimary: () => context.push('/onboarding/privacy'),
      secondaryLabel: 'How It Works',
      onSecondary: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('How It Works is not available in this preview.'),
        ),
      ),
    ),
  );
}
