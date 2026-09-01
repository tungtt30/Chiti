import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../widgets/participant_chips.dart';
import '../widgets/thousands_separator_input_formatter.dart';

enum _SponsorType { internal, external }

/// Create-or-edit sponsorship (Tài trợ) form for a trip.
///
/// A sponsorship is a fixed amount towards the group, either from an internal
/// member (picked from the participant list) or an external sponsor /
/// "Mạnh thường quân" (free-text name). The total sponsored reduces every
/// member's split proportionally.
class AddEditSponsorshipScreen extends ConsumerStatefulWidget {
  final String tripId;

  /// Pass [existing] to open in edit mode.
  final Sponsorship? existing;

  const AddEditSponsorshipScreen({
    super.key,
    required this.tripId,
    this.existing,
  });

  @override
  ConsumerState<AddEditSponsorshipScreen> createState() =>
      _AddEditSponsorshipScreenState();
}

class _AddEditSponsorshipScreenState
    extends ConsumerState<AddEditSponsorshipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  _SponsorType _type = _SponsorType.internal;
  String? _memberId;
  bool _memberInitialized = false;

  Sponsorship? get _existing => widget.existing;
  bool get _isEdit => _existing != null;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    if (e != null) {
      _type = e.isInternal ? _SponsorType.internal : _SponsorType.external;
      _memberId = e.memberId;
      _nameCtrl.text = e.sponsorName;
      _amountCtrl.text = ThousandsSeparatorInputFormatter.formatThousands(
        _displayAmount(e.amount),
      );
      _noteCtrl.text = e.note ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<Participant> _participants(WidgetRef ref) =>
      ref.read(participantsProvider(widget.tripId)).valueOrNull ?? [];

  String _currency() {
    final trip = ref.read(tripDetailProvider(widget.tripId)).valueOrNull;
    return trip?.currency ?? 'VND';
  }

  String _displayAmount(double value) {
    if (value == 0) return '0';
    final s = value.toStringAsFixed(2);
    if (s.endsWith('.00')) return s.substring(0, s.length - 3);
    return s;
  }

  double? _total() => double.tryParse(_amountCtrl.text.replaceAll(',', ''));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    final amount = _total() ?? 0;
    if (amount <= 0) {
      _showSnack(l10n.amountGreaterThanZero);
      return;
    }

    final users = _participants(ref);
    String sponsorName;
    String? memberId;
    if (_type == _SponsorType.internal) {
      final member = _memberId != null
          ? users.where((p) => p.id == _memberId).firstOrNull
          : null;
      if (member == null) {
        _showSnack(l10n.sponsorshipMemberHint);
        return;
      }
      sponsorName = member.name;
      memberId = member.id;
    } else {
      sponsorName = _nameCtrl.text.trim();
      if (sponsorName.isEmpty) {
        _showSnack(l10n.sponsorshipNameRequired);
        return;
      }
    }

    final note = _noteCtrl.text.trim().isEmpty
        ? null
        : _noteCtrl.text.trim();

    final notifier = ref.read(sponsorshipsProvider(widget.tripId).notifier);
    if (!_isEdit) {
      await notifier.addSponsorship(
        sponsorName: sponsorName,
        memberId: memberId,
        amount: amount,
        note: note,
      );
    } else {
      await notifier.updateSponsorship(
        _existing!.copyWith(
          sponsorName: sponsorName,
          memberId: memberId,
          amount: amount,
          note: note,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSponsorshipDialogTitle),
        content: Text(
          l10n.deleteSponsorshipDialogContent(
            formatCurrency(_existing?.amount ?? 0, _currency()),
            _existing?.sponsorName ?? '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final id = _existing!.id;
    if (mounted) Navigator.pop(context);
    await ref
        .read(sponsorshipsProvider(widget.tripId).notifier)
        .deleteSponsorship(id);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final participantsAsync = ref.watch(participantsProvider(widget.tripId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editSponsorship : l10n.addSponsorship),
        actions: [
          if (_isEdit)
            IconButton.filledTonal(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.deleteSponsorship,
              onPressed: _confirmDelete,
            ),
          TextButton(onPressed: _save, child: Text(l10n.save)),
        ],
      ),
      body: participantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorLabel(e.toString()))),
        data: (participants) {
          if (!_memberInitialized) {
            _memberInitialized = true;
            _memberId ??= participants.isNotEmpty ? participants.first.id : null;
          }

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Form(
              key: _formKey,
              child: ListView(
                primary: false,
                padding: const EdgeInsets.all(16),
                children: [
                  // ---- Sponsor type ----
                  Text(
                    l10n.sponsorshipType,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<_SponsorType>(
                    segments: [
                      ButtonSegment(
                        value: _SponsorType.internal,
                        icon: const Icon(Icons.person),
                        label: Text(l10n.sponsorshipTypeInternal),
                      ),
                      ButtonSegment(
                        value: _SponsorType.external,
                        icon: const Icon(Icons.volunteer_activism),
                        label: Text(l10n.sponsorshipTypeExternal),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (selection) =>
                        setState(() => _type = selection.first),
                  ),
                  const SizedBox(height: 16),

                  // ---- Sponsor picker ----
                  if (_type == _SponsorType.internal) ...[
                    Text(
                      l10n.sponsorshipSponsor,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (participants.isEmpty)
                      Text(
                        l10n.addParticipantsFirst,
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: participants.map((p) {
                          return ChoiceChip(
                            avatar:
                                ParticipantAvatar(participant: p, radius: 13),
                            label: Text(p.name),
                            selected: _memberId == p.id,
                            onSelected: (_) =>
                                setState(() => _memberId = p.id),
                          );
                        }).toList(),
                      ),
                  ] else ...[
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.sponsorshipSponsor,
                        hintText: l10n.sponsorshipNameHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.volunteer_activism),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.sponsorshipNameRequired
                          : null,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // ---- Amount ----
                  TextFormField(
                    controller: _amountCtrl,
                    inputFormatters: const [
                      ThousandsSeparatorInputFormatter(),
                    ],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.amount,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.monetization_on),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.required;
                      final n = double.tryParse(v.replaceAll(',', ''));
                      if (n == null || n <= 0) return l10n.amountMustBePositive;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ---- Note ----
                  TextFormField(
                    controller: _noteCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.sponsorshipNote,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(
                      _isEdit ? l10n.saveChanges : l10n.saveSponsorship,
                    ),
                  ),
                  if (_isEdit) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.deleteSponsorship),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}