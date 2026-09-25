import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../../core/widgets/tidy_glyph.dart';
import '../../../scan/controllers/scan_controller.dart';
import '../../../scan/models/scan_state.dart';
import '../../controllers/photo_selection_controller.dart';
import '../../models/photo_format.dart';
import '../../models/photo_group.dart';
import '../../repositories/photo_group_repository.dart';
import '../../widgets/photo_viewer_image.dart';

class PhotoViewerPage extends ConsumerWidget {
  const PhotoViewerPage({
    required this.assetId,
    required this.collection,
    super.key,
  });

  final String assetId;
  final String collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanControllerProvider);
    final photo = scan.media
        .where((item) => item.id == assetId && !item.video)
        .firstOrNull;
    if (photo == null || !scan.hasResults) {
      return _unavailable(context);
    }
    final repository = const PhotoGroupRepository();
    final photos = repository.collection(
      scan,
      collection == 'screenshots'
          ? PhotoCollectionKind.screenshots
          : PhotoCollectionKind.similar,
    );
    final index = photos.indexWhere((item) => item.id == assetId);
    final group = repository.groupContaining(scan, assetId);
    final selection = ref.watch(photoSelectionControllerProvider);
    final controller = ref.read(photoSelectionControllerProvider.notifier);
    final isSelected = selection.selectedIds.contains(assetId);
    final isKeeper = group != null && selection.keeperFor(group) == assetId;

    return Scaffold(
      backgroundColor: const Color(0xFF211E27),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TidySpacing.md),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _goBack(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                    ),
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Back'),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _goBack(context),
                    tooltip: 'Close preview',
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 6,
              child: SizedBox.expand(child: PhotoViewerImage(assetId: assetId)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TidySpacing.lg,
                TidySpacing.md,
                TidySpacing.lg,
                TidySpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: index > 0
                            ? () => _show(context, photos[index - 1])
                            : null,
                        tooltip: 'Previous photo',
                        color: Colors.white,
                        disabledColor: Colors.white24,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      const Spacer(),
                      if (isKeeper)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7F1E6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Text(
                              '✓ Suggested to Keep',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: const Color(0xFF14674A),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        onPressed: index >= 0 && index + 1 < photos.length
                            ? () => _show(context, photos[index + 1])
                            : null,
                        tooltip: 'Next photo',
                        color: Colors.white,
                        disabledColor: Colors.white24,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  Text(
                    'Photo',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(color: Colors.white),
                  ),
                  if (group != null) ...[
                    const SizedBox(height: TidySpacing.xs),
                    Text(
                      'Highest available resolution in this set. You can choose a different keeper.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: TidySpacing.md),
                  Row(
                    children: [
                      _PhotoInfo(
                        label: 'Date',
                        value: formatPhotoDate(photo.createdAt),
                      ),
                      _PhotoInfo(
                        label: 'Resolution',
                        value: '${photo.width} × ${photo.height}',
                      ),
                      _PhotoInfo(
                        label: 'File size',
                        value: photo.bytes == null
                            ? 'Unavailable'
                            : formatPhotoSize(photo.bytes!),
                      ),
                    ],
                  ),
                  const SizedBox(height: TidySpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TidyActionButton(
                          label: 'Keep',
                          style: TidyActionStyle.secondary,
                          onPressed: () {
                            controller.select([assetId], selected: false);
                            _goBack(context);
                          },
                        ),
                      ),
                      const SizedBox(width: TidySpacing.md),
                      Expanded(
                        child: TidyActionButton(
                          label: isSelected
                              ? 'Selected for Cleanup'
                              : 'Select for Cleanup',
                          onPressed: () {
                            controller.toggle(assetId);
                            _goBack(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unavailable(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF211E27),
    body: SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _goBack(context),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Back'),
            ),
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TidyGlyph(
                    TidyGlyphName.photo,
                    size: 42,
                    color: Colors.white54,
                  ),
                  SizedBox(height: TidySpacing.md),
                  Text(
                    'This photo is no longer available.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _show(BuildContext context, MediaRecord photo) {
    context.go(
      '/photos/viewer?id=${Uri.encodeQueryComponent(photo.id)}&collection=$collection',
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(_collectionPath);
  }

  String get _collectionPath => switch (collection) {
    'screenshots' => '/photos/screenshots',
    'blurry' => '/photos/blurry',
    _ => '/photos/similar',
  };
}

class _PhotoInfo extends StatelessWidget {
  const _PhotoInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: TidySpacing.xs),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: Colors.white),
        ),
      ],
    ),
  );
}
