import '../../core/constants.dart';

/// A logged expense. The total [amount] is always stored on the expense; the
/// payers (one or many, with the amount each paid) live in [ExpensePayer]
/// rows, and the per-person obligation lives in [ExpenseSplit] rows.
class Expense {
  final String id;
  final String tripId;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String splitMode; // one of SplitMode.*
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.splitMode = SplitMode.equal,
    required this.createdAt,
  });

  Expense copyWith({
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? splitMode,
  }) {
    return Expense(
      id: id,
      tripId: tripId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      splitMode: splitMode ?? this.splitMode,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'split_mode': splitMode,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      tripId: map['trip_id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      category: map['category'] as String,
      splitMode: (map['split_mode'] as String?) ?? SplitMode.equal,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
