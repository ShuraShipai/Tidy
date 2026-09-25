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
    final scan = ref.watch(scanControllerProvider);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (permission == 'limited')
            const Text(
              'Limited Photos access · only selected library items are available.',
            ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PhotoAssetThumbnail(
                      photo: photo,
                      selected: selected,
                      semanticContext: 'Photo for private Vault',
                      onPreview: () => context.push(
                        '/photos/viewer?id=${Uri.encodeQueryComponent(photo.id)}&collection=similar',
                      ),
                      onToggleSelection: () => setState(() {
                        if (!_selected.add(photo.id))
                          _selected.remove(photo.id);
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: TidySpacing.md),
          const Text(
            'Vault and cleanup selections stay separate. Items unavailable locally cannot be copied.',
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(TidySpacing.md),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
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
      if (mounted)
        setState(() => _error = 'Some copies could not be added: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
