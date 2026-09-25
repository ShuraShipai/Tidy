import 'package:flutter/material.dart';

import '../../../core/design/tidy_spacing.dart';

class SettingsAccessRefreshNote extends StatelessWidget {
  const SettingsAccessRefreshNote({super.key});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.verified_user_outlined, size: 18),
      const SizedBox(width: TidySpacing.sm),
      Expanded(
        child: Text(
          'Access is refreshed when you return to Tidy. Permission changes never delete content.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}
