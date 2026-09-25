import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_glyph.dart';
import '../../../../core/widgets/tidy_orb.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../../../core/widgets/tidy_safety_note.dart';
import '../../../scan/controllers/scan_controller.dart';
import '../../../scan/models/scan_state.dart';
import '../../controllers/photo_selection_controller.dart';
import '../../models/photo_format.dart';
import '../../repositories/photo_group_repository.dart';
import '../../widgets/photo_overview_card.dart';

class PhotosOverviewPage extends ConsumerWidget {
  const PhotosOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanControllerProvider);
    final repository = const PhotoGroupRepository();
    final similarPhotos = repository.uniqueSimilarPhotos(scan);
    final screenshots = repository.screenshots(scan);
    final blurryPhotos = repository.blurryPhotos(scan);
    final blurryIncomplete = repository.getBlurryAnalysisIncomplete(scan);
    ref.listen(scanControllerProvider, (previous, next) {
      if (next.hasResults) {
        final accessible =
            next.permissions['photos'] == 'authorized' ||
                next.permissions['photos'] == 'limited'
            ? next.media
                  .where((item) => !item.video)
                  .map((item) => item.id)
                  .toSet()
            : <String>{};
        ref
            .read(photoSelectionControllerProvider.notifier)
            .reconcile(accessible);
      }
    });

    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              TidySpacing.lg,
              TidySpacing.xl,
              TidySpacing.lg,
              TidySpacing.lg,
            ),
            children: [
              Text('Photos', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: TidySpacing.xs),
              Text(
                'A place for the moments worth keeping.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: TidySpacing.lg),
              PhotoOverviewCard(
                title: 'Similar Photos',
                detail: _measurement(similarPhotos, scan),
                glyph: TidyGlyphName.photo,
                tone: TidyOrbTone.violet,
                onTap: () => context.push('/photos/similar'),
              ),
              const SizedBox(height: TidySpacing.md),
              PhotoOverviewCard(
                title: 'Screenshots',
                detail: _measurement(screenshots, scan),
                glyph: TidyGlyphName.photo,
                tone: TidyOrbTone.sky,
                onTap: () => context.push('/photos/screenshots'),
              ),
              const SizedBox(height: TidySpacing.md),
              PhotoOverviewCard(
                title: 'Possibly Blurry',
                detail: !scan.hasResults
                    ? _measurement(blurryPhotos, scan)
                    : ![
                        'authorized',
                        'limited',
                      ].contains(scan.permissions['photos'])
                    ? 'Access needed'
                    : blurryIncomplete
                    ? '${blurryPhotos.length} possible · some photos unchecked'
                    : _measurement(blurryPhotos, scan),
                glyph: TidyGlyphName.photo,
                tone: TidyOrbTone.amber,
                onTap: () => context.push('/photos/blurry'),
              ),
              const SizedBox(height: TidySpacing.md),
              PhotoOverviewCard(
                title: 'Swipe Clean',
                detail: 'One photo. One easy decision.',
                glyph: TidyGlyphName.spark,
                tone: TidyOrbTone.pink,
                onTap: () => context.push('/photos/swipe'),
              ),
              const SizedBox(height: TidySpacing.md),
              const TidySafetyNote(
                text:
                    'Your favorites are yours to choose. Nothing is selected automatically.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _measurement(List<MediaRecord> records, ScanState scan) {
    if (!scan.hasResults) {
      if (scan.running) {
        return scan.processed != null && scan.total != null
            ? '${scan.processed} of ${scan.total} checked'
            : 'Scanning…';
      }
      return 'Not scanned';
    }
    if (!['authorized', 'limited'].contains(scan.permissions['photos'])) {
      return 'Access needed';
    }
    final bytes = records.fold<int?>(0, (sum, item) {
      if (sum == null || item.bytes == null) return null;
      return sum + item.bytes!;
    });
    return '${records.length} photos · ${bytes == null ? 'Size unavailable' : formatPhotoSize(bytes)}';
  }
}
