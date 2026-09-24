import 'package:flutter/material.dart';

import '../design/tidy_spacing.dart';

class SectionPlaceholderPage extends StatelessWidget {
  const SectionPlaceholderPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(TidySpacing.lg),
          child: Text(
            title == 'Storage'
                ? 'Your on-device storage overview will appear here.'
                : '$title will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
