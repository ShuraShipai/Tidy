import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../../../core/widgets/tidy_safety_note.dart';
import '../../controllers/settings_controller.dart';
import '../../widgets/settings_page_top_bar.dart';

class ScanPreferencesPage extends ConsumerWidget {
  const ScanPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final state = settings.asData?.value;
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
                            'Scan Preferences',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: TidySpacing.xs),
                          Text(
                            'Choose what to include in the next scan.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: TidySpacing.md),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                SwitchListTile.adaptive(
                                  title: const Text('Screenshots'),
                                  value: state.preferences.includeScreenshots,
                                  onChanged: state.saving
                                      ? null
                                      : ref
                                            .read(
                                              settingsControllerProvider
                                                  .notifier,
                                            )
                                            .setIncludeScreenshots,
                                ),
                                const Divider(
                                  height: 1,
                                  indent: TidySpacing.md,
                                  endIndent: TidySpacing.md,
                                ),
                                SwitchListTile.adaptive(
                                  title: const Text('Large Videos'),
                                  value: state.preferences.includeLargeVideos,
                                  onChanged: state.saving
                                      ? null
                                      : ref
                                            .read(
                                              settingsControllerProvider
                                                  .notifier,
                                            )
                                            .setIncludeLargeVideos,
                                ),
                              ],
                            ),
                          ),
                          const TidySafetyNote(
                            text:
                                'Preferences affect discovery only. They never select or remove items.',
                          ),
                          if (state.error != null)
                            Text(
                              state.error!,
                              style: Theme.of(context).textTheme.bodyMedium,
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
}
