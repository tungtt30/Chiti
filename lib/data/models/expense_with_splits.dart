import 'expense.dart';
import 'expense_payer.dart';
import 'expense_split.dart';

/// A single expense bundled with its payer rows and per-person split rows.
///
/// Read-only aggregate used by the expense detail view. The union of
/// [splits]' participant ids is the sub-group that participated; every other
/// trip member is excluded and owes nothing for this expense.
class ExpenseWithSplits {
  final Expense expense;
  final List<ExpensePayer> payers;
  final List<ExpenseSplit> splits;

  const ExpenseWithSplits({
    required this.expense,
    required this.payers,
    required this.splits,
  });
}