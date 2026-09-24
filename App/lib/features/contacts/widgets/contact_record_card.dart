import 'package:flutter/material.dart';
import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_clay_surface.dart';
import '../models/contact_record.dart';

class ContactRecordCard extends StatelessWidget {
  const ContactRecordCard({
    required this.contact,
    this.preview = false,
    super.key,
  });
  final ContactRecord contact;
  final bool preview;
  @override
  Widget build(BuildContext context) => TidyClaySurface(
    radius: TidyRadii.card,
    color: TidyColors.surface,
    shadows: TidyShadows.raised,
    child: Padding(
      padding: const EdgeInsets.all(TidySpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview ? 'Merged contact preview' : contact.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _field('Name', contact.name),
          if (contact.phones.isNotEmpty)
            _field('Phone', contact.phones.join('\n')),
          if (contact.emails.isNotEmpty)
            _field('Email', contact.emails.join('\n')),
          if (contact.organization.isNotEmpty)
            _field('Company', contact.organization),
        ],
      ),
    ),
  );
  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(color: TidyColors.secondaryText),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
