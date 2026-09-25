import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_colors.dart';
import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../../scan/controllers/scan_controller.dart';
import '../../../scan/models/scan_state.dart';
import '../../controllers/photo_selection_controller.dart';
import '../../models/photo_group.dart';
import '../../repositories/photo_group_repository.dart';
import '../../services/photo_library_service.dart';
import '../../widgets/photo_analysis_note.dart';
import '../../widgets/photo_asset_thumbnail.dart';
import '../../widgets/photo_collection_state.dart';
import '../../widgets/photo_clean_empty_state.dart';
import '../../widgets/photo_collection_metrics.dart';
import '../../widgets/photo_limited_access_note.dart';
import '../../widgets/similar_photo_filter_bar.dart';
import '../../widgets/no_photo_groups_filter_state.dart';
import '../../widgets/blurry_analysis_incomplete_state.dart';
import '../../widgets/photo_group_card.dart';
import '../../widgets/photo_page_top_bar.dart';
import '../../widgets/photo_selection_bar.dart';
import '../../widgets/photo_screenshot_tile.dart';

class PhotoCollectionPage extends ConsumerStatefulWidget {
  const PhotoCollectionPage({required this.kind, super.key});

  final PhotoCollectionKind kind;

  @override
  ConsumerState<PhotoCollectionPage> createState() =>
      _PhotoCollectionPageState();
}

class _PhotoCollectionPageState extends ConsumerState<PhotoCollectionPage> {
  SimilarPhotoFilter _filter = SimilarPhotoFilter.all;
  _ScreenshotSort _sort = _ScreenshotSort.largest;

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(scanControllerProvider);
    final currentPermission = ref.watch(photoPermissionProvider).asData?.value;
    final selection = ref.watch(photoSelectionControllerProvider);
    final totals = ref.watch(selectedPhotoTotalsProvider);
    final repository = const PhotoGroupRepository();
    final permission = scan.permissions['photos'] ?? currentPermission;
    final accessible = ['authorized', 'limited'].contains(permission);

    if (!accessible ||
        !scan.hasResults ||
        (scan.phase == ScanPhase.error && !scan.hasResults) ||
        scan.phase == ScanPhase.stale ||
        scan.running) {
      return _statusPage(context, scan, accessible, permission);
    }

