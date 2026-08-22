import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../widgets/participant_chips.dart';

class ManageParticipantsScreen extends ConsumerWidget {
  final String tripId;
  const ManageParticipantsScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(participantsProvider(tripId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.membersAndNotesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(
          context,
          ref,
          existing: null,
          color:
              kParticipantColors[(participantsAsync.valueOrNull?.length ?? 0) %
                  kParticipantColors.length],
        ),
        icon: const Icon(Icons.person_add),
        label: Text(l10n.addMember),
      ),
      body: participantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorLabel(e.toString()))),
        data: (participants) {
          if (participants.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noParticipantsYet,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noParticipantsHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final p = participants[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: ParticipantAvatar(participant: p, radius: 22),
                  title: Text(p.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.contact != null && p.contact!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            p.contact!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (p.note != null && p.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '📝 ${p.note}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      if ((p.note == null || p.note!.isEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            l10n.memberNotePlaceholder,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).disabledColor,
                                ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l10n.editAction,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _showEditDialog(context, ref, existing: p),
                      ),
                      IconButton(
                        tooltip: l10n.removeAction,
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmRemove(context, ref, p),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    Participant p,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeParticipantTitle),
        content: Text(l10n.removeParticipantContent(p.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.remove, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(participantsProvider(tripId).notifier)
          .removeParticipant(p.id);
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref, {
    required Participant? existing,
    int? color,
  }) async {
    final result = await showDialog<_ParticipantDraft>(
      context: context,
      builder: (ctx) => EditParticipantDialog(
        existing: existing,
        defaultColor: color ?? kParticipantColors[0],
      ),
    );
    if (result == null || !context.mounted) return;

    if (existing == null) {
      await ref
          .read(participantsProvider(tripId).notifier)
          .addParticipant(
            name: result.name,
            color: result.color,
            contact: result.contact,
            note: result.note,
          );
    } else {
      await ref
          .read(participantsProvider(tripId).notifier)
          .updateParticipant(
            existing.copyWith(
              name: result.name,
              color: result.color,
              contact: result.contact,
              note: result.note,
            ),
          );
    }
  }
}

class _ParticipantDraft {
  final String name;
  final int color;
  final String? contact;
  final String? note;
  const _ParticipantDraft({
    required this.name,
    required this.color,
    this.contact,
    this.note,
  });
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
              _ParticipantDraft(
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
