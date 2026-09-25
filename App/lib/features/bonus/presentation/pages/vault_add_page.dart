import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../photos/widgets/photo_asset_thumbnail.dart';
import '../../../scan/controllers/scan_controller.dart';
import '../../../scan/models/scan_state.dart';
import '../../services/group_eight_service.dart';
import '../../widgets/bonus_page_frame.dart';

class VaultAddPage extends ConsumerStatefulWidget {
  const VaultAddPage({super.key});

  @override
  ConsumerState<VaultAddPage> createState() => _VaultAddPageState();
}

class _VaultAddPageState extends ConsumerState<VaultAddPage> {
  final Set<String> _selected = {};
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final scan = ref
        .watch(
          scanControllerProvider.select((state) => _VaultScanViewState(state)),
        )
        .state;
    final permission = scan.permissions['photos'];
    final photos =
        scan.hasResults && const ['authorized', 'limited'].contains(permission)
        ? scan.media.where((record) => !record.video).toList(growable: false)
        : const <MediaRecord>[];
    if (photos.isEmpty) return _empty(scan, permission);
    return BonusPageFrame(
      title: 'Choose private items',
      subtitle: 'Adding encrypted copies leaves the originals in Photos.',
      backLabel: 'Vault',
      slivers: [
        if (permission == 'limited')
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: TidySpacing.lg),
              child: Text(
                'Limited Photos access · only selected library items are available.',
              ),
            ),
          ),
        if (_error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: TidySpacing.lg),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: TidySpacing.lg),
          sliver: SliverGrid.builder(
            itemCount: photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: TidySpacing.sm,
              mainAxisSpacing: TidySpacing.sm,
            ),
            itemBuilder: (context, index) {
              final photo = photos[index];
              final selected = _selected.contains(photo.id);
              return Semantics(
                label:
                    'Photo ${index + 1}, ${selected ? 'selected for Vault copy' : 'not selected'}',
                child: PhotoAssetThumbnail(
                  photo: photo,
                  selected: selected,
                  semanticContext: 'Photo for private Vault',
                  onPreview: () => context.push(
                    '/photos/viewer?id=${Uri.encodeQueryComponent(photo.id)}&collection=similar',
                  ),
                  onToggleSelection: () => setState(() {
                    if (!_selected.add(photo.id)) _selected.remove(photo.id);
                  }),
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              TidySpacing.lg,
              TidySpacing.md,
              TidySpacing.lg,
              TidySpacing.xs,
            ),
            child: Text(
              'Vault and cleanup selections stay separate. Items unavailable locally cannot be copied.',
            ),
          ),
        ),
        if (_busy)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(TidySpacing.md),
              child: LinearProgressIndicator(),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: TidySpacing.lg)),
      ],
      footer: TidyActionButton(
        label: _selected.isEmpty
            ? 'Select Items'
            : 'Add ${_selected.length} Selected Copies',
        onPressed: _selected.isEmpty || _busy
            ? null
            : () => _add(_selected.toList(growable: false)),
      ),
    );
  }

  Widget _empty(ScanState scan, String? permission) {
    final needsAccess = !const ['authorized', 'limited'].contains(permission);
    final hasResults = scan.hasResults;
    return BonusPageFrame(
      title: needsAccess ? 'Photos access needed' : 'Choose private items',
      subtitle: needsAccess
          ? 'Allow Photos access in Settings before copying library items into your Vault.'
          : 'Use the shared library scan to discover photos available to review.',
      backLabel: 'Vault',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!needsAccess && !scan.running)
            TidyActionButton(
              label: hasResults ? 'Refresh Library Scan' : 'Scan Library',
              onPressed: () => context.push('/scan?start=true'),
            ),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
      child: Column(
        children: [
          if (scan.running) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: TidySpacing.md),
            const Text('The library scan is already running.'),
          ] else if (hasResults)
            const Text('There are no accessible photos to add to the Vault.'),
          if (scan.phase == ScanPhase.error || scan.phase == ScanPhase.stale)
            const Text(
              'The saved scan needs a refresh before you can select photos.',
            ),
        ],
      ),
    );
  }

  Future<void> _add(List<String> ids) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(groupEightServiceProvider).addVaultItems(ids);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Some copies could not be added: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _VaultScanViewState {
  const _VaultScanViewState(this.state);

  final ScanState state;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _VaultScanViewState) return false;
    final a = state;
    final b = other.state;
    if (identical(a, b)) return true;
    if (identical(a, b)) return true;
    if (a.phase != b.phase ||
        a.running != b.running ||
        a.hasResults != b.hasResults ||
        a.permissions['photos'] != b.permissions['photos']) {
      return false;
    }
    final aPhotos = a.media.where((record) => !record.video);
    final bPhotos = b.media.where((record) => !record.video);
    if (aPhotos.length != bPhotos.length) return false;
    final aIterator = aPhotos.iterator;
    final bIterator = bPhotos.iterator;
    while (aIterator.moveNext() && bIterator.moveNext()) {
      if (aIterator.current.id != bIterator.current.id) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    state.phase,
    state.running,
    state.hasResults,
    state.permissions['photos'],
    Object.hashAll(
      state.media.where((record) => !record.video).map((item) => item.id),
    ),
  );
}
