import 'package:flutter/material.dart';

import '../../../core/design/tidy_sizes.dart';
import '../../../core/design/tidy_spacing.dart';
import 'onboarding_back_button.dart';
import '../../../core/widgets/tidy_page_background.dart';

class OnboardingPageFrame extends StatelessWidget {
  const OnboardingPageFrame({
    required this.body,
    required this.actions,
    this.onBack,
    super.key,
  });

  final Widget body;
  final Widget actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scrollActions =
                  constraints.maxHeight < TidySizes.pinnedActionsMinHeight &&
                  MediaQuery.textScalerOf(context).scale(TidySizes.actionText) >
                      TidySizes.actionText * 1.5;
              final content = Padding(
                padding: EdgeInsets.fromLTRB(
                  TidySpacing.lg,
                  onBack == null
                      ? TidySpacing.onboardingTop
                      : TidySpacing.pageTop,
                  TidySpacing.lg,
                  TidySpacing.md,
                ),
                child: body,
              );
              return Column(
                children: <Widget>[
                  if (onBack != null)
                    const SizedBox(height: TidySpacing.pageTop),
                  if (onBack != null)
                    SizedBox(
                      height: TidySizes.touchTarget,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OnboardingBackButton(onPressed: onBack!),
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: scrollActions
                          ? Column(children: <Widget>[content, actions])
                          : content,
                    ),
                  ),
                  if (!scrollActions) actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
