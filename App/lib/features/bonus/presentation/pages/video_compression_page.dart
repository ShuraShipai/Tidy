import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../scan/controllers/scan_controller.dart';
import '../../../scan/models/scan_state.dart';
import '../../services/group_eight_service.dart';
import '../../widgets/bonus_page_frame.dart';
import '../widgets/video_compression_preview.dart';

enum _CompressionQuality { smaller, balanced, higher }

class VideoCompressionPage extends ConsumerStatefulWidget {
  const VideoCompressionPage({required this.assetId, super.key});
  final String assetId;

  @override
  ConsumerState<VideoCompressionPage> createState() =>
      _VideoCompressionPageState();
}

class _VideoCompressionPageState extends ConsumerState<VideoCompressionPage> {
  _CompressionQuality _quality = _CompressionQuality.balanced;
  String? _jobId;
  String? _error;
  String? _errorCode;
  String? _compressedPath;
  int? _compressedBytes;
  double _progress = 0;
  bool _running = false;
  bool _saved = false;
  bool _removing = false;
  Uint8List? _originalPreview;
  Uint8List? _compressedPreview;
  late final Future<Uint8List?> _originalPreviewFuture;

  GroupEightService get _service => ref.read(groupEightServiceProvider);

  @override
  void initState() {
    super.initState();
    _originalPreviewFuture = _service.compressionThumbnail(
      assetId: widget.assetId,
    );
  }

  MediaRecord? get _video {
    final scan = ref.read(scanControllerProvider);
    for (final media in scan.media) {
      if (media.id == widget.assetId && media.video) return media;
    }
    return null;
  }

  int? get _estimatedBytes {
    final video = _video;
    if (video == null || video.duration <= 0) return null;
    final bitsPerSecond = switch (_quality) {
      _CompressionQuality.smaller => 950000,
      _CompressionQuality.balanced => 2200000,
      _CompressionQuality.higher => 5200000,
    };
    final estimate = (video.duration * (bitsPerSecond + 128000) / 8).round();
    return video.bytes == null ? estimate : estimate.clamp(0, video.bytes!);
  }

  @override
  void dispose() {
    final job = _jobId;
    if (job != null && !_saved) unawaited(_service.discardCompression(job));
    super.dispose();
  }

