import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../models/bonus_records.dart';
import '../../services/group_eight_service.dart';
import '../../widgets/bonus_page_frame.dart';

class PrivateVaultPage extends ConsumerStatefulWidget {
  const PrivateVaultPage({super.key});

  @override
  ConsumerState<PrivateVaultPage> createState() => _PrivateVaultPageState();
}

class _PrivateVaultPageState extends ConsumerState<PrivateVaultPage> {
  List<VaultItemRecord> _items = [];
  final Set<String> _selected = {};
  final Map<String, Future<Uint8List?>> _thumbnails = {};
  bool _unlocked = false;
  bool _busy = false;
  bool _setupChecked = false;
  bool _vaultConfigured = false;
  String? _error;
  late final AppLifecycleListener _lifecycleListener;

  GroupEightService get _service => ref.read(groupEightServiceProvider);

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onInactive: _lockUi,
      onHide: _lockUi,
      onPause: _lockUi,
    );
    unawaited(_loadVaultStatus());
  }

  Future<void> _loadVaultStatus() async {
    try {
      final configured = await _service.vaultIsConfigured();
      if (!mounted) return;
      setState(() {
        _vaultConfigured = configured;
        _setupChecked = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _setupChecked = true;
      });
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _lockUi() {
    if (!_unlocked && _items.isEmpty && _thumbnails.isEmpty) return;
    if (_unlocked && !_busy) unawaited(_service.lockVault());
    setState(() {
      _unlocked = false;
      _items = [];
      _selected.clear();
      _thumbnails.clear();
      _error = null;
    });
  }

  Future<void> _unlock() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.authenticateVault();
      final rows = await _service.vaultItems();
      if (!mounted) return;
      setState(() {
        _vaultConfigured = true;
        _setupChecked = true;
        _unlocked = true;
        _items = rows.map(VaultItemRecord.fromMap).toList(growable: false);
        _thumbnails.clear();
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    try {
      final rows = await _service.vaultItems();
      if (mounted) {
        setState(() => _items = rows.map(VaultItemRecord.fromMap).toList());
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _remove() async {
    final ids = List<String>.unmodifiable(_selected);
    if (ids.isEmpty || _busy) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _VaultRemovalConfirmation(count: ids.length),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await _service.removeVaultItems(ids);
      final removed = (outcome['removed'] as List? ?? const [])
          .cast<String>()
          .toSet();
      if (!mounted) return;
      setState(() {
        _items.removeWhere((item) => removed.contains(item.id));
        _selected.removeAll(removed);
        _thumbnails.removeWhere((id, _) => removed.contains(id));
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _lock() async {
    if (_unlocked) await _service.lockVault();
    if (mounted) {
      setState(() {
        _unlocked = false;
        _items = [];
        _selected.clear();
        _thumbnails.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) unawaited(_lock());
    },
    child: _unlocked ? _vaultScreen() : _setupScreen(),
  );

  Widget _setupScreen() => BonusPageFrame(
    title: 'Private Vault',
    subtitle: 'Protect selected copies using Face ID or your device passcode.',
    backLabel: 'Optional Features',
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TidyActionButton(
          label: !_setupChecked
              ? 'Checking Vault…'
              : _vaultConfigured
              ? 'Unlock Vault'
              : 'Set Up Vault',
          onPressed: _busy || !_setupChecked ? null : _unlock,
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Not Now'),
        ),
      ],
    ),
    child: Column(
      children: [
        const Icon(Icons.lock_outline, size: 100),
        const SizedBox(height: TidySpacing.md),
        const Text(
          'Stored privately on this iPhone\nSeparate from your cleanup selection',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TidySpacing.md),
        const Text(
          'Adding a copy does not remove its original from Photos.',
          textAlign: TextAlign.center,
        ),
        if (_error != null) ...[
          const SizedBox(height: TidySpacing.md),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(TidySpacing.md),
            child: CircularProgressIndicator(),
          ),
      ],
    ),
  );

  Widget _vaultScreen() => BonusPageFrame(
    title: 'Private Vault',
    subtitle:
        '${_items.length} private ${_items.length == 1 ? 'copy' : 'copies'} · unlocked for this session',
    backLabel: 'Settings',
    slivers: [
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
      if (_items.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: TidySpacing.xl),
            child: Column(
              children: [
                Icon(Icons.lock_outline, size: 56),
                SizedBox(height: TidySpacing.sm),
                Text('A space just for you.'),
                SizedBox(height: TidySpacing.xs),
                Text(
                  'Add items to keep encrypted copies behind device authentication.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: TidySpacing.lg),
          sliver: SliverGrid.builder(
            itemCount: _items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: TidySpacing.sm,
              mainAxisSpacing: TidySpacing.sm,
            ),
            itemBuilder: (context, index) {
              final item = _items[index];
              final image = _thumbnails.putIfAbsent(
                item.id,
                () => _service.vaultThumbnail(item.id),
              );
              return Semantics(
                label:
                    '${item.name}, ${_selected.contains(item.id) ? 'selected' : 'not selected'}',
                child: GestureDetector(
                  onTap: () => setState(() {
                    if (!_selected.add(item.id)) _selected.remove(item.id);
                  }),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FutureBuilder<Uint8List?>(
                          future: image,
                          builder: (context, snapshot) => snapshot.data == null
                              ? const ColoredBox(
                                  color: Color(0xFFEDE5F7),
                                  child: Icon(Icons.lock_outline),
                                )
                              : Image.memory(snapshot.data!, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Icon(
                          _selected.contains(item.id)
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 5),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TidySpacing.lg,
            TidySpacing.md,
            TidySpacing.lg,
            TidySpacing.lg,
          ),
          child: Text(
            _selected.isEmpty
                ? 'Select private copies to review removal. Photos originals remain in your library.'
                : '${_selected.length} selected · ${_size(_items.where((item) => _selected.contains(item.id)).fold<int>(0, (sum, item) => sum + item.bytes))} in the Vault',
          ),
        ),
      ),
    ],
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TidyActionButton(
          label: 'Add Items',
          onPressed: _busy
              ? null
              : () async {
                  await context.push('/bonus/vault/add');
                  if (mounted) await _refresh();
                },
        ),
        const SizedBox(height: TidySpacing.xs),
        TidyActionButton(
          label: 'Remove Selected from Vault',
          style: TidyActionStyle.secondary,
          onPressed: _selected.isEmpty || _busy ? null : _remove,
        ),
        const SizedBox(height: TidySpacing.xs),
        TidyActionButton(
          label: 'Lock Vault',
          style: TidyActionStyle.secondary,
          onPressed: _lock,
        ),
      ],
    ),
  );

  String _size(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).round()} KB';
}

class _VaultRemovalConfirmation extends StatelessWidget {
  const _VaultRemovalConfirmation({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(TidySpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Remove selected Vault copies?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: TidySpacing.sm),
          const Text(
            'Only the reviewed encrypted copies will be removed. Their Photos originals stay in your library.',
          ),
          const SizedBox(height: TidySpacing.lg),
          TidyActionButton(
            label: 'Remove $count ${count == 1 ? 'Copy' : 'Copies'}',
            style: TidyActionStyle.destructive,
            onPressed: () => Navigator.pop(context, true),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}
