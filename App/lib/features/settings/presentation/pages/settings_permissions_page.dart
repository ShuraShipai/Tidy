import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../../onboarding/controllers/onboarding_controller.dart';
import '../../../onboarding/models/access_status.dart';
import '../../../onboarding/models/permission_subject.dart';
import '../../../onboarding/repositories/onboarding_repository.dart';
import '../../models/permission_status_label.dart';
import '../../widgets/settings_page_top_bar.dart';
import '../../widgets/settings_permission_card.dart';
import '../../widgets/settings_access_refresh_note.dart';

class SettingsPermissionsPage extends ConsumerWidget {
  const SettingsPermissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(onboardingProvider);
    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: TidySpacing.lg),
                child: SettingsPageTopBar(backLabel: 'Settings'),
              ),
              Expanded(
                child: access.initialized
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(
                          TidySpacing.lg,
                          TidySpacing.xs,
                          TidySpacing.lg,
                          TidySpacing.lg,
                        ),
                        children: [
                          Text(
                            'Privacy & Access',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: TidySpacing.xs),
                          Text(
                            'You’re always in control.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: TidySpacing.md),
                          _permissionCard(
                            context,
                            ref,
                            subject: PermissionSubject.photos,
                            status: access.photos,
                            description:
                                'Scan only the library items you allow.',
                          ),
                          const SizedBox(height: TidySpacing.sm),
                          _permissionCard(
                            context,
                            ref,
                            subject: PermissionSubject.contacts,
                            status: access.contacts,
                            description: 'Find possible duplicate entries.',
                          ),
                          const SizedBox(height: TidySpacing.lg),
                          const SettingsAccessRefreshNote(),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator.adaptive()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _permissionCard(
    BuildContext context,
    WidgetRef ref, {
    required PermissionSubject subject,
    required AccessStatus status,
    required String description,
  }) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: SettingsPermissionCard(
      title: subject == PermissionSubject.photos ? 'Photos' : 'Contacts',
      status: permissionStatusLabel(
        status,
        photos: subject == PermissionSubject.photos,
      ),
      description: description,
      actionLabel: status == AccessStatus.notDetermined
          ? 'Request Access'
          : subject == PermissionSubject.photos &&
                status == AccessStatus.limited
          ? 'Manage Photos'
          : 'Open Settings',
      onAction: () => _manage(ref, subject, status),
    ),
  );

  Future<void> _manage(
    WidgetRef ref,
    PermissionSubject subject,
    AccessStatus status,
  ) async {
    if (status == AccessStatus.notDetermined) {
      await ref.read(onboardingProvider.notifier).request(subject);
      return;
    }
    final repository = ref.read(onboardingRepositoryProvider);
    if (subject == PermissionSubject.photos && status == AccessStatus.limited) {
      await repository.managePhotos();
    } else {
      await repository.openSettings();
    }
    await ref.read(onboardingProvider.notifier).refresh();
  }
}
