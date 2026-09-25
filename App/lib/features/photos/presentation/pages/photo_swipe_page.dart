import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_colors.dart';
import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../../scan/controllers/scan_controller.dart';
import '../../../scan/models/scan_state.dart';
import '../../controllers/photo_selection_controller.dart';
import '../../models/photo_format.dart';
import '../../models/photo_group.dart';
import '../../repositories/photo_group_repository.dart';
import '../../services/photo_library_service.dart';
import '../../widgets/photo_collection_state.dart';
import '../../widgets/photo_page_top_bar.dart';
import '../../widgets/photo_viewer_image.dart';

class PhotoSwipePage extends ConsumerStatefulWidget {
  const PhotoSwipePage({super.key});

  @override
  ConsumerState<PhotoSwipePage> createState() => _PhotoSwipePageState();
}

class _PhotoSwipePageState extends ConsumerState<PhotoSwipePage> {
  int _index = 0;
  final List<(String, bool)> _history = [];

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(scanControllerProvider);
    final permission =
        scan.permissions['photos'] ??
        ref.watch(photoPermissionProvider).asData?.value;
    final allowed = ['authorized', 'limited'].contains(permission);
    if (!allowed ||
        !scan.hasResults ||
        scan.running ||
        scan.phase == ScanPhase.stale) {
      return Scaffold(
        body: TidyPageBackground(
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: TidySpacing.lg),
                  child: PhotoPageTopBar(backLabel: 'Photos'),
                ),
                Expanded(
                  child: PhotoCollectionState(
                    kind: PhotoCollectionKind.similar,
                    scan: scan,
                    photoPermission: permission,
                    onScan: () {
                      if (!allowed) {
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
    final photos = const PhotoGroupRepository().photos(scan);
    final totals = ref.watch(selectedPhotoTotalsProvider);
    if (photos.isEmpty || _index >= photos.length) {
      return Scaffold(
        body: TidyPageBackground(
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: TidySpacing.lg),
                  child: PhotoPageTopBar(backLabel: 'Photos'),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(TidySpacing.lg),
                  child: Text(
                    photos.isEmpty
                        ? 'No photos are available to review.'
                        : 'You’ve reviewed every accessible photo.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const Spacer(),
                if (totals.count > 0)
                  Padding(
                    padding: const EdgeInsets.all(TidySpacing.lg),
                    child: TidyActionButton(
                      label: 'Review Selection',
                      onPressed: () => context.push('/photos/review'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    final photo = photos[_index];
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    TidySpacing.lg,
                    TidySpacing.xs,
                    TidySpacing.lg,
                    TidySpacing.md,
                  ),
                  children: [
                    Text(
                      'Swipe Clean',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: TidySpacing.xs),
                    Text(
                      'A little less clutter, one photo at a time.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: TidySpacing.md),
                    Row(
                      children: [
                        Text(
                          '${_index + 1} / ${photos.length}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: TidyColors.violetDeep,
                        ),
                        const SizedBox(width: TidySpacing.xs),
                        Text(
                          'Review before cleaning',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: TidySpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: AspectRatio(
                        aspectRatio: 0.92,
                        child: PhotoViewerImage(assetId: photo.id),
                      ),
                    ),
                    const SizedBox(height: TidySpacing.sm),
                    Text(
                      '${formatPhotoDate(photo.createdAt)} · ${photo.bytes == null ? 'Size unavailable' : formatPhotoSize(photo.bytes!)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TidyActionButton(
                              label: 'Clean',
                              style: TidyActionStyle.secondary,
                              onPressed: () => _advance(photo, selected: true),
                            ),
                          ),
                          const SizedBox(width: TidySpacing.md),
                          Expanded(
                            child: TidyActionButton(
                              label: 'Keep',
                              onPressed: () => _advance(photo, selected: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TidySpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _history.isEmpty ? null : _undo,
                            child: const Text('Undo'),
                          ),
                          TextButton(
                            onPressed: totals.count == 0
                                ? null
                                : () => context.push('/photos/review'),
                            child: const Text('Review Selection'),
                          ),
                        ],
                      ),
                      Text(
                        'Left selects for cleanup. Right keeps. Nothing is deleted here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _advance(MediaRecord photo, {required bool selected}) {
    final controller = ref.read(photoSelectionControllerProvider.notifier);
    final wasSelected = ref
        .read(photoSelectionControllerProvider)
        .selectedIds
        .contains(photo.id);
    _history.add((photo.id, wasSelected));
    controller.select([photo.id], selected: selected);
    setState(() => _index++);
  }

  void _undo() {
    if (_history.isEmpty) return;
    final (id, wasSelected) = _history.removeLast();
    ref.read(photoSelectionControllerProvider.notifier).select([
      id,
    ], selected: wasSelected);
    setState(() => _index = (_index - 1).clamp(0, 1 << 30));
  }
}
