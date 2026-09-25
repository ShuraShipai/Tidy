import 'package:flutter/material.dart';

import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_page_background.dart';
import 'photo_page_top_bar.dart';

class BlurryAnalysisIncompleteState extends StatelessWidget {
  const BlurryAnalysisIncompleteState({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TidyPageBackground(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: TidySpacing.lg),
              child: PhotoPageTopBar(backLabel: 'Photos'),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(TidySpacing.lg),
              child: Text(
                'Some photos couldn’t be checked for blur.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    ),
  );
}
