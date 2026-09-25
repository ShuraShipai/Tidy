import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../services/group_eight_service.dart';
import '../../widgets/bonus_page_frame.dart';

class CleanupHistoryPage extends ConsumerStatefulWidget {
  const CleanupHistoryPage({super.key});

  @override
  ConsumerState<CleanupHistoryPage> createState() => _CleanupHistoryPageState();
}

class _CleanupHistoryPageState extends ConsumerState<CleanupHistoryPage> {
  late Future<List<Map<String, Object?>>> _history;

  @override
  void initState() {
    super.initState();
    _history = ref.read(groupEightServiceProvider).history();
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, Object?>>>(
    future: _history,
    builder: (context, snapshot) {
      final rows = snapshot.data ?? const <Map<String, Object?>>[];
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      final thisWeek = rows
          .where((row) {
            final date = DateTime.fromMillisecondsSinceEpoch(
              ((row['date'] as num?) ?? 0).round(),
            );
            return date.isAfter(cutoff);
          })
          .toList(growable: false);
      final bytes = thisWeek.fold<int>(
        0,
        (sum, row) => sum + (((row['bytes'] as num?) ?? 0).toInt()),
      );
      final hasUnknownSize = thisWeek.any(
        (row) => row['bytes'] == null && row['category'] != 'Calendar',
      );
      final categories = <String, int?>{};
      for (final row in thisWeek) {
        final category = row['category'] as String? ?? 'Other';
        final itemBytes = (row['bytes'] as num?)?.toInt();
        categories.update(
          category,
          (value) =>
              value == null || itemBytes == null ? null : value + itemBytes,
          ifAbsent: () => itemBytes,
        );
      }
      return BonusPageFrame(
        title: 'A little more room.',
        subtitle: 'Completed optional actions saved on this iPhone.',
        backLabel: 'Optional Features',
        child: snapshot.connectionState == ConnectionState.waiting
            ? const Center(child: CircularProgressIndicator())
            : snapshot.hasError
            ? Text('Cleanup history could not be read: ${snapshot.error}')
            : rows.isEmpty
            ? const _EmptyHistory()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(TidySpacing.lg),
                      child: Column(
                        children: [
                          const Text('Past 7 days'),
                          const SizedBox(height: TidySpacing.sm),
                          Text(
                            hasUnknownSize
                                ? 'Some sizes unavailable'
                                : _size(bytes),
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const Text(
                            'Estimated space associated with completed removals',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: TidySpacing.md),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(TidySpacing.md),
                      child: Column(
                        children: [
                          for (final entry in categories.entries)
                            ListTile(
                              title: Text(entry.key),
                              trailing: Text(
                                entry.value == null
                                    ? 'Size unavailable'
                                    : entry.value == 0
                                    ? 'No storage measurement'
                                    : _size(entry.value!),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: TidySpacing.lg),
                  Text(
                    'Recent actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: TidySpacing.sm),
                  for (final row in rows)
                    Card(
                      child: ListTile(
                        title: Text(
                          row['description'] as String? ??
                              row['category'] as String? ??
                              'Completed action',
                        ),
                        subtitle: Text(
                          '${_date(((row['date'] as num?) ?? 0).round())} · ${(row['count'] as num?)?.toInt() ?? 0} items',
                        ),
                        trailing: Text(
                          row['bytes'] == null
                              ? 'Size unavailable'
                              : (row['bytes'] as num).toInt() == 0
                              ? '—'
                              : _size((row['bytes'] as num).toInt()),
                        ),
                      ),
                    ),
                  const SizedBox(height: TidySpacing.md),
                  const Text(
                    'History records successful confirmed actions only. It stays in this app on this iPhone.',
                  ),
                ],
              ),
      );
    },
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TidySpacing.xl),
    child: Column(
      children: [
        const Icon(Icons.history, size: 56),
        const SizedBox(height: TidySpacing.md),
        Text(
          'No completed actions yet',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: TidySpacing.xs),
        const Text(
          'Successful, confirmed Group 08 actions will appear here. Nothing is estimated or filled in before it happens.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

String _size(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}

String _date(int milliseconds) {
  final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  return '${date.day}/${date.month}/${date.year}';
}
