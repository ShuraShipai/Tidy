import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../models/video_record.dart';

class VideoPlayerSurface extends StatefulWidget {
  const VideoPlayerSurface({required this.video, super.key});

  final VideoRecord video;

  @override
  State<VideoPlayerSurface> createState() => _VideoPlayerSurfaceState();
}

class _VideoPlayerSurfaceState extends State<VideoPlayerSurface> {
  MethodChannel? _player;
  StreamSubscription<Object?>? _events;
  bool _ready = false;
  bool _playing = false;
  double _position = 0;
  double _duration = 0;
  String? _error;

  @override
  void dispose() {
    unawaited(_events?.cancel());
    super.dispose();
  }

  void _created(int viewId) {
    final channelName = 'tidy/videos/player/$viewId';
    _player = MethodChannel(channelName);
    _events = EventChannel('tidy/videos/events/$viewId')
        .receiveBroadcastStream()
        .listen(
          _onEvent,
          onError: (Object error) {
            if (mounted) {
              setState(() => _error = 'Video playback is unavailable.');
            }
          },
        );
  }

  void _onEvent(Object? event) {
    if (!mounted || event is! Map) return;
    setState(() {
      _ready = event['ready'] == true;
      _playing = event['playing'] == true;
      _position = (event['position'] as num?)?.toDouble() ?? _position;
      _duration = (event['duration'] as num?)?.toDouble() ?? _duration;
      _error = event['error'] as String?;
    });
  }

  Future<void> _togglePlayback() async {
    try {
      if (_playing) {
        await _player?.invokeMethod<void>('pause');
      } else {
        await _player?.invokeMethod<void>('play');
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.message ?? 'Video playback is unavailable.',
        );
      }
    }
  }

  Future<void> _seek(double value) async {
    _position = value;
    if (mounted) {
      setState(() {});
    }
    try {
      await _player?.invokeMethod<void>('seek', value);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.message ?? 'Could not seek in this video.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final duration = _duration > 0 ? _duration : widget.video.duration;
    return ColoredBox(
      color: const Color(0xFF1F1C27),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: widget.video.width > 0 && widget.video.height > 0
                ? widget.video.width / widget.video.height
                : 16 / 9,
            child: available
                ? UiKitView(
                    viewType: 'tidy/videos/player',
                    creationParams: {'id': widget.video.id},
                    creationParamsCodec: const StandardMessageCodec(),
                    onPlatformViewCreated: _created,
                  )
                : const Center(
                    child: Text(
                      'Video playback is available on iPhone.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TidySpacing.md),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TidySpacing.md),
            child: Row(
              children: [
                IconButton(
                  tooltip: _playing ? 'Pause video' : 'Play video',
                  onPressed: available && _ready ? _togglePlayback : null,
                  color: Colors.white,
                  icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                ),
                Expanded(
                  child: Slider(
                    value: duration <= 0
                        ? 0
                        : _position.clamp(0, duration).toDouble(),
                    max: duration <= 0 ? 1 : duration,
                    onChanged: _ready
                        ? (value) => setState(() => _position = value)
                        : null,
                    onChangeEnd: _ready ? _seek : null,
                    activeColor: TidyColors.lightViolet,
                    inactiveColor: Colors.white24,
                  ),
                ),
                Text(
                  _clock(duration),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _clock(double seconds) {
    if (!seconds.isFinite || seconds <= 0) return '0:00';
    final total = seconds.floor();
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }
}
