import 'package:flutter/material.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../scan/models/scan_state.dart';

class ScanStatusNote extends StatelessWidget {
  const ScanStatusNote({required this.state, super.key});
  final ScanState state;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (state.phase == ScanPhase.cancelled)
        const Text('Scan cancelled. Start again when you’re ready.'),
      if (state.phase == ScanPhase.stale)
        const Text(
          'Your library or access changed. Scan again to refresh results.',
        ),
      if (state.message != null) Text(state.message!),
      if (state.storageError != null) Text(state.storageError!),
      if (state.stage == 'media' &&
          state.running &&
          state.processed != null &&
          state.total != null)
        Text(
          '${state.processed} of ${state.total} accessible media items checked. Contacts follow.',
        ),
      if (state.stage == 'contacts' && state.running)
        const Text('Checking accessible contacts…'),
      for (final entry in state.permissions.entries)
        if (entry.value != 'authorized')
          Text(
            '${entry.key == 'photos' ? 'Photos' : 'Contacts'} access: ${entry.value == 'notDetermined' ? 'not requested' : entry.value}. Only accessible items are checked.',
          ),
      if (state.hasResults) ...[
        if (state.completedAt != null)
          Text(
            'Last scanned: ${MaterialLocalizations.of(context).formatMediumDate(state.completedAt!)} at ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(state.completedAt!))}',
          ),
        const SizedBox(height: TidySpacing.sm),
        Text(
          '${state.reviewableIds.length} media candidates · ${(state.knownReviewableBytes / 1000000000).toStringAsFixed(2)} GB known primary-resource bytes${state.unknownReviewableSizes > 0 ? ' plus ${state.unknownReviewableSizes} unknown sizes' : ''}. This is not total asset storage or a promise of freed space.',
        ),
        Text(
          '${state.contacts.length} possible contact groups in ${state.contactCount} accessible contacts.',
        ),
        if (state.incomplete)
          Text(
            'Some items could not be fully checked: ${state.unavailableSizes} unknown media sizes; ${state.unavailableImages} unavailable photo comparisons. Nothing was downloaded from iCloud.',
          ),
        const Text(
          'Similar-photo suggestions compare up to 30 preceding photos taken within 60 seconds. Large videos are 100 MiB or larger. No exact-duplicate claim is made.',
        ),
      ],
    ],
  );
}
