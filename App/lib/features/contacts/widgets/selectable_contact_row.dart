import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../models/contact_record.dart';

class SelectableContactRow extends StatelessWidget {
  const SelectableContactRow({
    required this.contact,
    required this.selected,
    required this.onTap,
    super.key,
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
