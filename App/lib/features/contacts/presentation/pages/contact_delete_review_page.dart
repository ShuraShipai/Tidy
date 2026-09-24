import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/tidy_colors.dart';
import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../controllers/contacts_controller.dart';
import '../../models/contact_record.dart';

class ContactDeleteReviewPage extends ConsumerStatefulWidget {
  const ContactDeleteReviewPage({this.initialContactId, super.key});
  final String? initialContactId;
  @override
  ConsumerState<ContactDeleteReviewPage> createState() =>
      _ContactDeleteReviewPageState();
}

class _ContactDeleteReviewPageState
    extends ConsumerState<ContactDeleteReviewPage> {
  bool done = false, busy = false;
  String? error;
  int removedCount = 0;
  @override
  void initState() {
    super.initState();
    if (widget.initialContactId != null &&
        !(ref
                .read(contactsControllerProvider)
                .value
                ?.selected
                .contains(widget.initialContactId) ??
            false)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref
            .read(contactsControllerProvider.notifier)
            .toggle(widget.initialContactId!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactsControllerProvider).value;
    final ctl = ref.read(contactsControllerProvider.notifier);
    if (state == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final chosen = state.contacts
        .where((c) => state.selected.contains(c.id))
        .toList();
    return Scaffold(
      backgroundColor: TidyColors.background,
      appBar: AppBar(
        title: Text(done ? 'Contacts removed' : 'Choose Contacts'),
      ),
      body: SafeArea(
        child: done
            ? ListView(
                padding: const EdgeInsets.all(TidySpacing.lg),
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: TidyColors.emerald,
                    size: 62,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$removedCount contact${removedCount == 1 ? '' : 's'} removed',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 10),
                  const Text('Only confirmed successful removals are counted.'),
                  const SizedBox(height: 24),
                  TidyActionButton(
                    label: 'Back to Contacts',
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
                    child: Text(
                      'Only select records you no longer need. Contact deletion is separate from merging.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: TidyColors.secondaryText,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      children: [
                        for (final c in state.contacts)
                          _SelectableContact(
                            contact: c,
                            selected: state.selected.contains(c.id),
                            onTap: () => ctl.toggle(c.id),
                          ),
                      ],
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        error!,
                        style: const TextStyle(color: TidyColors.destructive),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      children: [
                        Text(
                          '${chosen.length} selected',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        TidyActionButton(
                          label: 'Review Selection',
                          onPressed: chosen.isEmpty || busy
                              ? null
                              : () => _review(chosen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _review(List<ContactRecord> chosen) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Contacts to Delete'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'These exact contacts will be removed from this iPhone:',
              ),
              const SizedBox(height: 10),
              for (final c in chosen)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• ${c.name}'),
                ),
              const SizedBox(height: 10),
              const Text('This cannot be undone in Tidy.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: TidyColors.destructive,
            ),
            child: const Text('Delete Contacts'),
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
      await ref.read(contactsControllerProvider.notifier).deleteSelected();
      if (mounted) {
        setState(() {
          removedCount = chosen.length;
          done = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _SelectableContact extends StatelessWidget {
  const _SelectableContact({
    required this.contact,
    required this.selected,
    required this.onTap,
  });
  final ContactRecord contact;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    color: TidyColors.surface,
    child: CheckboxListTile(
      value: selected,
      onChanged: (_) => onTap(),
      title: Text(contact.name),
      subtitle: Text([...contact.phones, ...contact.emails].join(' · ')),
      secondary: CircleAvatar(
        backgroundColor: TidyColors.orbGreenLight,
        child: Text(contact.initials),
      ),
      controlAffinity: ListTileControlAffinity.trailing,
    ),
  );
}
