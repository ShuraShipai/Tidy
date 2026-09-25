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
        ],
      ),
    );
  }
}
