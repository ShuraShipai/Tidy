import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_colors.dart';
import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../../scan/controllers/scan_controller.dart';
import '../../controllers/photo_selection_controller.dart';
import '../../models/photo_group.dart';
import '../../repositories/photo_group_repository.dart';
import '../../widgets/photo_asset_thumbnail.dart';
import '../../widgets/photo_page_top_bar.dart';
import '../../widgets/photo_viewer_image.dart';

class PhotoComparisonPage extends ConsumerWidget {
  const PhotoComparisonPage({
    required this.anchorId,
    this.exactDuplicateOnly = false,
    super.key,
  });

  final String anchorId;
  final bool exactDuplicateOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanControllerProvider);
    final group = const PhotoGroupRepository().groupContaining(
      scan,
      anchorId,
      exactDuplicateOnly: exactDuplicateOnly,
    );
    if (group == null || !scan.hasResults) {
      return Scaffold(
        body: TidyPageBackground(
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: TidySpacing.lg),
                  child: PhotoPageTopBar(backLabel: 'Similar Photos'),
                ),
                const Expanded(
                  child: Center(
                    child: Text('This photo group is no longer available.'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final selection = ref.watch(photoSelectionControllerProvider);
    final controller = ref.read(photoSelectionControllerProvider.notifier);
    final keeperId = selection.keeperFor(group);

    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: TidySpacing.lg),
                child: PhotoPageTopBar(backLabel: 'Similar Photos'),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        TidySpacing.lg,
                        TidySpacing.xs,
                        TidySpacing.lg,
                        TidySpacing.md,
                      ),
                      sliver: SliverList.list(
                        children: [
                          Text(
                            _groupTitle(group),
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: TidySpacing.xs),
                          Text(
                            '${group.items.length} similar photos · compare the little details.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: TidySpacing.md),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: AspectRatio(
                              aspectRatio: 1.25,
                              child: PhotoViewerImage(assetId: keeperId),
                            ),
                          ),
                          const SizedBox(height: TidySpacing.md),
                          _SuggestedKeeperBadge(),
                          const SizedBox(height: TidySpacing.sm),
                          Text(
                            'Highest available resolution in this set. You can choose a different keeper.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: TidySpacing.md),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const gap = TidySpacing.sm;
                              final width =
                                  (constraints.maxWidth - gap * 2) / 3;
                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  for (final photo in group.items)
                                    SizedBox(
                                      width: width,
                                      child: PhotoAssetThumbnail(
                                        photo: photo,
                                        selected: selection.selectedIds
                                            .contains(photo.id),
                                        isKeeper: photo.id == keeperId,
                                        semanticContext:
                                            'Photo in comparison group',
                                        onPreview: () => context.push(
                                          '/photos/viewer?id=${Uri.encodeQueryComponent(photo.id)}&collection=similar',
                                        ),
                                        onChooseKeeper: () => controller
                                            .setKeeper(group, photo.id),
                                        onToggleSelection: () =>
                                            controller.toggle(photo.id),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
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
                      TidyActionButton(
                        label: 'Select All Except Best',
                        onPressed: () => controller.selectAllExceptBest(group),
                      ),
                      const SizedBox(height: TidySpacing.sm),
                      TidyActionButton(
                        label: 'Open Full Preview',
                        style: TidyActionStyle.secondary,
                        onPressed: () => context.push(
                          '/photos/viewer?id=${Uri.encodeQueryComponent(keeperId)}&collection=similar',
                        ),
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

  String _groupTitle(PhotoGroup group) => group.items.first.createdAt == null
      ? group.kind == PhotoGroupKind.exactDuplicate
            ? 'Duplicate Set'
            : 'Similar Set'
      : _dateRange(group);

  String _dateRange(PhotoGroup group) {
    final dates = group.items
        .map((item) => item.createdAt)
        .whereType<DateTime>()
        .toList();
    dates.sort();
    final first = dates.first;
    final last = dates.last;
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (first.year == last.year &&
        first.month == last.month &&
        first.day == last.day) {
      return '${first.day} ${monthNames[first.month - 1]} ${first.year}';
    }
    return '${first.day} ${monthNames[first.month - 1]} – ${last.day} ${monthNames[last.month - 1]}';
  }
}

class _SuggestedKeeperBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFD7F1E6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '✓ Suggested to Keep',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF14674A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}
