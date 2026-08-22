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
/// Pass [existing] to open in edit mode (fields are pre-filled from the saved
/// expense, its payers and per-person splits); leave it null for create mode.
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
  final Map<String, TextEditingController> _payerCtrls = {};
  final Map<String, TextEditingController> _amountCtrls = {};
  final Map<String, TextEditingController> _weightCtrls = {};
  final Map<String, TextEditingController> _noteCtrls = {};

  DateTime _date = DateTime.now();
  String _category = ExpenseCategory.food;
  String _splitMode = SplitMode.equal;
  bool _shared = true;
  bool _multiPayer = false;
  final Set<String> _selectedIds = {};
  final Set<String> _payerIds = {};

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
      _date = e.date;
      _category = e.category;
      _splitMode = e.splitMode;
      _loadExisting();
    }
  }

  /// In edit mode, fetch the saved payer/split rows and pre-fill the form.
  Future<void> _loadExisting() async {
    final e = _existing!;
    setState(() => _loadingExisting = true);
    final repo = ref.read(repositoryProvider);
    try {
      final payers = await repo.getExpensePayers(e.id);
      final splits = await repo.getExpenseSplits(e.id);
      if (!mounted) return;

      _multiPayer = payers.length > 1;
      if (_multiPayer) {
        _payerIds.addAll(payers.map((p) => p.participantId));
        for (final p in payers) {
          _payerCtrls.putIfAbsent(
            p.participantId,
            () => TextEditingController(),
          ).text = _displayAmount(p.amount);
        }
      } else if (payers.isNotEmpty) {
        _payerIds.add(payers.first.participantId);
      }

      _selectedIds.addAll(splits.map((s) => s.participantId));

      final participants =
          ref.read(participantsProvider(widget.tripId)).valueOrNull ?? [];
      _shared = splits.length == participants.length && participants.isNotEmpty;

      if (_splitMode == SplitMode.customAmount) {
        for (final s in splits) {
          _amountCtrls.putIfAbsent(
            s.participantId,
            () => TextEditingController(),
          ).text = _displayAmount(s.amount);
        }
      } else if (_splitMode == SplitMode.customWeight) {
        for (final s in splits) {
          _weightCtrls.putIfAbsent(
            s.participantId,
            () => TextEditingController(),
          ).text = _displayAmount(s.weight ?? 1);
        }
      }
      for (final s in splits) {
        final note = s.note;
        if (note != null && note.isNotEmpty) {
          _noteCtrls.putIfAbsent(
            s.participantId,
            () => TextEditingController(),
          ).text = note;
        }
      }
      _selectionInitialized = true;
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    for (final c in _payerCtrls.values) {
      c.dispose();
    }
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    for (final c in _weightCtrls.values) {
      c.dispose();
    }
    for (final c in _noteCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<Participant> _participants(WidgetRef ref) =>
      ref.read(participantsProvider(widget.tripId)).valueOrNull ?? [];

  String _currency() {
    final trip = ref.read(tripDetailProvider(widget.tripId)).valueOrNull;
    return trip?.currency ?? 'VND';
  }

  void _setShared(bool value) {
    setState(() {
      _shared = value;
      if (value) {
        _selectedIds
          ..clear()
          ..addAll(_participants(ref).map((p) => p.id));
        _splitMode = SplitMode.equal;
      }
    });
  }

  void _onAmountChanged() => setState(() {});

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  double? _total() => double.tryParse(_amountCtrl.text);

  void _applyEqualSplit() {
    if (_selectedIds.isEmpty) return;
    final total = _total() ?? 0;
    if (total <= 0) return;
    setState(() {
      _splitMode = SplitMode.equal;
      final ids = _selectedIds.toList();
      final perHead = splitEqually(total: total, count: ids.length);
      for (var i = 0; i < ids.length; i++) {
        _amountCtrls.putIfAbsent(ids[i], () => TextEditingController()).text =
            _displayAmount(perHead[i]);
      }
    });
  }

  void _enterCustomAmounts() {
    if (_selectedIds.isEmpty) return;
    final total = _total() ?? 0;
    final perHead = total > 0
        ? splitEqually(total: total, count: _selectedIds.length)
        : List.filled(_selectedIds.length, 0.0);
    setState(() {
      _splitMode = SplitMode.customAmount;
      final ids = _selectedIds.toList();
      for (var i = 0; i < ids.length; i++) {
        final ctrl = _amountCtrls.putIfAbsent(
          ids[i],
          () => TextEditingController(),
        );
        ctrl.text = _displayAmount(perHead[i]);
      }
    });
  }

  void _enterWeights() {
    if (_selectedIds.isEmpty) return;
    setState(() {
      _splitMode = SplitMode.customWeight;
      for (final id in _selectedIds) {
        _weightCtrls.putIfAbsent(id, () => TextEditingController(text: '1'));
      }
    });
  }

  String _displayAmount(double value) {
    if (value == 0) return '0';
    final s = value.toStringAsFixed(2);
    if (s.endsWith('.00')) return s.substring(0, s.length - 3);
    return s;
  }

  /// Builds payer rows (single or multi) enforcing the sum equals the total.
  List<ExpensePayer>? _buildPayers(double total) {
    final payers = <ExpensePayer>[];
    double payerTotal = 0;
    if (!_multiPayer) {
      final pid = _payerIds.first;
      payers.add(
        ExpensePayer(
          id: generateId(),
          expenseId: '',
          participantId: pid,
          amount: total,
        ),
      );
      payerTotal = total;
    } else {
      for (final pid in _payerIds) {
        final amt = double.tryParse(_payerCtrls[pid]?.text ?? '') ?? 0;
        payerTotal += amt;
        if (amt > 0) {
          payers.add(
            ExpensePayer(
              id: generateId(),
              expenseId: '',
              participantId: pid,
              amount: amt,
            ),
          );
        }
      }
    }
    if (payers.isEmpty || (payerTotal - total).abs() > 0.01) {
      _showSnack(
        'Payer amounts (${_displayAmount(payerTotal)}) must sum to the total '
        '(${_displayAmount(total)})',
      );
      return null;
    }
    return payers;
  }

  /// Builds split rows by mode; returns null if custom amounts fail to sum.
  List<ExpenseSplit>? _buildSplits(double total) {
    final splits = <ExpenseSplit>[];
    final ids = _selectedIds.toList();
    switch (_splitMode) {
      case SplitMode.customAmount:
        double splitSum = 0;
        for (final pid in ids) {
          final amt = double.tryParse(_amountCtrls[pid]?.text ?? '') ?? 0;
          splitSum += amt;
          splits.add(
            ExpenseSplit(
              id: generateId(),
              expenseId: '',
              participantId: pid,
              amount: amt,
              note: _noteOf(pid),
            ),
          );
        }
        if ((splitSum - total).abs() > 0.01) {
          _showSnack('Custom amounts must sum to the total');
          return null;
        }
      case SplitMode.customWeight:
        final weights = ids
            .map((pid) => double.tryParse(_weightCtrls[pid]?.text ?? '0') ?? 0)
            .toList();
        if (weights.any((w) => w < 0)) {
          _showSnack('Weights cannot be negative');
          return null;
        }
        final shares = splitByWeight(total: total, weights: weights);
        for (var i = 0; i < ids.length; i++) {
          splits.add(
            ExpenseSplit(
              id: generateId(),
              expenseId: '',
              participantId: ids[i],
              amount: shares[i],
              weight: weights[i], // keep raw weight for re-editing
              note: _noteOf(ids[i]),
            ),
          );
        }
      default: // SplitMode.equal
        final shares = splitEqually(total: total, count: ids.length);
        for (var i = 0; i < ids.length; i++) {
          splits.add(
            ExpenseSplit(
              id: generateId(),
              expenseId: '',
              participantId: ids[i],
              amount: shares[i],
              note: _noteOf(ids[i]),
            ),
          );
        }
    }
    return splits;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final total = _total() ?? 0;
    if (total <= 0) {
      _showSnack('Amount must be greater than 0');
      return;
    }
    if (_selectedIds.isEmpty) {
      _showSnack('Select at least one participant to split');
      return;
    }
    if (_payerIds.isEmpty) {
      _showSnack('Select who paid');
      return;
    }

    final payers = _buildPayers(total);
    if (payers == null) return;
    final splits = _buildSplits(total);
    if (splits == null) return;

    if (_existing == null) {
      await ref
          .read(expensesProvider(widget.tripId).notifier)
          .createExpense(
            title: _titleCtrl.text.trim(),
            amount: total,
            date: _date,
            category: _category,
            splitMode: _splitMode,
            payers: payers,
            splits: splits,
          );
    } else {
      final updated = _existing!.copyWith(
        title: _titleCtrl.text.trim(),
        amount: total,
        date: _date,
        category: _category,
        splitMode: _splitMode,
      );
      await ref
          .read(expensesProvider(widget.tripId).notifier)
          .updateExpense(expense: updated, payers: payers, splits: splits);
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

  String? _noteOf(String pid) {
    final n = _noteCtrls[pid]?.text.trim();
    return (n == null || n.isEmpty) ? null : n;
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
            if (_selectedIds.isEmpty) {
              _selectedIds
                ..clear()
                ..addAll(participants.map((p) => p.id));
            }
            if (_payerIds.isEmpty) {
              _payerIds.add(participants.first.id);
            }
          }

          // Instant on-the-spot calculation driving the live preview below.
          final previewTotal = _total() ?? 0;
          final shares = computeSubsetShares(
            total: previewTotal,
            selectedIds: _selectedIds.toList(),
            splitMode: _splitMode,
            customAmounts: {
              for (final id in _selectedIds)
                id: double.tryParse(_amountCtrls[id]?.text ?? '') ?? 0,
            },
            weights: {
              for (final id in _selectedIds)
                id: double.tryParse(_weightCtrls[id]?.text ?? '0') ?? 0,
            },
          );
          final payerAmounts = <String, double>{};
          if (_payerIds.isNotEmpty) {
            if (_multiPayer) {
              for (final id in _payerIds) {
                payerAmounts[id] =
                    double.tryParse(_payerCtrls[id]?.text ?? '') ?? 0;
              }
            } else {
              payerAmounts[_payerIds.first] = previewTotal;
            }
          }

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
                    payerAmounts: payerAmounts,
                    payerIds: _payerIds,
                    selectedIds: _selectedIds,
                    splitMode: _splitMode,
                    participants: participants,
                    currency: _currency(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: ExpenseCategory.all
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text('${ExpenseCategory.icons[c]} $c'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _category = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(4),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(formatDateShort(_date)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ---- Payer section ----
                  const _SectionTitle(
                    icon: Icons.payments_outlined,
                    title: 'Who paid?',
                  ),
                  SegmentedButton<bool>(
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('One person'),
                        icon: Icon(Icons.person),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Multiple'),
                        icon: Icon(Icons.groups),
                      ),
                    ],
                    selected: {_multiPayer},
                    onSelectionChanged: (s) =>
                        setState(() => _multiPayer = s.first),
                  ),
                  const SizedBox(height: 12),
                  if (!_multiPayer)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: participants.map((p) {
                        final selected = _payerIds.contains(p.id);
                        return ChoiceChip(
                          avatar: ParticipantAvatar(participant: p, radius: 13),
                          label: Text(p.name),
                          selected: selected,
                          onSelected: (_) => setState(() {
                            _payerIds
                              ..clear()
                              ..add(p.id);
                          }),
                        );
                      }).toList(),
                    )
                  else
                    Column(
                      children: participants.map((p) {
                        final checked = _payerIds.contains(p.id);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Checkbox(
                                value: checked,
                                onChanged: (v) => setState(() {
                                  if (v ?? false) {
                                    _payerIds.add(p.id);
                                  } else {
                                    _payerIds.remove(p.id);
                                  }
                                }),
                              ),
                              ParticipantAvatar(participant: p, radius: 15),
                              const SizedBox(width: 8),
                              Expanded(child: Text(p.name)),
                              SizedBox(
                                width: 110,
                                child: TextField(
                                  controller: _payerCtrls.putIfAbsent(
                                    p.id,
                                    () => TextEditingController(),
                                  ),
                                  enabled: checked,
                                  onChanged: (_) => setState(() {}),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    hintText: '0',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),

                  // ---- Split section ----
                  const _SectionTitle(icon: Icons.call_split, title: 'Split'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Shared expense (everyone)'),
                    subtitle: Text(
                      _shared
                          ? 'Split equally among all members'
                          : 'Choose who splits this expense',
                    ),
                    value: _shared,
                    onChanged: (v) => _setShared(v),
                  ),
                  if (!_shared) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Split among: ${_selectedIds.length} of '
                              '${participants.length} members selected',
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
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Split Equally'),
                        avatar: const Icon(Icons.content_cut, size: 16),
                        selected: _splitMode == SplitMode.equal,
                        onSelected: (_) => _applyEqualSplit(),
                      ),
                      ChoiceChip(
                        label: const Text('Custom Amounts'),
                        selected: _splitMode == SplitMode.customAmount,
                        onSelected: (_) => _enterCustomAmounts(),
                      ),
                      ChoiceChip(
                        label: const Text('Weights'),
                        selected: _splitMode == SplitMode.customWeight,
                        onSelected: (_) => _enterWeights(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSplitInputs(participants),
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

  Widget _buildSplitInputs(List<Participant> participants) {
    final total = _total() ?? 0;
    final ids = _selectedIds.toList();
    if (ids.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Select at least one participant above.'),
      );
    }

    final isAmount = _splitMode == SplitMode.customAmount;
    final isWeight = _splitMode == SplitMode.customWeight;

    return Column(
      children: ids.map((pid) {
        final p = participants.firstWhere(
          (e) => e.id == pid,
          orElse: () => participants.first,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ParticipantAvatar(participant: p, radius: 14),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.name)),
                  if (isAmount)
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _amountCtrls.putIfAbsent(
                          pid,
                          () => TextEditingController(),
                        ),
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          hintText: '0',
                        ),
                      ),
                    )
                  else if (isWeight)
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _weightCtrls.putIfAbsent(
                          pid,
                          () => TextEditingController(),
                        ),
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          hintText: 'weight',
                        ),
                      ),
                    )
                  else
                    Text(
                      '≈ ${formatCurrency(splitEqually(total: total, count: ids.length)[ids.indexOf(pid)], _currency())}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextField(
                  controller: _noteCtrls.putIfAbsent(
                    pid,
                    () => TextEditingController(),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Note for ${p.name} (optional)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(
                      Icons.sticky_note_2_outlined,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// Reactive "on-the-spot" split preview.
///
/// Rebuilds on every amount keystroke or participant toggle and shows exactly
/// what each selected member owes for this single expense, plus each payer's
/// net impact (credit for paying, minus their own share when participating).
class _LiveSplitPreview extends StatelessWidget {
  final double total;
  final Map<String, double> shares;
  final Map<String, double> payerAmounts;
  final Set<String> payerIds;
  final Set<String> selectedIds;
  final String splitMode;
  final List<Participant> participants;
  final String currency;

  const _LiveSplitPreview({
    required this.total,
    required this.shares,
    required this.payerAmounts,
    required this.payerIds,
    required this.selectedIds,
    required this.splitMode,
    required this.participants,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameMap = {for (final p in participants) p.id: p};
    final k = selectedIds.length;

    final customSum =
        splitMode == SplitMode.customAmount
            ? shares.values.fold(0.0, (a, b) => a + b)
            : total;
    final payerSum = payerAmounts.values.fold(0.0, (a, b) => a + b);
    final amountsMismatch = total > 0 && (customSum - total).abs() > 0.01;
    final payersMismatch =
        total > 0 && payerIds.isNotEmpty && (payerSum - total).abs() > 0.01;

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
              if (splitMode == SplitMode.equal)
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
              if (payerIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                for (final entry in payerAmounts.entries)
                  if (nameMap.containsKey(entry.key))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          ParticipantAvatar(
                            participant: nameMap[entry.key]!,
                            radius: 12,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${nameMap[entry.key]!.name} paid '
                              '${formatCurrency(entry.value, currency)}'
                              '${selectedIds.contains(entry.key) ? '' : ' (không tham gia)'}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          _netLabel(theme, entry.key, entry.value),
                        ],
                      ),
                    ),
              ],
              if (amountsMismatch)
                _banner(
                  theme,
                  'Tổng tiền chia (${formatCurrency(customSum, currency)}) '
                  'không khớp với số tiền (${formatCurrency(total, currency)}).',
                  isError: true,
                ),
              if (payersMismatch)
                _banner(
                  theme,
                  'Tổng tiền trả (${formatCurrency(payerSum, currency)}) '
                  'không khớp với số tiền (${formatCurrency(total, currency)}).',
                  isError: true,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _netLabel(ThemeData theme, String participantId, double paid) {
    final share = shares[participantId] ?? 0;
    final net = computePayerNetImpact(amountPaid: paid, shareObligation: share);
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