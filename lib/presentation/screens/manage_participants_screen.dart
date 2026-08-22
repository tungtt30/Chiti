import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../widgets/participant_chips.dart';
import '../widgets/participant_edit_dialog.dart';

class ManageParticipantsScreen extends ConsumerWidget {
  final String tripId;
  const ManageParticipantsScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(participantsProvider(tripId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.membersAndNotesTitle)),
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
                        onPressed: () => _showEditDialog(context, ref, p),
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
    WidgetRef ref,
    Participant existing,
  ) async {
    final result = await showParticipantEditDialog(
      context,
      existing: existing,
      defaultColor: existing.color,
    );
    if (result == null || !context.mounted) return;

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
