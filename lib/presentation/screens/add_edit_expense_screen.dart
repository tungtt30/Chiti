import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/id_generator.dart';
import '../../core/settlement_calculator.dart';
import '../../data/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../widgets/participant_chips.dart';
import '../widgets/thousands_separator_input_formatter.dart';

/// Create-or-edit expense form for a trip.
///
/// Each expense is split equally among a selected subset of members; one
/// person pays the full amount. Pass [existing] to open in edit mode.
class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final String tripId;

  /// Pass [existing] to open in edit mode.
  final Expense? existing;

  /// When true, [existing] is used as a template: the form opens in create
  /// mode (fresh expense) but prefilled with the existing expense's values
  /// and participants (Nhân bản / duplicate).
  final bool duplicate;

  const AddEditExpenseScreen({
    super.key,
    required this.tripId,
    this.existing,
    this.duplicate = false,
  });

  @override
  ConsumerState<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  final Set<String> _selectedIds = {};
  String _payerId = '';
  String _category = ExpenseCategory.other;

  /// True while prefilled data is being loaded in edit mode; gates the lazy
  /// self-seed branch in build() so it cannot overwrite the loaded values.
  bool _loadingExisting = false;

  /// One-shot guard for the default selection seeding in create mode.
  bool _selectionInitialized = false;

  Expense? get _existing => widget.existing;

  /// Create-mode flag: a duplicate opens like a new expense but prefilled.
  bool get _isEdit => _existing != null && !widget.duplicate;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _amountCtrl.text = ThousandsSeparatorInputFormatter.formatThousands(
        _displayAmount(e.amount),
      );
      _payerId = e.payerId;
      _category = e.category;
      // Duplicates prefill the joined members too, then save as a new
      // expense (edit mode skips this and loads from the DB).
      _loadExisting();
    }
  }

  /// In edit mode, fetch the saved participating-member rows and pre-fill the
  /// selection.
  Future<void> _loadExisting() async {
    final e = _existing!;
    setState(() => _loadingExisting = true);
    final repo = ref.read(repositoryProvider);
    try {
      final participants = await repo.getExpenseParticipants(e.id);
      if (!mounted) return;
      _selectedIds
        ..clear()
        ..addAll(participants.map((p) => p.participantId));
      _selectionInitialized = true;
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  List<Participant> _participants(WidgetRef ref) =>
      ref.read(participantsProvider(widget.tripId)).valueOrNull ?? [];

  String _currency() {
    final trip = ref.read(tripDetailProvider(widget.tripId)).valueOrNull;
    return trip?.currency ?? 'VND';
  }

  void _onAmountChanged() => setState(() {});

  /// Parses the (possibly comma-grouped) amount field. Commas are stripped
  /// before numeric parsing.
  double? _total() => double.tryParse(_amountCtrl.text.replaceAll(',', ''));

  String _displayAmount(double value) {
    if (value == 0) return '0';
    final s = value.toStringAsFixed(2);
    if (s.endsWith('.00')) return s.substring(0, s.length - 3);
    return s;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    final total = _total() ?? 0;
    if (total <= 0) {
      _showSnack(l10n.amountGreaterThanZero);
      return;
    }
    final users = _participants(ref);
    if (_selectedIds.isEmpty) {
      _showSnack(l10n.selectParticipantToSplit);
      return;
    }
    if (_payerId.isEmpty ||
        !users.any((p) => p.id == _payerId)) {
      _showSnack(l10n.selectWhoPaid);
      return;
    }

    // Equal split among the selected subset, remainder on the last share.
    final shares = computeSubsetShares(
      total: total,
      selectedIds: _selectedIds.toList(),
      splitMode: 'equal',
    );
    final joined = _selectedIds
        .map(
          (id) => ExpenseParticipant(
            id: generateId(),
            expenseId: '',
            participantId: id,
            shareAmount: shares[id] ?? 0,
          ),
        )
        .toList();

    if (!_isEdit) {
      await ref
          .read(expensesProvider(widget.tripId).notifier)
          .createExpense(
            title: _titleCtrl.text.trim(),
            amount: total,
            payerId: _payerId,
            category: _category,
            participants: joined,
          );
    } else {
      final updated = _existing!.copyWith(
        title: _titleCtrl.text.trim(),
        amount: total,
        payerId: _payerId,
        category: _category,
      );
      await ref
          .read(expensesProvider(widget.tripId).notifier)
          .updateExpense(expense: updated, participants: joined);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteExpenseDialogTitle),
        content: Text(
          l10n.deleteExpenseDialogContent(
            _existing?.title ?? l10n.expenseTitle,
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
        .read(expensesProvider(widget.tripId).notifier)
        .deleteExpense(id);
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
        title: Text(_isEdit ? l10n.editExpense : l10n.addExpense),
        actions: [
          if (_isEdit)
            IconButton.filledTonal(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.deleteExpense,
              onPressed: _confirmDelete,
            ),
          TextButton(onPressed: _save, child: Text(l10n.save)),
        ],
      ),
      body: participantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorLabel(e.toString()))),
        data: (participants) {
          if (participants.isEmpty) {
            return Center(child: Text(l10n.addParticipantsFirst));
          }

          if (_loadingExisting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!_selectionInitialized) {
            _selectionInitialized = true;
            _selectedIds
              ..clear()
              ..addAll(participants.map((p) => p.id));
          }
          if (_payerId.isEmpty) {
            _payerId = participants.first.id;
          }

          // Instant on-the-spot calculation driving the live preview below.
          final previewTotal = _total() ?? 0;
          final shares = computeSubsetShares(
            total: previewTotal,
            selectedIds: _selectedIds.toList(),
            splitMode: 'equal',
          );

          return GestureDetector(
            // Dismiss the keyboard when tapping outside any input field.
            onTap: () => FocusScope.of(context).unfocus(),
            child: Form(
              key: _formKey,
              child: ListView(
                primary: false,
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.expenseTitle,
                      hintText: l10n.expenseTitleHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.required : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountCtrl,
                    onChanged: (_) => _onAmountChanged(),
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
                  _LiveSplitPreview(
                    total: previewTotal,
                    shares: shares,
                    payerId: _payerId,
                    selectedIds: _selectedIds,
                    participants: participants,
                    currency: _currency(),
                  ),
                  const SizedBox(height: 16),

                  // ---- Category ----
                  Text(
                    l10n.category,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ExpenseCategory.all.map((c) {
                      return ChoiceChip(
                        avatar: Text(ExpenseCategory.icons[c] ?? '📦'),
                        label: Text(ExpenseCategory.localizedLabel(c, l10n)),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ---- Who paid ----
                  Text(
                    l10n.whoPaid,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: participants.map((p) {
                      return ChoiceChip(
                        avatar: ParticipantAvatar(participant: p, radius: 13),
                        label: Text(p.name),
                        selected: _payerId == p.id,
                        onSelected: (_) => setState(() => _payerId = p.id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ---- Participants who joined ----
                  Text(
                    l10n.whoJoined,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l10n.selectedOfMembers(_selectedIds.length, participants.length)}'
                            '${previewTotal > 0 && _selectedIds.isNotEmpty
                                ? l10n.eachApprox(formatCurrency(previewTotal / _selectedIds.length, _currency()))
                                : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _selectedIds
                              ..clear()
                              ..addAll(participants.map((p) => p.id));
                          }),
                          child: Text(l10n.selectAll),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedIds.clear()),
                          child: Text(l10n.deselectAll),
                        ),
                      ],
                    ),
                  ),
                  ParticipantChipSelector(
                    participants: participants,
                    selectedIds: _selectedIds,
                    onChanged: (ids) => setState(() {
                      _selectedIds
                        ..clear()
                        ..addAll(ids);
                    }),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(_isEdit ? l10n.saveChanges : l10n.saveExpense),
                  ),
                  if (_isEdit) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.deleteExpense),
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

/// Reactive "on-the-spot" split preview.
///
/// Rebuilds on every amount keystroke or participant toggle and shows exactly
/// what each selected member owes for this single expense (equal split), plus
/// the payer's net impact.
class _LiveSplitPreview extends StatelessWidget {
  final double total;
  final Map<String, double> shares;
  final String payerId;
  final Set<String> selectedIds;
  final List<Participant> participants;
  final String currency;

  const _LiveSplitPreview({
    required this.total,
    required this.shares,
    required this.payerId,
    required this.selectedIds,
    required this.participants,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final nameMap = {for (final p in participants) p.id: p};
    final k = selectedIds.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(l10n.liveSplitPreview, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            if (k == 0)
              _banner(
                theme,
                l10n.joinPreviewText,
                isError: true,
              )
            else if (total <= 0)
              Text(
                l10n.enterAmountPreview,
                style: theme.textTheme.bodySmall,
              )
            else ...[
              Text(
                '${l10n.eachPaysPreview(formatCurrency(total / k, currency))} '
                '${l10n.participantsCount(k)}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final id in selectedIds)
                if (nameMap.containsKey(id))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        ParticipantAvatar(participant: nameMap[id]!, radius: 12),
                        const SizedBox(width: 8),
                        Expanded(child: Text(nameMap[id]!.name)),
                        Text(
                          formatCurrency(shares[id] ?? 0, currency),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              if (nameMap.containsKey(payerId)) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      ParticipantAvatar(
                        participant: nameMap[payerId]!,
                        radius: 12,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.payerSummary(
                            nameMap[payerId]!.name,
                            formatCurrency(total, currency),
                            selectedIds.contains(payerId)
                                ? ''
                                : l10n.notJoinedSuffix,
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      _netLabel(theme),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _netLabel(ThemeData theme) {
    final share = shares[payerId] ?? 0;
    final net = computePayerNetImpact(amountPaid: total, shareObligation: share);
    final sign = net >= 0 ? '+' : '-';
    return Text(
      '$sign${formatCurrency(net.abs(), currency)}',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: net >= 0 ? Colors.green.shade700 : theme.colorScheme.error,
      ),
    );
  }

  Widget _banner(ThemeData theme, String message, {required bool isError}) {
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isError ? scheme.errorContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.warning_amber : Icons.info_outline,
            size: 16,
            color: isError ? scheme.onErrorContainer : scheme.onSurface,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}