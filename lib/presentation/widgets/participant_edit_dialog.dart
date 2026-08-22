import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/models/models.dart';
import '../../l10n/app_localizations.dart';

/// Result draft of the add/edit participant dialog.
class ParticipantDraft {
  final String name;
  final int color;
  final String? contact;
  final String? note;
  const ParticipantDraft({
    required this.name,
    required this.color,
    this.contact,
    this.note,
  });
}

/// Opens the add/edit participant dialog and returns the draft, or `null`
/// when dismissed.
Future<ParticipantDraft?> showParticipantEditDialog(
  BuildContext context, {
  Participant? existing,
  int? defaultColor,
}) {
  return showDialog<ParticipantDraft>(
    context: context,
    builder: (ctx) => EditParticipantDialog(
      existing: existing,
      defaultColor: defaultColor ?? kParticipantColors[0],
    ),
  );
}

class EditParticipantDialog extends StatefulWidget {
  final Participant? existing;
  final int defaultColor;
  const EditParticipantDialog({
    super.key,
    this.existing,
    required this.defaultColor,
  });

  @override
  State<EditParticipantDialog> createState() => _EditParticipantDialogState();
}

class _EditParticipantDialogState extends State<EditParticipantDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _noteCtrl;
  late int _color;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _contactCtrl = TextEditingController(text: e?.contact ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _color = e?.color ?? widget.defaultColor;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.existing == null ? l10n.addMember : l10n.editMember),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.nameField,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactCtrl,
                decoration: InputDecoration(
                  labelText: l10n.contactOptional,
                  hintText: l10n.contactHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.noteForTripOptional,
                  hintText: l10n.noteHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.avatarColor,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: kParticipantColors.map((c) {
                  final selected = c == _color;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(c),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              ParticipantDraft(
                name: _nameCtrl.text.trim(),
                color: _color,
                contact: _contactCtrl.text.trim().isEmpty
                    ? null
                    : _contactCtrl.text.trim(),
                note: _noteCtrl.text.trim().isEmpty
                    ? null
                    : _noteCtrl.text.trim(),
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}