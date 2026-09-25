import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../models/video_record.dart';

class VideoSortControl extends StatelessWidget {
  const VideoSortControl({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final VideoSortOrder value;
  final ValueChanged<VideoSortOrder> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: TidyColors.violetTint,
      borderRadius: BorderRadius.circular(TidyRadii.button),
    ),
    child: Padding(
      padding: const EdgeInsets.all(5),
      child: SegmentedButton<VideoSortOrder>(
        showSelectedIcon: false,
        segments: [
          for (final order in VideoSortOrder.values)
            ButtonSegment(value: order, label: Text(order.label)),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? TidyColors.surface
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? TidyColors.violetDeep
                : TidyColors.secondaryText,
          ),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? 2 : 0,
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TidyRadii.nested),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ),
    ),
  );
}
