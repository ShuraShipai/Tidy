import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/design/tidy_colors.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../../onboarding/controllers/onboarding_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/permission_status_label.dart';
import '../../models/scan_preferences.dart';
import '../../widgets/settings_entry_row.dart';
import '../../widgets/settings_section_label.dart';

class SettingsHomePage extends ConsumerWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final access = ref.watch(onboardingProvider);
    final state = settings.asData?.value;

    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          child: settings.isLoading || !access.initialized
              ? const Center(child: CircularProgressIndicator.adaptive())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    TidySpacing.lg,
                    TidySpacing.pageTop,
                    TidySpacing.lg,
                    TidySpacing.xl,
                  ),
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SettingsSectionLabel('Privacy'),
                    _group([
                      SettingsEntryRow(
                        icon: Icons.photo_outlined,
                        label: 'Photos Access',
                        status: permissionStatusLabel(
                          access.photos,
                          photos: true,
                        ),
                        onTap: () => context.push('/settings/permissions'),
                      ),
                      SettingsEntryRow(
                        icon: Icons.contacts_outlined,
                        label: 'Contacts Access',
                        status: permissionStatusLabel(access.contacts),
                        onTap: () => context.push('/settings/permissions'),
                      ),
                    ]),
                    const SettingsSectionLabel('Cleaning'),
                    _group([
                      SettingsEntryRow(
                        icon: Icons.tune,
                        label: 'Scan Preferences',
                        onTap: () => context.push('/settings/preferences'),
                      ),
                      SettingsEntryRow(
                        icon: Icons.photo_outlined,
                        label: 'Similar Photo Sensitivity',
                        status: state?.preferences.sensitivity.label,
                        onTap: () => context.push('/settings/sensitivity'),
                      ),
                    ]),
                    const SettingsSectionLabel('Optional Features'),
                    _group([
                      SettingsEntryRow(
                        icon: Icons.lock_outline,
                        label: 'Private Vault',
                        onTap: () => context.push('/bonus/vault'),
                      ),
                      SettingsEntryRow(
                        icon: Icons.calendar_month_outlined,
                        label: 'Calendar Cleanup',
                        onTap: () => context.push('/bonus/calendar'),
                      ),
                      SettingsEntryRow(
                        icon: Icons.widgets_outlined,
                        label: 'Home Screen Widgets',
                        onTap: () => context.push('/bonus/widgets'),
                      ),
                      SettingsEntryRow(
                        icon: Icons.history,
                        label: 'Cleanup History',
                        onTap: () => context.push('/bonus/history'),
                      ),
                    ]),
                    const SettingsSectionLabel('About'),
                    _group([
                      SettingsEntryRow(
                        icon: Icons.verified_user_outlined,
                        label: 'Privacy',
                        onTap: () => context.push('/settings/privacy'),
                      ),
                      SettingsEntryRow(
                        icon: Icons.info_outline,
                        label: 'How Cleaning Works',
                        onTap: () => context.push('/settings/how'),
                      ),
                      SettingsEntryRow(
                        icon: Icons.auto_awesome_outlined,
                        label: 'App Version',
                        status: state?.version.version,
                        onTap: () => context.push('/settings/about'),
                      ),
                    ]),
                    if (settings.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: TidySpacing.md),
                        child: Text(
                          'Some settings could not be loaded. Reopen Settings to try again.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _group(List<Widget> rows) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0)
            const Divider(
              height: 1,
              thickness: 0.5,
              indent: TidySpacing.md,
              endIndent: TidySpacing.md,
              color: TidyColors.divider,
            ),
          rows[index],
        ],
      ],
    ),
  );
}
