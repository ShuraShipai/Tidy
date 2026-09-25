import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../../../core/widgets/tidy_safety_note.dart';
import '../../controllers/settings_controller.dart';
import '../../models/scan_preferences.dart';
import '../../widgets/sensitivity_option_card.dart';
import '../../widgets/settings_done_button.dart';
import '../../widgets/settings_page_top_bar.dart';

class PhotoSensitivityPage extends ConsumerWidget {
  const PhotoSensitivityPage({super.key});

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
              Expanded(
                child: state == null
                    ? const Center(child: CircularProgressIndicator.adaptive())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          TidySpacing.lg,
                          TidySpacing.xs,
                          TidySpacing.lg,
                          TidySpacing.lg,
                        ),
                        children: [
                          Text(
                            'Similar Photo Sensitivity',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: TidySpacing.xs),
                          Text(
                            'Choose how closely photos need to match.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: TidySpacing.md),
                          for (final value
                              in SimilarPhotoSensitivity.values) ...[
                            SensitivityOptionCard(
                              value: value,
                              selected: state.preferences.sensitivity == value,
                              onTap: state.saving
                                  ? () {}
                                  : () => ref
                                        .read(
                                          settingsControllerProvider.notifier,
                                        )
                                        .setSensitivity(value),
                            ),
                            const SizedBox(height: TidySpacing.sm),
                          ],
                          const TidySafetyNote(
                            text:
                                'Suggestions are never mandatory. You choose the keeper in every set.',
                          ),
                          if (state.error != null)
                            Text(
                              state.error!,
                              style: Theme.of(context).textTheme.bodyMedium,
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
}
