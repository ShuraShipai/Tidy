import 'package:flutter/material.dart';
import '../../../core/design/tidy_colors.dart';
import 'contact_match_evidence.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_clay_surface.dart';
import '../models/contact_record.dart';

class ContactMatchCard extends StatelessWidget {
  const ContactMatchCard({
    required this.first,
    required this.second,
    required this.evidence,
    required this.onReview,
    required this.onIgnore,
    super.key,
  });
  final ContactRecord first, second;
  final List<String> evidence;
  final VoidCallback onReview, onIgnore;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TidySpacing.md),
    child: TidyClaySurface(
      radius: TidyRadii.card,
      color: TidyColors.surface,
      shadows: TidyShadows.raised,
      child: Padding(
        padding: const EdgeInsets.all(TidySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: TidyColors.orbGreenLight,
                  foregroundColor: TidyColors.emerald,
                  child: Text(first.initials),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        first.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '2 possible matches',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TidyColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in evidence) ContactMatchEvidence(label: item),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReview,
                    child: const Text('Review'),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(onPressed: onIgnore, child: const Text('Ignore')),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
