import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_sizes.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';
import '../../../core/widgets/tidy_glyph.dart';
import '../../../core/widgets/tidy_orb.dart';
import '../../scan/models/scan_state.dart';
import '../models/photo_group.dart';

class PhotoCollectionState extends StatelessWidget {
  const PhotoCollectionState({
    required this.kind,
    required this.scan,
    required this.onScan,
    required this.photoPermission,
    super.key,
  });

  final PhotoCollectionKind kind;
  final ScanState scan;
  final VoidCallback onScan;
  final String? photoPermission;

  @override
  Widget build(BuildContext context) {
    final status = photoPermission ?? scan.permissions['photos'];
    final denied =
        ['denied', 'restricted'].contains(status) ||
        scan.phase == ScanPhase.permissionDenied;
    final notScanned =
        !scan.hasResults &&
        ![
          ScanPhase.error,
          ScanPhase.stale,
          ScanPhase.cancelled,
        ].contains(scan.phase);
    final title = denied
        ? 'Photo Access Is Off'
        : scan.phase == ScanPhase.error
        ? 'Photos couldn’t be scanned'
        : kind == PhotoCollectionKind.screenshots
        ? 'Review your screenshots'
        : 'Find similar photos';
    final message = denied
        ? 'Allow Photos access in Settings to review your library.'
        : scan.phase == ScanPhase.error
        ? scan.message ?? 'Check access, then try scanning again.'
        : notScanned
        ? 'Scan your accessible photos to find items you can review.'
        : 'Your scan needs an update before these photos can be reviewed.';
    final action = denied ? 'Manage Photo Access' : 'Scan Library';
    final actionCallback = denied
        ? () => context.push('/onboarding/photos')
        : onScan;
    final glyph = kind == PhotoCollectionKind.screenshots
        ? TidyGlyphName.photo
        : TidyGlyphName.photo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TidySpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TidyOrb(
            glyph: glyph,
            tone: denied ? TidyOrbTone.pink : TidyOrbTone.violet,
            size: TidySizes.illustrationOrb,
          ),
          const SizedBox(height: TidySpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: TidySpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: TidyColors.secondaryText),
          ),
          const SizedBox(height: TidySpacing.xl),
          TidyActionButton(label: action, onPressed: actionCallback),
          if (scan.phase == ScanPhase.error) ...[
            const SizedBox(height: TidySpacing.xs),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to Home'),
            ),
          ],
        ],
      ),
    );
  }
}

class PhotoCleanEmptyState extends StatelessWidget {
  const PhotoCleanEmptyState({required this.kind, super.key});

  final PhotoCollectionKind kind;

  @override
  Widget build(BuildContext context) {
    final screenshot = kind == PhotoCollectionKind.screenshots;
    final blurry = kind == PhotoCollectionKind.blurry;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TidySpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TidyOrb(
            glyph: TidyGlyphName.photo,
            tone: screenshot
                ? TidyOrbTone.sky
                : blurry
                ? TidyOrbTone.amber
                : TidyOrbTone.violet,
            size: TidySizes.illustrationOrb,
          ),
          const SizedBox(height: TidySpacing.xl),
          Text(
            screenshot
                ? 'No screenshots to clean'
                : blurry
                ? 'No possibly blurry photos'
                : 'Every shot is its own.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: TidySpacing.sm),
          Text(
            screenshot
                ? 'You’re all caught up here.'
                : blurry
                ? 'No photos were flagged by the on-device blur check.'
                : 'No similar photos to review. Your memories have room to be themselves.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: TidyColors.secondaryText),
          ),
          const SizedBox(height: TidySpacing.xl),
          TidyActionButton(
            label: 'Back to Home',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}

class PhotoLimitedAccessNote extends StatelessWidget {
  const PhotoLimitedAccessNote({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TidySpacing.sm),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 17, color: TidyColors.violetDeep),
        const SizedBox(width: TidySpacing.xs),
        Expanded(
          child: Text(
            'Limited access · only selected photos are shown.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    ),
  );
}
