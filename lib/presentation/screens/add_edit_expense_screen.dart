import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/id_generator.dart';
import '../../core/settlement_calculator.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../widgets/participant_chips.dart';

/// Create-or-edit expense form for a trip.
///
/// Each expense is split equally among a selected subset of members; one
/// person pays the full amount. Pass [existing] to open in edit mode.
class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final String tripId;
  final Expense? existing;
  const AddEditExpenseScreen({super.key, required this.tripId, this.existing});

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
  String _category = ExpenseCategory.others;

  /// True while prefilled data is being loaded in edit mode; gates the lazy
  /// self-seed branch in build() so it cannot overwrite the loaded values.
  bool _loadingExisting = false;

  /// One-shot guard for the default selection seeding in create mode.
  bool _selectionInitialized = false;

  Expense? get _existing => widget.existing;

  bool get _isEdit => _existing != null;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _amountCtrl.text = _displayAmount(e.amount);
      _payerId = e.payerId;
      _category = e.category;
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

  double? _total() => double.tryParse(_amountCtrl.text);

  String _displayAmount(double value) {
    if (value == 0) return '0';
    final s = value.toStringAsFixed(2);
    if (s.endsWith('.00')) return s.substring(0, s.length - 3);
    return s;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final total = _total() ?? 0;
    if (total <= 0) {
      _showSnack('Amount must be greater than 0');
      return;
    }
    final users = _participants(ref);
    if (_selectedIds.isEmpty) {
      _showSnack('Select at least one participant to split');
      return;
    }
    if (_payerId.isEmpty ||
        !users.any((p) => p.id == _payerId)) {
      _showSnack('Select who paid');
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

    if (_existing == null) {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text(
          'Delete "${_existing?.title ?? 'this expense'}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (_isEdit)
            IconButton.filledTonal(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete expense',
              onPressed: _confirmDelete,
            ),
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: participantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (participants) {
          if (participants.isEmpty) {
            return const Center(child: Text('Add participants first'));
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
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Dinner at Beach, Grab to Hotel…',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountCtrl,
                    onChanged: (_) => _onAmountChanged(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return 'Must be > 0';
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
                    'Danh mục',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ExpenseCategory.all.map((c) {
                      return ChoiceChip(
                        avatar: Text(ExpenseCategory.icons[c] ?? '📦'),
                        label: Text(ExpenseCategory.label(c)),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ---- Who paid ----
                  Text(
                    'Who paid?',
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
                    'Who joined?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Selected: ${_selectedIds.length} of '
                            '${participants.length} members'
                            '${previewTotal > 0 && _selectedIds.isNotEmpty
                                ? ' (each ~ ${formatCurrency(previewTotal / _selectedIds.length, _currency())})'
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
                          child: const Text('Select All'),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedIds.clear()),
                          child: const Text('Deselect All'),
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
                    label: Text(_isEdit ? 'Save Changes' : 'Save Expense'),
                  ),
                  if (_isEdit) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Expense'),
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
                Text('Live Split Preview', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            if (k == 0)
              _banner(
                theme,
                'Chưa chọn người tham gia. Select who joined this expense.',
                isError: true,
              )
            else if (total <= 0)
              Text(
                'Nhập số tiền để xem mức chia ngay.',
                style: theme.textTheme.bodySmall,
              )
            else ...[
              Text(
                'Mỗi người đóng: ${formatCurrency(total / k, currency)} '
                '($k người tham gia)',
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
                          '${nameMap[payerId]!.name} paid '
                          '${formatCurrency(total, currency)}'
                          '${selectedIds.contains(payerId) ? '' : ' (không tham gia)'}',
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