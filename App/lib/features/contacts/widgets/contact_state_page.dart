import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';

class ContactStatePage extends StatelessWidget {
  const ContactStatePage({
    required this.title,
    required this.message,
    required this.action,
    required this.onAction,
    this.empty = false,
    super.key,
  });

  final String title;
  final String message;
  final String action;
  final VoidCallback onAction;
  final bool empty;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TidySpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            empty ? Icons.contacts_outlined : Icons.lock_outline,
            size: 64,
            color: TidyColors.emerald,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: TidyColors.secondaryText),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 260,
            child: TidyActionButton(label: action, onPressed: onAction),
          ),
        ],
      ),
    ),
  );
}
