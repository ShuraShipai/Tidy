import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/tidy_colors.dart';
import '../../../../core/design/tidy_radii.dart';
import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../controllers/contacts_controller.dart';
import '../../models/contact_record.dart';
import '../../widgets/contact_merge_confirmation_sheet.dart';
import '../../widgets/contact_page_heading.dart';
import '../../widgets/contact_record_card.dart';
import 'contact_delete_review_page.dart';
import 'contact_merge_success_page.dart';

class MergedContactPreviewPage extends ConsumerStatefulWidget {
  const MergedContactPreviewPage({required this.group, super.key});
  final ContactMatchGroup group;
  @override
  ConsumerState<MergedContactPreviewPage> createState() =>
      _MergedContactPreviewPageState();
}

class _MergedContactPreviewPageState
    extends ConsumerState<MergedContactPreviewPage> {
  bool busy = false, done = false;
  bool notesLossAcknowledged = false;
  String? error;
  ContactRecord? completedRecord;
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(contactsControllerProvider).value;
    if (done && completedRecord != null) {
      return ContactMergeSuccessPage(contact: completedRecord!);
    }
    final a = s?.byId(widget.group.first), b = s?.byId(widget.group.second);
    if (a == null || b == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Merged Contact Preview')),
        body: const Center(
          child: Text(
            'A contact changed or is no longer available. Review the current contacts again.',
          ),
        ),
      );
    }
    final keeper = a, other = b;
    final merged = ContactRecord(
      id: keeper.id,
      givenName: keeper.givenName,
      familyName: keeper.familyName,
      organization: keeper.organization.isNotEmpty
          ? keeper.organization
          : other.organization,
      phones: _union(
        a.phones,
        b.phones,
        (value) => value.replaceAll(RegExp(r'\D'), ''),
      ),
      emails: _union(a.emails, b.emails, (value) => value.trim().toLowerCase()),
      version: keeper.version,
    );
    return Scaffold(
      backgroundColor: TidyColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TidySpacing.lg),
          children: [
            ContactPageHeading(
              backLabel: 'Back',
              title: 'Merged Contact Preview',
              subtitle:
                  'Review the combined name, phone numbers, email addresses and company.',
              onBack: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 18),
            ContactRecordCard(contact: merged, preview: true),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TidyColors.noteBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Other supported details are preserved unless they conflict; conflicting details prevent the merge. iOS does not let Tidy read Contact Notes without a restricted Apple entitlement. Source Notes may be lost, so keep the contacts separate if you need them.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: notesLossAcknowledged,
              onChanged: busy
                  ? null
                  : (value) =>
                        setState(() => notesLossAcknowledged = value ?? false),
              title: const Text(
                'I understand source Notes may not be preserved',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error!,
                  style: const TextStyle(color: TidyColors.destructive),
                ),
              ),
            const SizedBox(height: 22),
            TidyActionButton(
              label: busy ? 'Merging…' : 'Merge Contacts',
              onPressed: busy || !notesLossAcknowledged
                  ? null
                  : () => _confirm(keeper, other, merged),
            ),
            const SizedBox(height: 8),
            TidyActionButton(
              label: 'Keep Separate',
              style: TidyActionStyle.secondary,
              onPressed: busy
                  ? null
                  : () {
                      ref
                          .read(contactsControllerProvider.notifier)
                          .ignore(widget.group);
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) =>
                            ContactDeleteReviewPage(initialContactId: other.id),
                      ),
                    ),
              child: const Text('Delete Contact…'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _union(
    List<String> a,
    List<String> b,
    String Function(String) normalize,
  ) {
    final seen = <String>{};
    return [
      for (final value in [...a, ...b])
        if (seen.add(normalize(value))) value,
    ];
  }

  Future<void> _confirm(
    ContactRecord keeper,
    ContactRecord other,
    ContactRecord merged,
  ) async {
    final yes = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TidyColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TidyRadii.card),
        ),
      ),
      builder: (_) => const ContactMergeConfirmationSheet(),
    );
    if (yes != true) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final saved = await ref
          .read(contactsControllerProvider.notifier)
          .merge(
            keeper,
            other,
            givenName: merged.givenName,
            familyName: merged.familyName,
            organization: merged.organization,
            phones: merged.phones,
            emails: merged.emails,
            acknowledgeUnreadableNotes: notesLossAcknowledged,
          );
      if (mounted) {
        setState(() {
          busy = false;
          done = true;
          completedRecord = saved;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e.toString();
        });
      }
    }
  }
}
