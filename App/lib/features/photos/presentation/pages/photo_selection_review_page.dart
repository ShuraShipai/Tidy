import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_colors.dart';
import '../../../../core/design/tidy_radii.dart';
import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../../scan/controllers/scan_controller.dart';
import '../../controllers/photo_selection_controller.dart';
import '../../models/photo_format.dart';
import '../../services/photo_library_service.dart';
import '../../widgets/photo_page_top_bar.dart';
import '../../widgets/photo_delete_confirmation_sheet.dart';
import '../../widgets/photo_review_row.dart';
import '../../widgets/photo_no_selection_state.dart';
import '../../widgets/photo_review_unavailable_state.dart';

class PhotoSelectionReviewPage extends ConsumerStatefulWidget {
  const PhotoSelectionReviewPage({super.key});

  @override
  ConsumerState<PhotoSelectionReviewPage> createState() =>
      _PhotoSelectionReviewPageState();
}

class _PhotoSelectionReviewPageState
    extends ConsumerState<PhotoSelectionReviewPage> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(scanControllerProvider);
    final totals = ref.watch(selectedPhotoTotalsProvider);
    final hasItems = totals.count > 0;
    final sizeLabel = totals.unknownSizes == 0
        ? formatPhotoSize(totals.knownBytes)
        : '${formatPhotoSize(totals.knownBytes)} known · ${totals.unknownSizes} unknown';
    final authorized = [
      'authorized',
      'limited',
    ].contains(scan.permissions['photos']);

    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: TidySpacing.lg),
                child: PhotoPageTopBar(backLabel: 'Photos'),
              ),
              Expanded(
                child: !authorized || !scan.hasResults
                    ? const PhotoReviewUnavailableState()
                    : !hasItems
                    ? const PhotoNoSelectionState()
                    : CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              TidySpacing.lg,
                              TidySpacing.xs,
                              TidySpacing.lg,
                              TidySpacing.xl,
                            ),
                            sliver: SliverList.list(
                              children: [
                                Text(
                                  'Review Selected Photos',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),
                                const SizedBox(height: TidySpacing.sm),
                                Text(
                                  '${totals.count} photos · $sizeLabel estimated',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: TidySpacing.md),
                                for (final photo in totals.photos) ...[
                                  PhotoReviewRow(
                                    photo: photo,
                                    onPreview: () => context.push(
                                      '/photos/viewer?id=${Uri.encodeQueryComponent(photo.id)}&collection=similar',
                                    ),
                                    onRemove: () => ref
                                        .read(
                                          photoSelectionControllerProvider
                                              .notifier,
                                        )
                                        .select([photo.id], selected: false),
                                  ),
                                  const SizedBox(height: TidySpacing.md),
                                ],
                                const SizedBox(height: TidySpacing.sm),
                                Text(
                                  'Photos may remain in Recently Deleted. The size shown is an estimate, not guaranteed space returned to your iPhone.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              if (authorized && scan.hasResults && hasItems)
                DecoratedBox(
                  decoration: const BoxDecoration(color: TidyColors.background),
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(
                      TidySpacing.lg,
                      TidySpacing.sm,
                      TidySpacing.lg,
                      TidySpacing.xs,
                    ),
                    child: TidyActionButton(
                      label: _processing
                          ? 'Deleting Photos…'
                          : 'Review & Delete',
                      onPressed: _processing ? null : _confirmDelete,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final reviewed = Set<String>.unmodifiable(
      ref.read(selectedPhotoTotalsProvider).selectedIds,
    );
    if (reviewed.isEmpty || _processing) return;
    final count = reviewed.length;
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      barrierColor: TidyColors.sheetScrim,
      backgroundColor: TidyColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TidyRadii.card),
        ),
      ),
      builder: (_) => PhotoDeleteConfirmationSheet(count: count),
    );
    if (confirm != true || !mounted) return;
    if (!ref
            .read(photoSelectionControllerProvider)
            .selectedIds
            .containsAll(reviewed) ||
        ref.read(photoSelectionControllerProvider).selectedIds.length !=
            reviewed.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The selection changed. Review it again before deleting.',
          ),
        ),
      );
      return;
    }

    setState(() => _processing = true);
    try {
      final outcome = await ref
          .read(photoLibraryServiceProvider)
          .delete(reviewed);
      ref
          .read(photoSelectionControllerProvider.notifier)
          .removeDeleted(outcome.deletedIds);
      await ref
          .read(scanControllerProvider.notifier)
          .applyDeleted(outcome.deletedIds);
      if (!mounted) return;
      final deletedCount = outcome.deletedIds.length;
      final remainingCount = reviewed.length - deletedCount;
      final message = deletedCount == 0
          ? outcome.message ??
                'Photos did not confirm any deletions. Your selection is still available.'
          : remainingCount == 0
          ? '$deletedCount ${deletedCount == 1 ? 'photo' : 'photos'} moved to Recently Deleted.'
          : '$deletedCount removed. $remainingCount remain selected for review.';
      context.go('/photos');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ??
                'Photo access or the selection changed. Review again.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Photos could not be deleted. Your selection is still available.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }
}
