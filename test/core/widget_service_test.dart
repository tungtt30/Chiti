import 'package:flutter_test/flutter_test.dart';

import 'package:chiti/core/services/widget_service.dart';
import 'package:chiti/data/models/models.dart';
import 'package:chiti/l10n/app_localizations_vi.dart';

Trip _trip({String? hostId, String currency = 'VND'}) => Trip(
  id: 't1',
  name: 'Nhóm cầu lông',
  destination: '',
  currency: currency,
  startDate: DateTime(2026, 8, 1),
  endDate: DateTime(2026, 8, 1),
  createdAt: DateTime(2026, 8, 1),
  hostId: hostId,
);

MemberStat _member(String id, String name, double net) => MemberStat(
  participantId: id,
  name: name,
  paid: 0,
  consumed: 0,
  net: net,
  joinedCount: 0,
  totalBillsCount: 1,
  participationRate: 0,
);

TripSummaryStats _stats({
  List<MemberStat> members = const [],
  double totalSpent = 1200000,
}) => TripSummaryStats(
  totalSpent: totalSpent,
  averagePerMember: totalSpent / (members.isEmpty ? 1 : members.length),
  expenseCount: 1,
  topExpense: null,
  categories: const [],
  members: members,
  settlements: const [],
  paidSettlementsCount: 0,
);

void main() {
  final l10n = AppLocalizationsVi();

  group('buildWidgetPayload', () {
    test('host owes money -> "Phải đóng" in red', () {
      final payload = buildWidgetPayload(
        trip: _trip(hostId: 'host'),
        stats: _stats(members: [_member('host', 'Host', -200000)]),
        l10n: l10n,
      );

      expect(payload.hasData, isTrue);
      expect(payload.groupName, 'Nhóm cầu lông');
      expect(payload.tripId, 't1');
      expect(payload.netColor, 'red');
      expect(payload.netLabel, 'Phải đóng: ₫200,000');
      expect(payload.totalSpent, 'Tổng chi tiêu nhóm: ₫1,200,000');
    });

    test('host is owed money -> "Được nhận" in green', () {
      final payload = buildWidgetPayload(
        trip: _trip(hostId: 'host'),
        stats: _stats(members: [_member('host', 'Host', 150000)]),
        l10n: l10n,
      );

      expect(payload.netColor, 'green');
      expect(payload.netLabel, 'Được nhận: ₫150,000');
    });

    test('host balanced -> neutral "Đã cân bằng"', () {
      final payload = buildWidgetPayload(
        trip: _trip(hostId: 'host'),
        stats: _stats(members: [_member('host', 'Host', 0)]),
        l10n: l10n,
      );

      expect(payload.netColor, 'neutral');
      expect(payload.netLabel, 'Đã cân bằng');
    });

    test('no host id -> falls back to the first member', () {
      final payload = buildWidgetPayload(
        trip: _trip(),
        stats: _stats(
          members: [
            _member('p1', 'Alice', -30000),
            _member('p2', 'Bob', 30000),
          ],
        ),
        l10n: l10n,
      );

      expect(payload.tripId, 't1');
      expect(payload.netColor, 'red');
      expect(payload.netLabel, 'Phải đóng: ₫30,000');
    });

    test('no members -> placeholder (hasData false)', () {
      final payload = buildWidgetPayload(
        trip: _trip(hostId: 'host'),
        stats: _stats(members: const []),
        l10n: l10n,
      );

      expect(payload.hasData, isFalse);
      expect(payload.groupName, isNull);
      expect(payload.tripId, isNull);
    });

    test('host id missing from members -> first member wins', () {
      final payload = buildWidgetPayload(
        trip: _trip(hostId: 'ghost'),
        stats: _stats(members: [_member('p1', 'Alice', 5000)]),
        l10n: l10n,
      );

      expect(payload.netColor, 'green');
    });
  });
}