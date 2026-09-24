import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/tidy_colors.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../controllers/contacts_controller.dart';
import '../../models/contact_record.dart';
import '../../widgets/contact_record_card.dart';
import 'merged_contact_preview_page.dart';
import 'contact_delete_review_page.dart';

class ContactReviewPage extends ConsumerWidget {
  const ContactReviewPage({required this.group, super.key});
  final ContactMatchGroup group;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(contactsControllerProvider).value;
    final a = s?.byId(group.first), b = s?.byId(group.second);
    if (a == null || b == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Contacts')),
        body: const Center(
          child: Text(
            'These contacts are no longer available. Refresh the list.',
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: TidyColors.background,
      appBar: AppBar(title: const Text('Review Contacts')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(
              'Do these look like the same person?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ContactRecordCard(contact: a),
            const SizedBox(height: 12),
            ContactRecordCard(contact: b),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final ev in group.evidence)
                  Chip(
                    label: Text(ev),
                    avatar: const Icon(
                      Icons.check_circle_outline,
                      color: TidyColors.emerald,
                      size: 18,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Matching details are evidence to review. Tidy will not change either contact unless you confirm.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: TidyColors.secondaryText),
            ),
            const SizedBox(height: 24),
            TidyActionButton(
              label: 'Preview Merged Contact',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MergedContactPreviewPage(group: group),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TidyActionButton(
              label: 'Keep Separate',
              style: TidyActionStyle.secondary,
              onPressed: () {
                ref.read(contactsControllerProvider.notifier).ignore(group);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ContactDeleteReviewPage(initialContactId: b.id),
                ),
              ),
              child: const Text('Delete Contact…'),
            ),
          ],
        ),
      ),
    );
  }
}
