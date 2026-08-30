import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settlement_calculator.dart';
import '../../data/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../widgets/participant_chips.dart';
import '../widgets/participant_edit_dialog.dart';

class ManageParticipantsScreen extends ConsumerWidget {
  final String tripId;

  /// Called when a member long-press chooses "View expense history" (the
  /// Summary tab of the parent trip screen).
  final VoidCallback? onOpenSummary;

  const ManageParticipantsScreen({
    super.key,
    required this.tripId,
    this.onOpenSummary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(participantsProvider(tripId));
    final trip = ref.watch(tripDetailProvider(tripId)).valueOrNull;
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

          return ListView(
            primary: false,
            semanticChildCount: participants.length,
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              if (trip != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: _SettlementSettingsCard(
                    trip: trip,
                    participants: participants,
                  ),
                ),
              for (final p in participants)
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: ParticipantAvatar(participant: p, radius: 22),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trip?.hostId == p.id ||
                            (trip?.hostId == null && p.id == participants.first.id))
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Tooltip(
                              message: l10n.hostBadge,
                              child: Text(
                                '👑',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ),
                      ],
                    ),
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
                    onLongPress: () => _showMemberActions(context, ref, p),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Long-press action sheet for a member: set as Host, view expense
  /// history (Summary tab), or remove from the group.
  Future<void> _showMemberActions(
    BuildContext context,
    WidgetRef ref,
    Participant p,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final trip = ref.read(tripDetailProvider(tripId)).valueOrNull;
    final isHost = trip?.hostId == p.id;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: ParticipantAvatar(participant: p, radius: 20),
              title: Text(p.name),
              subtitle: Text(
                isHost ? l10n.hostBadge : l10n.memberNotePlaceholder,
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
            ),
            const Divider(height: 1),
            if (!isHost)
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text(l10n.setAsHost),
                onTap: () => Navigator.pop(sheetContext, 'host'),
              ),
            if (isHost)
              ListTile(
                enabled: false,
                leading: const Icon(Icons.emoji_events),
                title: Text(l10n.setAsHost),
                subtitle: Text(l10n.hostAlready),
              ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(l10n.viewExpenseHistory),
              onTap: () => Navigator.pop(sheetContext, 'history'),
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
              title: Text(
                l10n.removeFromGroup,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () => Navigator.pop(sheetContext, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;

    switch (action) {
      case 'host':
        final current = ref.read(tripDetailProvider(tripId)).valueOrNull;
        if (current != null) {
          await ref
              .read(tripDetailProvider(tripId).notifier)
              .updateTrip(current.copyWith(hostId: p.id));
        }
      case 'history':
        onOpenSummary?.call();
      case 'remove':
        await _confirmRemove(context, ref, p);
    }
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

/// Settlement settings: Host / Treasurer mode vs peer-to-peer, plus the Host
/// picker shown only in host mode.
class _SettlementSettingsCard extends ConsumerWidget {
  final Trip trip;
  final List<Participant> participants;

  const _SettlementSettingsCard({
    required this.trip,
    required this.participants,
  });

  String get _tripId => trip.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final mode = SettlementMode.fromDbValue(trip.settlementMode);
    // Effective host: stored one, else the first member.
    final effectiveHostId =
        trip.hostId ?? (participants.isNotEmpty ? participants.first.id : null);
    final hostName = participants
        .where((p) => p.id == effectiveHostId)
        .map((p) => p.name)
        .firstOrNull;

    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.settlementModeTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            RadioGroup<bool>(
              groupValue: mode == SettlementMode.host,
              onChanged: (v) {
                if (v == null) return;
                ref
                    .read(tripDetailProvider(_tripId).notifier)
                    .updateTrip(
                      trip.copyWith(
                        settlementMode: v
                            ? SettlementMode.host.dbValue
                            : SettlementMode.peerToPeer.dbValue,
                      ),
                    );
              },
              child: Column(
                children: [
                  RadioListTile<bool>(
                    value: true,
                    title: Text(l10n.settlementModeHostLabel),
                    subtitle: Text(l10n.settlementModeHostHint),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<bool>(
                    value: false,
                    title: Text(l10n.settlementModePeerToPeerLabel),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            if (mode == SettlementMode.host) ...[
              const Divider(height: 8),
              DropdownButtonFormField<String>(
                key: const ValueKey('host_selector'),
                initialValue: effectiveHostId,
                decoration: InputDecoration(
                  labelText: l10n.selectHost,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.emoji_events_outlined),
                ),
                items: participants
                    .map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null || v == trip.hostId) return;
                  ref
                      .read(tripDetailProvider(_tripId).notifier)
                      .updateTrip(trip.copyWith(hostId: v));
                },
              ),
              const SizedBox(height: 4),
              if (hostName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.hostIs(hostName),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}