    final allPhotos = repository.collection(scan, widget.kind);
    if (allPhotos.isEmpty) {
      if (widget.kind == PhotoCollectionKind.blurry &&
          repository.getBlurryAnalysisIncomplete(scan)) {
        return const BlurryAnalysisIncompleteState();
      }
      return Scaffold(
        body: TidyPageBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TidySpacing.lg,
                  ),
                  child: PhotoPageTopBar(backLabel: 'Photos'),
                ),
                Expanded(child: PhotoCleanEmptyState(kind: widget.kind)),
              ],
            ),
          ),
        ),
      );
    }

    final visibleGroups = widget.kind == PhotoCollectionKind.similar
        ? repository.groupsForFilter(scan, _filter)
        : const <PhotoGroup>[];
    // The thumbnail grid below is shared by screenshot and blurry collections.
    // Keep both collections' discovered items in that grid.
    final sortedPhotos = widget.kind == PhotoCollectionKind.similar
        ? const <MediaRecord>[]
        : _sortPhotos(allPhotos);
    final contentCount = allPhotos.length;
    final contentBytes = _size(allPhotos);
    final contentIds = allPhotos.map((item) => item.id).toSet();
    final selectionController = ref.read(
      photoSelectionControllerProvider.notifier,
    );
    final allSelected =
        contentIds.isNotEmpty &&
        contentIds.every(selection.selectedIds.contains);

    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TidySpacing.lg),
                child: PhotoPageTopBar(
                  backLabel: 'Photos',
                  actionLabel: widget.kind == PhotoCollectionKind.similar
                      ? 'Deselect All'
                      : null,
                  onAction: widget.kind == PhotoCollectionKind.similar
                      ? () => selectionController.select(
                          contentIds,
                          selected: false,
                        )
                      : null,
                ),
              ),
              Expanded(
                child: CustomScrollView(
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
                            _heading,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          if (widget.kind == PhotoCollectionKind.blurry) ...[
                            const SizedBox(height: TidySpacing.xs),
                            Text(
                              'Some shots may be soft. You decide what stays.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                          const SizedBox(height: TidySpacing.lg),
                          PhotoCollectionMetrics(
                            count: contentCount,
                            bytes: contentBytes,
                          ),
                          if (widget.kind == PhotoCollectionKind.blurry &&
                              repository.getBlurryAnalysisIncomplete(scan))
                            const PhotoAnalysisNote(
                              text:
                                  'Some photos could not be analyzed. This list may not include every blurry photo.',
                            ),
                          if (permission == 'limited') ...[
                            const SizedBox(height: TidySpacing.md),
                            const PhotoLimitedAccessNote(),
                          ],
                          if (widget.kind == PhotoCollectionKind.similar) ...[
                            const SizedBox(height: TidySpacing.md),
                            SimilarPhotoFilterBar(
                              selected: _filter,
                              onChanged: (value) =>
                                  setState(() => _filter = value),
                            ),
                            const SizedBox(height: TidySpacing.lg),
                            if (visibleGroups.isEmpty)
                              NoPhotoGroupsFilterState(filter: _filter)
                            else
                              for (final group in visibleGroups) ...[
                                PhotoGroupCard(
                                  group: group,
                                  selectedIds: selection.selectedIds,
                                  keeperId: selection.keeperFor(group),
                                  onChooseKeeper: null,
                                  onPreview: (id) => context.push(
                                    '/photos/viewer?id=${Uri.encodeQueryComponent(id)}&collection=similar',
                                  ),
                                  onToggle: selectionController.toggle,
                                  onSelectAllExceptBest: () =>
                                      selectionController.selectAllExceptBest(
                                        group,
                                      ),
                                  onCompare: () => context.push(
                                    '/photos/similar/group?photo=${Uri.encodeQueryComponent(group.anchorId)}&kind=${group.kind.name}',
                                  ),
                                ),
                                const SizedBox(height: TidySpacing.md),
                              ],
                          ] else ...[
                            const SizedBox(height: TidySpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => selectionController.select(
                                    contentIds,
                                    selected: !allSelected,
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: TidyColors.primary,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(44, 44),
                                  ),
                                  child: Text(
                                    allSelected ? 'Deselect All' : 'Select All',
                                  ),
                                ),
                                PopupMenuButton<_ScreenshotSort>(
                                  initialValue: _sort,
                                  onSelected: (value) =>
                                      setState(() => _sort = value),
                                  itemBuilder: (context) => [
                                    for (final value in _ScreenshotSort.values)
                                      PopupMenuItem(
                                        value: value,
                                        child: Text(value.label),
                                      ),
                                  ],
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      'Sort: ${_sort.label} ↓',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: TidyColors.primary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: TidySpacing.xs),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                const gap = TidySpacing.sm;
                                final width =
                                    (constraints.maxWidth - gap * 2) / 3;
                                return Wrap(
                                  spacing: gap,
                                  runSpacing: gap,
                                  children: [
                                    for (final photo in sortedPhotos)
                                      SizedBox(
                                        width: width,
                                        child:
                                            widget.kind ==
                                                PhotoCollectionKind.screenshots
                                            ? PhotoScreenshotTile(
                                                photo: photo,
                                                selected: selection.selectedIds
                                                    .contains(photo.id),
                                                onPreview: () => context.push(
                                                  '/photos/viewer?id=${Uri.encodeQueryComponent(photo.id)}&collection=${widget.kind.name}',
                                                ),
                                                onToggle: () =>
                                                    selectionController.toggle(
                                                      photo.id,
                                                    ),
                                              )
                                            : PhotoAssetThumbnail(
                                                photo: photo,
                                                selected: selection.selectedIds
                                                    .contains(photo.id),
                                                semanticContext:
                                                    'Possibly blurry photo',
                                                onPreview: () => context.push(
                                                  '/photos/viewer?id=${Uri.encodeQueryComponent(photo.id)}&collection=${widget.kind.name}',
                                                ),
                                                onToggleSelection: () =>
                                                    selectionController.toggle(
                                                      photo.id,
                                                    ),
                                              ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PhotoSelectionBar(
                totals: totals,
                actionLabel: widget.kind == PhotoCollectionKind.similar
                    ? 'Review Selected Photos'
                    : 'Review Selection',
                onReview: () => context.push('/photos/review'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPage(
    BuildContext context,
    ScanState scan,
    bool accessible,
    String? permission,
  ) {
    if (scan.running) {
      return Scaffold(
        body: TidyPageBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(TidySpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhotoPageTopBar(backLabel: 'Photos'),
                  const SizedBox(height: TidySpacing.xl),
                  Text(
                    'Scanning your iPhone',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: TidySpacing.sm),
                  Text(
                    'Looking for photos you may not need…',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Spacer(),
                  const Center(child: CircularProgressIndicator()),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: () =>
                        ref.read(scanControllerProvider.notifier).cancel(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TidySpacing.lg),
                child: PhotoPageTopBar(backLabel: 'Photos'),
              ),
              Expanded(
                child: PhotoCollectionState(
                  kind: widget.kind,
                  scan: scan,
                  photoPermission: permission,
                  onScan: () {
                    if (!accessible) {
                      context.push('/onboarding/photos');
                    } else {
                      ref.read(scanControllerProvider.notifier).start();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _heading => switch (widget.kind) {
    PhotoCollectionKind.similar => 'Similar Photos',
    PhotoCollectionKind.screenshots => 'Screenshots',
    PhotoCollectionKind.blurry => 'Possibly Blurry',
  };

  List<MediaRecord> _sortPhotos(List<MediaRecord> photos) {
    final sorted = [...photos];
    sorted.sort((left, right) {
      switch (_sort) {
        case _ScreenshotSort.largest:
          if (left.bytes == null && right.bytes != null) return 1;
          if (left.bytes != null && right.bytes == null) return -1;
          return (right.bytes ?? 0).compareTo(left.bytes ?? 0);
        case _ScreenshotSort.newest:
          if (left.createdAt == null && right.createdAt != null) return 1;
          if (left.createdAt != null && right.createdAt == null) return -1;
          if (left.createdAt == null || right.createdAt == null) return 0;
          return right.createdAt!.compareTo(left.createdAt!);
        case _ScreenshotSort.oldest:
          if (left.createdAt == null && right.createdAt != null) return 1;
          if (left.createdAt != null && right.createdAt == null) return -1;
          if (left.createdAt == null || right.createdAt == null) return 0;
          return left.createdAt!.compareTo(right.createdAt!);
      }
    });
    return sorted;
  }

  int? _size(List<MediaRecord> items) {
    if (items.any((item) => item.bytes == null)) return null;
    return items.fold<int>(0, (sum, item) => sum + item.bytes!);
  }
}

enum _ScreenshotSort {
  largest('largest'),
  newest('newest'),
  oldest('oldest');

  const _ScreenshotSort(this.label);
  final String label;
}
