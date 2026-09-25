import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_orb.dart';
import '../../../../core/widgets/tidy_glyph.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../controllers/settings_controller.dart';
import '../../widgets/settings_page_top_bar.dart';

class AboutTidyPage extends ConsumerWidget {
  const AboutTidyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider).asData?.value;
    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: TidySpacing.lg),
                child: SettingsPageTopBar(backLabel: 'Back'),
              ),
              const Spacer(),
              const TidyOrb(glyph: TidyGlyphName.storage),
              const SizedBox(height: TidySpacing.md),
              Text('tidy', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: TidySpacing.sm),
              Text(
                state?.version.label ?? 'Version unavailable',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: TidySpacing.lg),
              Text(
                'Free. Private. On your iPhone.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
