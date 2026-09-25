import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../photos/services/photo_library_service.dart';
import '../../../photos/widgets/photo_asset_thumbnail.dart';
import '../../../scan/controllers/scan_controller.dart';
import '../../../scan/models/scan_state.dart';
import '../../services/group_eight_service.dart';
import '../../widgets/bonus_page_frame.dart';
import '../../widgets/vault_move_confirmation_sheet.dart';

class VaultAddPage extends ConsumerStatefulWidget {
  const VaultAddPage({super.key});

  @override
  ConsumerState<VaultAddPage> createState() => _VaultAddPageState();
}

class _VaultAddPageState extends ConsumerState<VaultAddPage> {
  final Set<String> _selected = {};
  bool _busy = false;
  String? _error;
  Set<String> _vaultedSources = {};
  bool _vaultIndexLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadVaultedSources();
  }

  Future<void> _loadVaultedSources() async {
    try {
      final rows = await ref.read(groupEightServiceProvider).vaultItems();
      if (!mounted) return;
      setState(() {
        _vaultedSources = rows
            .map((row) => row['source'])
            .whereType<String>()
            .toSet();
        _vaultIndexLoaded = true;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Could not check existing Vault items: $error';
          _vaultIndexLoaded = true;
        });
      }
    }
  }

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
        ? _newestFirst(
            scan.media.where(
              (record) => !record.video && !_vaultedSources.contains(record.id),
            ),
          )
        : const <MediaRecord>[];
    if (photos.isEmpty) return _empty(scan, permission);
    return BonusPageFrame(
      title: 'Choose private items',
      subtitle:
          'Choose items to copy into Vault. Removing Photos originals is a separate confirmed step.',
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
                  onPreview: () {},
                  onTap: () => _toggleSelection(photo.id),
                  onToggleSelection: () => _toggleSelection(photo.id),
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
            : 'Move ${_selected.length} to Vault',
        onPressed: _selected.isEmpty || _busy || !_vaultIndexLoaded
            ? null
            : () => _add(_selected.toList(growable: false)),
      ),
    );
  }

  List<MediaRecord> _newestFirst(Iterable<MediaRecord> records) {
    final indexed = records.toList(growable: false).asMap().entries.toList();
    indexed.sort((left, right) {
      final leftDate = left.value.createdAt;
      final rightDate = right.value.createdAt;
      if (leftDate == null || rightDate == null) {
        if (leftDate == null && rightDate == null) {
          return left.key.compareTo(right.key);
        }
        return leftDate == null ? 1 : -1;
      }
      final byDate = rightDate.compareTo(leftDate);
      return byDate != 0 ? byDate : left.key.compareTo(right.key);
    });
    return indexed.map((entry) => entry.value).toList(growable: false);
  }

  Widget _empty(ScanState scan, String? permission) {
    final needsAccess = !const ['authorized', 'limited'].contains(permission);
    final hasResults = scan.hasResults;
    final discoveredPhotos = scan.media.where((record) => !record.video);
    final allDiscoveredPhotosVaulted =
        discoveredPhotos.isNotEmpty &&
        discoveredPhotos.every((record) => _vaultedSources.contains(record.id));
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
        ],
      ),
      child: Column(
        children: [
          if (scan.running) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: TidySpacing.md),
            const Text('The library scan is already running.'),
          ] else if (hasResults)
            Text(
              _vaultIndexLoaded && allDiscoveredPhotosVaulted
                  ? 'All available photos are already in the Vault.'
                  : 'There are no accessible photos to move to the Vault.',
            ),
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
      final copyResult = await ref
          .read(groupEightServiceProvider)
          .addVaultItems(ids);
      final verified = Set<String>.from(
        copyResult['verified'] as List? ?? const [],
      );
      final failedCopies = (copyResult['failures'] as List? ?? const []).length;
      final alreadyVaulted =
          (copyResult['alreadyVaulted'] as List? ?? const []).length;
      if (verified.isEmpty) {
        if (mounted) {
          setState(
            () => _error = alreadyVaulted > 0
                ? 'These items are already in the Vault. No originals were removed.'
                : 'No encrypted Vault copies could be verified. No originals were removed.',
          );
        }
        return;
      }
      if (!mounted) return;
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => VaultMoveConfirmationSheet(count: verified.length),
      );
      if (!mounted) return;
      if (confirmed != true) {
        context.pop<String>(
          '${verified.length} ${verified.length == 1 ? 'item was' : 'items were'} encrypted in Vault; originals remain in Photos.',
        );
        return;
      }
      try {
        final deletion = await ref
            .read(photoLibraryServiceProvider)
            .delete(verified);
        await ref
            .read(scanControllerProvider.notifier)
            .applyDeleted(deletion.deletedIds);
        final moved = deletion.deletedIds.length;
        final retained = verified.length - moved;
        final message = moved == 0
            ? 'Vault copies saved, but no Photos originals were removed${deletion.message == null ? '' : ': ${deletion.message}'}.'
            : retained == 0 && failedCopies == 0 && alreadyVaulted == 0
            ? '$moved ${moved == 1 ? 'item moved' : 'items moved'} to Vault.'
            : '$moved ${moved == 1 ? 'item moved' : 'items moved'}; $retained ${retained == 1 ? 'original remains' : 'originals remain'} in Photos. ${failedCopies > 0 ? '$failedCopies item(s) could not be copied. ' : ''}${alreadyVaulted > 0 ? '$alreadyVaulted item(s) were already in Vault. ' : ''}Verified Vault copies were kept.';
        if (mounted) context.pop<String>(message);
      } catch (error) {
        if (mounted) {
          context.pop<String>(
            'Encrypted Vault copies are saved, but Photos originals could not be removed: $error',
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Some copies could not be added: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleSelection(String id) => setState(() {
    if (!_selected.add(id)) _selected.remove(id);
  });
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
