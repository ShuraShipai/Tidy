import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_clay_surface.dart';
import '../../../core/widgets/tidy_glyph.dart';
import '../models/video_record.dart';
import '../repositories/video_repository.dart';

class VideoCard extends ConsumerStatefulWidget {
  const VideoCard({
    required this.video,
    required this.selected,
    required this.onOpen,
    required this.onToggle,
    super.key,
  });

  final VideoRecord video;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  @override
  ConsumerState<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends ConsumerState<VideoCard> {
  late Future<VideoPreviewData?> _preview;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void didUpdateWidget(covariant VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) _loadPreview();
  }

  void _loadPreview() {
    _preview = ref
        .read(videoRepositoryProvider)
        .preview(widget.video.id)
        .then((value) => value, onError: (Object _) => null);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TidySpacing.md),
    child: TidyClaySurface(
      radius: TidyRadii.card,
      color: TidyColors.surface,
      shadows: TidyShadows.raised,
      child: SizedBox(
        height: 132,
        child: Row(
          children: [
            const SizedBox(width: TidySpacing.sm),
            Semantics(
              button: true,
              label: 'Preview video',
              child: GestureDetector(
                onTap: widget.onOpen,
                child: FutureBuilder<VideoPreviewData?>(
                  future: _preview,
                  builder: (context, snapshot) {
                    final bytes = snapshot.data?.thumbnailBytes;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(TidyRadii.thumbnail),
                      child: SizedBox(
                        width: 96,
                        height: 108,
                        child: bytes == null
                            ? const ColoredBox(
                                color: TidyColors.orbPinkLight,
                                child: Center(
                                  child: TidyGlyph(
                                    TidyGlyphName.video,
                                    size: 32,
                                    color: TidyColors.pink,
                                  ),
                                ),
                              )
                            : Image.memory(
                                Uint8List.fromList(bytes),
                                fit: BoxFit.cover,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: TidySpacing.sm),
            Expanded(
              child: FutureBuilder<VideoPreviewData?>(
                future: _preview,
                builder: (context, snapshot) {
                  final fileName = snapshot.data?.fileName;
                  return InkWell(
                    onTap: widget.onOpen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            fileName == null || fileName.isEmpty
                                ? 'Video file'
                                : fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: TidySpacing.xs),
                          Text(
                            '${widget.video.resolutionLabel} · ${_date(context, widget.video.createdAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: TidyColors.secondaryText),
                          ),
                          const SizedBox(height: TidySpacing.xs),
                          Text(
                            widget.video.sizeLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: widget.selected
                      ? 'Deselect video'
                      : 'Select video for review',
                  onPressed: widget.onToggle,
                  icon: Icon(
                    widget.selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: widget.selected
                        ? TidyColors.primary
                        : TidyColors.lightViolet,
                    size: 25,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 10),
                  child: Text(
                    widget.video.durationLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      backgroundColor: TidyColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  String _date(BuildContext context, DateTime? date) => date == null
      ? 'Date unavailable'
      : MaterialLocalizations.of(context).formatShortDate(date);
}
