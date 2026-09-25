import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_colors.dart';
import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../controllers/contacts_controller.dart';
import '../../widgets/contact_page_heading.dart';
import '../../widgets/contact_record_card.dart';

/// Group 05 selection only. The approved Review Cleanup destination is Group 06.
class ContactDeleteReviewPage extends ConsumerStatefulWidget {
  const ContactDeleteReviewPage({required this.initialContactId, super.key});

  final String initialContactId;

  @override
  ConsumerState<ContactDeleteReviewPage> createState() =>
      _ContactDeleteReviewPageState();
}

class _ContactDeleteReviewPageState
    extends ConsumerState<ContactDeleteReviewPage> {
  final Set<String> selected = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactsControllerProvider).value;
    if (state == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final available = state.contacts
        .where((contact) => contact.id == widget.initialContactId)
        .toList();
    final chosen = available.where((contact) => selected.contains(contact.id));

    return Scaffold(
      backgroundColor: TidyColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(TidySpacing.lg),
                children: [
                  ContactPageHeading(
                    backLabel: 'Back',
                    title: 'Choose a Contact',
                    subtitle: 'Only select the record you no longer need.',
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 22),
                  for (final contact in available) ...[
                    ContactRecordCard(contact: contact),
                    const SizedBox(height: 16),
                    TidyActionButton(
                      label: selected.contains(contact.id)
                          ? 'Selected ✓'
                          : 'Select This Contact',
                      style: TidyActionStyle.secondary,
                      onPressed: () => _toggle(contact.id),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'Contacts deletion is not the same as merging. Review your selection before approving removal.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TidyColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${chosen.length} selected',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TidyActionButton(
                    label: 'Review Cleanup',
                    onPressed: chosen.isEmpty
                        ? null
                        : () {
                            ref
                                .read(contactsControllerProvider.notifier)
                                .setSelection(
                                  chosen.map((contact) => contact.id).toSet(),
                                );
                            context.push('/cleanup/review');
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(String id) => setState(() {
    if (!selected.add(id)) selected.remove(id);
  });
}
