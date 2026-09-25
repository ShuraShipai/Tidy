import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../../core/widgets/tidy_back_button.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../../scan/controllers/scan_controller.dart';
import '../../controllers/cleanup_controller.dart';
import '../../models/cleanup_plan.dart';
import '../../widgets/cleanup_category_row.dart';
import '../../widgets/cleanup_confirmation_sheet.dart';
import '../../widgets/cleanup_empty_selection_state.dart';
import '../../widgets/cleanup_photo_preview.dart';
import '../../widgets/cleanup_unavailable_state.dart';

class CleanupReviewPage extends ConsumerWidget {
  const CleanupReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanControllerProvider);
    final plan = ref.watch(cleanupPlanProvider);
    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TidySpacing.lg,
                  TidySpacing.md,
                  TidySpacing.lg,
                  0,
                ),
                child: Row(
                  children: [
                    TidyBackButton(
                      onPressed: () => context.pop(),
                      tooltip: 'Back',
                    ),
                    Expanded(
                      child: Text(
                        'Review Cleanup',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: !scan.hasResults
                    ? const CleanupUnavailableState()
                    : plan.isEmpty
                    ? const CleanupEmptySelectionState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          TidySpacing.lg,
                          TidySpacing.md,
                          TidySpacing.lg,
                          TidySpacing.xl,
                        ),
                        children: [
                          Text(
                            'Ready to clean',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: TidySpacing.xs),
                          Text(
                            'Only items you selected are included. Review each group before continuing.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: TidySpacing.lg),
                          for (final category in CleanupCategory.values)
                            if (plan.forCategory(category).isNotEmpty)
                              CleanupCategoryRow(
                                category: category,
                                count: plan.forCategory(category).length,
                                sizeText: _categorySize(
                                  plan.forCategory(category),
                                ),
                                onEdit: () => context.push(switch (category) {
                                  CleanupCategory.similarPhotos =>
                                    '/photos/similar',
                                  CleanupCategory.screenshots =>
                                    '/photos/screenshots',
                                  CleanupCategory.possiblyBlurry =>
                                    '/photos/blurry',
                                  CleanupCategory.selectedPhotos =>
                                    '/photos/swipe',
                                  CleanupCategory.largeVideos => '/videos',
                                  CleanupCategory.duplicateContacts =>
                                    '/contacts',
                                }),
                              ),
                          if (plan.entries.any(
                            (entry) => entry.media != null,
                          )) ...[
                            const SizedBox(height: TidySpacing.md),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final entry
                                    in plan.entries
                                        .where((entry) => entry.media != null)
                                        .take(12))
                                  CleanupPhotoPreview(photo: entry.media!),
                              ],
                            ),
                          ],
                          const SizedBox(height: TidySpacing.lg),
                          Text(
                            _estimate(plan),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
              ),
              if (scan.hasResults && !plan.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TidySpacing.lg,
                    TidySpacing.sm,
                    TidySpacing.lg,
                    TidySpacing.md,
                  ),
                  child: TidyActionButton(
                    label: 'Clean ${plan.itemCount} Items',
                    onPressed: () => _confirm(context, ref, plan),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    CleanupPlan plan,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => CleanupConfirmationSheet(
          count: plan.itemCount,
          sizeEstimate: _estimate(plan),
          photosMayRetainItems: plan.entries.any(
            (entry) => entry.media != null,
          ),
          scrollController: scrollController,
        ),
      ),
    );
    if (!context.mounted || confirmed != true) return;
    context.go('/cleanup/progress', extra: plan);
  }

  static String _categorySize(List<CleanupEntry> entries) {
    if (entries.every((entry) => entry.media == null)) return '';
    final bytes = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.media?.bytes ?? 0),
    );
    final known = entries.where((entry) => entry.media?.bytes != null).length;
    return known == 0 ? 'size unavailable' : _size(bytes);
  }

  static String _estimate(CleanupPlan plan) {
    final mediaCount = plan.entries
        .where((entry) => entry.media != null)
        .length;
    final contactsCount = plan.entries
        .where((entry) => entry.contact != null)
        .length;
    if (mediaCount == 0) {
      return 'Storage size unavailable for selected contacts';
    }
    final knownCount = mediaCount - plan.unknownMediaSizes;
    final known = knownCount == 0
        ? 'No measurable media size'
        : 'Known media size: ${_size(plan.knownBytes)}';
    final unknown = plan.unknownMediaSizes == 0
        ? ''
        : ' · ${plan.unknownMediaSizes} unknown sizes';
    final contacts = contactsCount == 0
        ? ''
        : ' · contact storage is not measurable';
    return '$known$unknown$contacts';
  }

  static String _size(int bytes) => bytes >= 1000000000
      ? '${(bytes / 1000000000).toStringAsFixed(1)} GB'
      : bytes >= 1000000
      ? '${(bytes / 1000000).round()} MB'
      : '${(bytes / 1000).round()} KB';
}
