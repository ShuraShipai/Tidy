import 'package:flutter/material.dart';

import '../../../core/design/tidy_spacing.dart';
import '../models/photo_group.dart';

class NoPhotoGroupsFilterState extends StatelessWidget {
  const NoPhotoGroupsFilterState({required this.filter, super.key});

  final SimilarPhotoFilter filter;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: TidySpacing.xl),
      child: Text(
        filter == SimilarPhotoFilter.duplicates
            ? 'No exact duplicate groups were found.'
            : 'No similar photo groups were found.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
  );
}
