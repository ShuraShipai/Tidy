import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/widgets/tidy_glyph.dart';
import '../../scan/models/scan_state.dart';
import '../services/photo_library_service.dart';

class PhotoAssetThumbnail extends ConsumerWidget {
  const PhotoAssetThumbnail({
    required this.photo,
    required this.selected,
    required this.onPreview,
    required this.onToggleSelection,
    this.isKeeper = false,
    this.onChooseKeeper,
    this.semanticContext = 'photo',
    super.key,
  });

  final MediaRecord photo;
  final bool selected;
  final VoidCallback onPreview;
  final VoidCallback onToggleSelection;
  final bool isKeeper;
  final VoidCallback? onChooseKeeper;
  final String semanticContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(photoThumbnailProvider(photo.id));
    final outline = selected || isKeeper;
    return Semantics(
      container: true,
      label: '$semanticContext, ${selected ? 'selected' : 'not selected'}',
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TidyRadii.thumbnail),
            border: outline
                ? Border.all(color: TidyColors.primary, width: 2.5)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TidyRadii.thumbnail - 2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Material(
                  color: TidyColors.violetTint,
                  child: InkWell(
                    onTap: onChooseKeeper ?? onPreview,
                    child: image.when(
                      data: (bytes) => bytes == null
                          ? const _UnavailablePhoto()
                          : Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (context, error, stackTrace) =>
                                  const _UnavailablePhoto(),
                            ),
                      error: (error, stackTrace) => const _UnavailablePhoto(),
                      loading: () => const Center(
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  left: 5,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: TidyColors.primaryText.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: TidyGlyph(
                          TidyGlyphName.photo,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isKeeper)
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7F1E6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        child: Text(
                          '✓ Keep',
                          style: TextStyle(
                            color: Color(0xFF14674A),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Material(
                      color: Colors.transparent,
                      child: InkResponse(
                        onTap: onToggleSelection,
                        radius: 22,
                        containedInkWell: true,
                        customBorder: const CircleBorder(),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected
                                  ? TidyColors.primary
                                  : Colors.black26,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check,
                                    size: 15,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnavailablePhoto extends StatelessWidget {
  const _UnavailablePhoto();

  @override
  Widget build(BuildContext context) => const Center(
    child: TidyGlyph(
      TidyGlyphName.photo,
      size: 30,
      color: TidyColors.violetDeep,
    ),
  );
}
