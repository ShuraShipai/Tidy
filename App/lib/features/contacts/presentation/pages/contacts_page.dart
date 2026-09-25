import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/tidy_colors.dart';
import '../../../onboarding/services/onboarding_service.dart';
import '../../controllers/contacts_controller.dart';
import '../../widgets/contact_match_card.dart';
import '../../widgets/contact_state_page.dart';
import 'contact_review_page.dart';
import 'contact_delete_review_page.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});
  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(contactsControllerProvider.notifier).refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(contactsControllerProvider);
    final ctl = ref.read(contactsControllerProvider.notifier);
    return Scaffold(
      backgroundColor: TidyColors.background,
      body: SafeArea(
        child: async.when(
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (e, _) => ContactStatePage(
            title: 'Contacts unavailable',
            message: 'Contacts could not be read. Check access and try again.',
            action: 'Try Again',
            onAction: ctl.refresh,
          ),
          data: (s) => _content(context, s),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ContactsState s) {
    final ctl = ref.read(contactsControllerProvider.notifier);
    if (s.status != 'authorized' && s.status != 'limited') {
      return ContactStatePage(
        title: switch (s.status) {
          'notScanned' => 'Scan your library first',
          'scanning' => 'Scanning your library',
          'denied' => 'Contacts Access Needed',
          'restricted' => 'Contacts Are Restricted',
          'unsupported' => 'Contacts unavailable',
          _ => 'Contacts access needed',
        },
        message: switch (s.status) {
          'notScanned' =>
            'Start a scan from Home to review possible duplicate contacts.',
          'scanning' =>
            'Your contacts will be ready after the current scan finishes.',
          'denied' =>
            'Allow Contacts access in Settings to find possible duplicate contacts.',
          'restricted' =>
            'Contacts access is restricted by this iPhone. Change device restrictions to use contact review.',
          'unsupported' =>
            'Contact cleanup is available on iPhone with Contacts access.',
          _ =>
            'Allow access to find entries that may belong to the same person.',
        },
        action: s.status == 'denied'
            ? 'Open Settings'
            : s.status == 'notScanned' || s.status == 'scanning'
            ? 'Go to Home'
            : 'Try Again',
        onAction: () async {
          if (s.status == 'denied') {
            await OnboardingService().openSettings();
          } else if (s.status == 'notScanned' || s.status == 'scanning') {
            if (context.mounted) context.go('/home');
          } else {
            await ctl.refresh();
          }
        },
      );
    }
    if (s.visibleGroups.isEmpty) {
      return ContactStatePage(
        title: s.groups.isEmpty
            ? 'Everyone in their place.'
            : 'No more groups to review.',
        message: s.groups.isEmpty
            ? s.contacts.isEmpty
                  ? 'No contacts are available to review.'
                  : 'No possible duplicate contacts found.'
            : 'Ignored groups remain separate. No contact changes were made.',
        action: s.groups.isEmpty ? 'Refresh Contacts' : 'Done',
        onAction: s.groups.isEmpty ? ctl.refresh : () => context.go('/home'),
        empty: true,
      );
    }
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Duplicate Contacts',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${s.visibleGroups.length} possible duplicate groups',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'These contacts look similar. Review them before making changes.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: TidyColors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              for (final g in s.visibleGroups)
                if (s.byId(g.first) != null && s.byId(g.second) != null)
                  ContactMatchCard(
                    first: s.byId(g.first)!,
                    second: s.byId(g.second)!,
                    evidence: g.evidence,
                    onReview: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ContactReviewPage(group: g),
                      ),
                    ),
                    onIgnore: () => ctl.ignore(g),
                  ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ContactDeleteReviewPage(),
                  ),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Choose Contacts to Delete'),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
