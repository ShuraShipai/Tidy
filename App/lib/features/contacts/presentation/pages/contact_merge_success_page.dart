import 'package:flutter/material.dart';

import '../../../../core/design/tidy_colors.dart';
import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../../core/widgets/tidy_glyph.dart';
import '../../../../core/widgets/tidy_orb.dart';
import '../../models/contact_record.dart';
import '../../widgets/contact_record_card.dart';

class ContactMergeSuccessPage extends StatelessWidget {
  const ContactMergeSuccessPage({required this.contact, super.key});

  final ContactRecord contact;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TidyColors.background,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TidySpacing.lg),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 60),
                  const Center(
                    child: TidyOrb(
                      glyph: TidyGlyphName.contacts,
                      tone: TidyOrbTone.green,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'All together now.',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${contact.name}’s reviewed details are in one contact.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ContactRecordCard(contact: contact, preview: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TidyActionButton(
              label: 'Back to Contacts',
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ),
      ),
    ),
  );
}