  Future<void> _compress() async {
    final video = _video;
    if (video == null || _running) return;
    final profile = Stopwatch()..start();
    setState(() {
      _running = true;
      _error = null;
      _errorCode = null;
      _progress = 0;
    });
    try {
      _jobId = await _service.startCompression(
        assetId: video.id,
        quality: _quality.name,
        temporaryBytes: (_estimatedBytes ?? video.bytes ?? 0) * 2,
      );
      final exportWaitStarted = profile.elapsedMilliseconds;
      while (mounted && _jobId != null) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final status = await _service.compressionStatus(_jobId!);
        if (!mounted) return;
        final progress = (status['progress'] as num?)?.toDouble() ?? 0;
        setState(() => _progress = progress.clamp(0, 1));
        final state = status['status'];
        if (state == 'completed') {
          _compressedPath = status['path'] as String?;
          _compressedBytes = (status['bytes'] as num?)?.toInt();
          final previewStarted = profile.elapsedMilliseconds;
          // Reuse the preview requested on page entry; retrieving the same
          // Photos AVAsset again after export needlessly repeats PhotoKit work.
          _originalPreview = await _originalPreviewFuture;
          _compressedPreview = await _service.compressionThumbnail(
            path: _compressedPath,
          );
          debugPrint(
            'compression_profile export_wait_ms=${previewStarted - exportWaitStarted} '
            'preview_pair_ms=${profile.elapsedMilliseconds - previewStarted} '
            'tap_to_result_ms=${profile.elapsedMilliseconds}',
          );
          if (!mounted) return;
          setState(() {
            _running = false;
          });
          return;
        }
        if (state == 'failed' || state == 'cancelled') {
          throw PlatformException(
            code: state == 'cancelled'
                ? 'compression_cancelled'
                : 'compression_failed',
            message:
                status['error'] as String? ??
                'iOS could not create the compressed copy.',
          );
        }
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _running = false;
          _error = error.message ?? 'Compression failed.';
          _errorCode = error.code;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _running = false;
          _error = '$error';
          _errorCode = 'compression_failed';
        });
      }
    }
  }

  Future<void> _cancel() async {
    final id = _jobId;
    if (id != null) await _service.cancelCompression(id);
    if (mounted) {
      setState(() {
        _running = false;
        _jobId = null;
      });
    }
  }

  Future<void> _keepBoth() async {
    final id = _jobId;
    if (id == null || _saved) return;
    setState(() => _removing = true);
    try {
      await _service.keepCompressedCopy(id, retainForRemoval: true);
      if (!mounted) return;
      setState(() {
        _saved = true;
        _removing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compressed video saved as a separate Photos item.'),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _removing = false;
          _error = '$error';
        });
      }
    }
  }

  Future<void> _removeOriginal() async {
    final id = _jobId;
    if (id == null || _removing) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RemoveOriginalSheet(),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _removing = true);
    try {
      if (!_saved) {
        await _service.keepCompressedCopy(id, retainForRemoval: true);
        _saved = true;
      }
      final result = await _service.removeCompressedOriginal(
        id,
        originalBytes: _video?.bytes,
      );
      final removed = result['removed'] == true;
      if (!mounted) return;
      if (!removed) throw StateError('The original remains in Photos. $result');
      setState(() {
        _removing = false;
        _jobId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Original removed. The compressed copy remains in Photos.',
          ),
        ),
      );
      context.pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _removing = false;
          _error = '$error';
        });
      }
    }
  }

  Future<void> _playPreview({required bool compressed}) async {
    try {
      await _service.playCompressionPreview(
        assetId: compressed ? null : widget.assetId,
        path: compressed ? _compressedPath : null,
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Preview could not be opened: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    if (video == null) {
      return const BonusPageFrame(
        title: 'Video unavailable',
        subtitle:
            'This video is no longer present in the current on-device scan.',
        backLabel: 'Video',
        child: SizedBox.shrink(),
      );
    }
    if (_running) return _progressPage();
    if (_compressedPath != null) return _resultPage(video);
    if (_error != null) return _errorPage(video);
    return BonusPageFrame(
      title: 'A smaller video.\nThe same memory.',
      subtitle: 'Choose the balance that works for you.',
      backLabel: 'Video',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TidyActionButton(label: 'Compress', onPressed: _compress),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(TidySpacing.sm),
              child: Row(
                children: [
                  VideoCompressionPreview(
                    aspectRatio: video.width > 0 && video.height > 0
                        ? video.width / video.height
                        : 1,
                    preview: _originalPreviewFuture,
                    onPlay: () => _playPreview(compressed: false),
                  ),
                  const SizedBox(width: TidySpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Original video'),
                        Text(
                          video.bytes == null
                              ? 'Size unavailable'
                              : _size(video.bytes!),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${video.width} × ${video.height} · ${_duration(video.duration)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TidySpacing.md),
          Text('Compression', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: TidySpacing.xs),
          for (final option in _CompressionQuality.values) ...[
            _QualityOption(
              quality: option,
              selected: _quality == option,
              estimate: _estimatedFor(video, option),
              onTap: () => setState(() => _quality = option),
            ),
            const SizedBox(height: TidySpacing.sm),
          ],
          const Text(
            'Output sizes are estimates based on duration and quality. iOS reports the actual size after export. Your original stays unchanged.',
          ),
          if (_error != null) ...[
            const SizedBox(height: TidySpacing.md),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _progressPage() => BonusPageFrame(
    title: 'Making a little room.',
    subtitle: 'Creating a separate, smaller copy.',
    footer: TidyActionButton(
      label: 'Cancel',
      style: TidyActionStyle.secondary,
      onPressed: _cancel,
    ),
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(TidySpacing.xl),
          child: Icon(Icons.compress, size: 100),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(TidySpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Preparing compressed video…'),
                const SizedBox(height: TidySpacing.sm),
                LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                ),
                const SizedBox(height: TidySpacing.sm),
                const Text(
                  'Your original is safe. Keep Tidy open until the copy is ready.',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _resultPage(MediaRecord video) => BonusPageFrame(
    title: 'Smaller. Still your moment.',
    subtitle: 'Preview both before deciding what to keep.',
    backLabel: 'Video',
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TidyActionButton(
          label: _saved ? 'Done' : 'Keep Both',
          onPressed: _removing
              ? null
              : _saved
              ? () => context.pop()
              : _keepBoth,
        ),
        const SizedBox(height: TidySpacing.xs),
        TidyActionButton(
          label: 'Remove Original…',
          style: TidyActionStyle.secondary,
          onPressed: _removing ? null : _removeOriginal,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _PreviewColumn(
                label: 'Original · ${video.width} × ${video.height}',
                bytes: video.bytes,
                image: _originalPreview,
                onTap: () => _playPreview(compressed: false),
              ),
            ),
            const SizedBox(width: TidySpacing.sm),
            Expanded(
              child: _PreviewColumn(
                label: 'Compressed · ${_quality.name}',
                bytes: _compressedBytes,
                image: _compressedPreview,
                onTap: () => _playPreview(compressed: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: TidySpacing.md),
        if (video.bytes != null && _compressedBytes != null)
          Text(
            '${_size((video.bytes! - _compressedBytes!).clamp(0, video.bytes!))} smaller',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        const SizedBox(height: TidySpacing.lg),
        Text(
          _saved
              ? 'The compressed copy is saved in Photos. The original is still there.'
              : 'Your original is still here. Keep both copies, or review removal of the original. Nothing is replaced automatically.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (_error != null) ...[
          const SizedBox(height: TidySpacing.sm),
          Text(_error!),
        ],
      ],
    ),
  );

  Widget _errorPage(MediaRecord video) {
    final lowSpace = _errorCode == 'compression_low_storage';
    return BonusPageFrame(
      title: lowSpace
          ? 'A little more room first.'
          : 'That video couldn’t be compressed.',
      subtitle: lowSpace
          ? 'iOS reports there is not enough temporary space for this estimated copy. Your original is unchanged.'
          : 'Your original video hasn’t changed. Try again, or keep it just as it is.',
      backLabel: 'Video',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TidyActionButton(
            label: lowSpace ? 'Review Storage' : 'Try Again',
            onPressed: lowSpace ? null : _compress,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          lowSpace ? Icons.storage_outlined : Icons.video_file_outlined,
          size: 88,
        ),
      ),
    );
  }

  String? _estimatedFor(MediaRecord video, _CompressionQuality quality) {
    if (video.duration <= 0) return null;
    final rate = switch (quality) {
      _CompressionQuality.smaller => 1078000,
      _CompressionQuality.balanced => 2328000,
      _CompressionQuality.higher => 5328000,
    };
    var bytes = (video.duration * rate / 8).round();
    if (video.bytes != null) bytes = bytes.clamp(0, video.bytes!);
    return _size(bytes);
  }

  static String _duration(double seconds) {
    final total = seconds.round();
    return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
  }

  static String _size(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).round()} MB';
    return '${(bytes / 1024).round()} KB';
  }
}

class _QualityOption extends StatelessWidget {
  const _QualityOption({
    required this.quality,
    required this.selected,
    required this.estimate,
    required this.onTap,
  });
  final _CompressionQuality quality;
  final bool selected;
  final String? estimate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labels = switch (quality) {
      _CompressionQuality.smaller => (
        'Smaller',
        'More compression. Some detail is lost.',
      ),
      _CompressionQuality.balanced => (
        'Balanced',
        'A good balance of detail and file size.',
      ),
      _CompressionQuality.higher => (
        'Higher Quality',
        'More detail, a larger file.',
      ),
    };
    final selectedShape = RoundedRectangleBorder(
      side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      borderRadius: BorderRadius.circular(22),
    );
    return Card(
      shape: selected ? selectedShape : null,
      clipBehavior: Clip.antiAlias,
      elevation: selected ? 0 : null,
      child: ListTile(
        onTap: onTap,
        title: Text(labels.$1),
        subtitle: Text(labels.$2),
        trailing: Text(estimate ?? 'Estimate unavailable'),
      ),
    );
  }
}

class _PreviewColumn extends StatelessWidget {
  const _PreviewColumn({
    required this.label,
    required this.bytes,
    required this.image,
    required this.onTap,
  });
  final String label;
  final int? bytes;
  final Uint8List? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AspectRatio(
        aspectRatio: 0.8,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: Colors.black12,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  if (image == null)
                    const Icon(Icons.video_file_outlined)
                  else
                    Image.memory(image!, fit: BoxFit.cover),
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: TidySpacing.xs),
      Text(
        bytes == null
            ? 'Size unavailable'
            : _VideoCompressionPageState._size(bytes!),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
    ],
  );
}

class _RemoveOriginalSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(TidySpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_outline, size: 44),
          const SizedBox(height: TidySpacing.md),
          Text(
            'Remove original video?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: TidySpacing.sm),
          const Text(
            'The compressed copy will be saved first. Photos will ask for approval before moving the original to Recently Deleted.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TidySpacing.lg),
          TidyActionButton(
            label: 'Save Copy & Remove Original',
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
