import 'expense.dart';
import 'expense_participant.dart';

/// A single expense bundled with the participating members and their shares.
///
/// Read-only aggregate used by the expense detail view. The union of
/// [participants]' member ids is the sub-group that joined; every other trip
/// member is excluded and owes nothing for this expense.
class ExpenseWithParticipants {
  final Expense expense;
  final List<ExpenseParticipant> participants;

  const ExpenseWithParticipants({
    required this.expense,
    required this.participants,
  });
}