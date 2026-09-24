import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/tidy_colors.dart';
import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../controllers/contacts_controller.dart';
import '../../models/contact_record.dart';
import '../../widgets/contact_record_card.dart';

class MergedContactPreviewPage extends ConsumerStatefulWidget {
  const MergedContactPreviewPage({required this.group, super.key});
  final ContactMatchGroup group;
  @override
  ConsumerState<MergedContactPreviewPage> createState() =>
      _MergedContactPreviewPageState();
}

class _MergedContactPreviewPageState
    extends ConsumerState<MergedContactPreviewPage> {
  String? keeperId;
  bool busy = false, done = false;
  String? error;
  ContactRecord? completedRecord;
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(contactsControllerProvider).value;
    if (done && completedRecord != null) return _successPage(completedRecord!);
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
    final keeper = (keeperId == a.id || keeperId == b.id)
            ? (keeperId == a.id ? a : b)
            : a,
        other = keeper.id == a.id ? b : a;
    final merged = ContactRecord(
      id: keeper.id,
      givenName: keeper.givenName,
      familyName: keeper.familyName,
      organization: keeper.organization.isNotEmpty
          ? keeper.organization
          : other.organization,
      phones: _union(a.phones, b.phones),
      emails: _union(a.emails, b.emails),
      version: keeper.version,
    );
    return Scaffold(
      backgroundColor: TidyColors.background,
      appBar: AppBar(
        title: Text(done ? 'Contacts merged' : 'Merged Contact Preview'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TidySpacing.lg),
          children: [
            if (done) ...[
              const Icon(
                Icons.contacts_rounded,
                color: TidyColors.emerald,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'All together now.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'The reviewed source record was merged. The preserved fields are shown below.',
              ),
              const SizedBox(height: 20),
              ContactRecordCard(contact: merged, preview: true),
              const SizedBox(height: 24),
              TidyActionButton(
                label: 'Back to Contacts',
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ] else ...[
              Text(
                'Exactly what the merged contact will contain.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Keep the primary name and company from',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: a.id, label: Text(a.name)),
                  ButtonSegment(value: b.id, label: Text(b.name)),
                ],
                selected: {keeper.id},
                onSelectionChanged: (v) => setState(() => keeperId = v.first),
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
                  'Unique phone numbers and email addresses from both records are included. Other supported unique details stay with the merged record. Conflicting notes or birthdays stop the merge so nothing is silently lost.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
                onPressed: busy ? null : () => _confirm(keeper, other, merged),
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
                        Navigator.of(context).pop();
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _union(List<String> a, List<String> b) => [
    ...{...a, ...b},
  ];

  Widget _successPage(ContactRecord contact) => Scaffold(
    backgroundColor: TidyColors.background,
    appBar: AppBar(title: const Text('Contacts merged')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(TidySpacing.lg),
        children: [
          const Icon(
            Icons.contacts_rounded,
            color: TidyColors.emerald,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'All together now.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'The reviewed source record was merged. The preserved fields are shown below.',
          ),
          const SizedBox(height: 20),
          ContactRecordCard(contact: contact, preview: true),
          const SizedBox(height: 24),
          TidyActionButton(
            label: 'Back to Contacts',
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
    ),
  );
  Future<void> _confirm(
    ContactRecord keeper,
    ContactRecord other,
    ContactRecord merged,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merge these contacts?'),
        content: const Text(
          'The two reviewed records will become the merged contact shown in your preview. This change will be saved to Contacts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Merge Contacts'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(contactsControllerProvider.notifier)
          .merge(
            keeper,
            other,
            givenName: merged.givenName,
            familyName: merged.familyName,
            organization: merged.organization,
            phones: merged.phones,
            emails: merged.emails,
          );
      if (mounted) {
        setState(() {
          busy = false;
          done = true;
          completedRecord = merged;
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
