import 'package:flutter_test/flutter_test.dart';

import 'package:chiti/core/trip_report_text.dart';
import 'package:chiti/data/models/models.dart';
import 'package:chiti/l10n/app_localizations_vi.dart';

void main() {
  final stats = TripSummaryStats(
    totalSpent: 360,
    averagePerMember: 180,
    expenseCount: 2,
    topExpense: const TopExpense(
      id: 'e2',
      title: 'Taxi',
      amount: 260,
      payerId: 'a',
    ),
    categories: const [
      CategoryStat(
        categoryId: 'Food',
        label: 'Ăn uống',
        emoji: '🍽️',
        total: 100,
        percent: 0.27777777777,
      ),
      CategoryStat(
        categoryId: 'Transport',
        label: 'Di chuyển',
        emoji: '🚗',
        total: 260,
        percent: 0.72222222222,
      ),
    ],
    members: const [
      MemberStat(
        participantId: 'a',
        name: 'Alice',
        paid: 300,
        consumed: 180,
        net: 120,
        joinedCount: 2,
        totalBillsCount: 2,
        participationRate: 1,
      ),
      MemberStat(
        participantId: 'b',
        name: 'Bob',
        paid: 60,
        consumed: 180,
        net: -120,
        joinedCount: 2,
        totalBillsCount: 2,
        participationRate: 1,
      ),
    ],
    settlements: [
      Settlement(
        id: 's1',
        tripId: 'trip-1',
        fromParticipantId: 'b',
        toParticipantId: 'a',
        amount: 120,
        isPaid: false,
        createdAt: DateTime(2026),
      ),
    ],
    paidSettlementsCount: 0,
  );

  test('buildTripReportText contains header, members, categories, transfers',
      () {
    final text = buildTripReportText(
      l10n: AppLocalizationsVi(),
      tripName: 'Phố Cổ',
      currency: 'VND',
      stats: stats,
      nameMap: const {'a': 'Alice', 'b': 'Bob'},
    );

    expect(text, contains('BÁO CÁO CHUYẾN ĐI "Phố Cổ"'));
    expect(text, contains('Alice'));
    expect(text, contains('Bob'));
    expect(text, contains('Ăn uống'));
    expect(text, contains('chuyển cho'));
    expect(text, contains('0/1'));
  });

  test('report with no settlements shows the balanced message', () {
    final empty = stats.copyWith(
      settlements: const [],
      paidSettlementsCount: 0,
    );
    final text = buildTripReportText(
      l10n: AppLocalizationsVi(),
      tripName: 'Phố Cổ',
      currency: 'VND',
      stats: empty,
      nameMap: const {'a': 'Alice', 'b': 'Bob'},
    );

    expect(text, contains('không cần chuyển khoản'));
    expect(text, isNot(contains('chuyển cho')));
  });

  test('buildTransferText formats a single transfer line', () {
    final line = buildTransferText(
      l10n: AppLocalizationsVi(),
      fromName: 'Bob',
      toName: 'Alice',
      amount: 120,
      currency: 'VND',
    );
    expect(line, contains('Bob chuyển cho Alice'));
    expect(line, contains('120'));
  });
}