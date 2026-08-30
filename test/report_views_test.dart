import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chiti/core/utils/image_exporter.dart';
import 'package:chiti/data/models/models.dart';
import 'package:chiti/l10n/app_localizations.dart';
import 'package:chiti/presentation/widgets/expenses/expense_report_view.dart';
import 'package:chiti/presentation/widgets/summary/summary_report_view.dart';

Trip _trip() => Trip(
  id: 't1',
  name: 'Da Nang Trip',
  destination: 'Da Nang',
  currency: 'VND',
  startDate: DateTime(2026, 8, 1),
  endDate: DateTime(2026, 8, 5),
  createdAt: DateTime(2026, 7, 1),
  hostId: 'p1',
);

List<Participant> _participants() => [
  Participant(
    id: 'p1',
    tripId: 't1',
    name: 'Alice',
    color: 0xFFE57373,
    createdAt: DateTime(2026, 7, 1),
  ),
];

Settlement _settlement() => Settlement(
  id: 's1',
  tripId: 't1',
  fromParticipantId: 'p1',
  toParticipantId: 'p2',
  amount: 120000,
  isPaid: false,
  createdAt: DateTime(2026, 8, 6),
);

Expense _expense() => Expense(
  id: 'e1',
  tripId: 't1',
  title: 'Dinner',
  amount: 300000,
  payerId: 'p1',
  category: 'Food',
  createdAt: DateTime(2026, 8, 2),
);

TripSummaryStats _stats() {
  return TripSummaryStats(
    totalSpent: 300000,
    averagePerMember: 150000,
    expenseCount: 1,
    topExpense: TopExpense(
      id: 'e1',
      title: 'Dinner',
      amount: 300000,
      payerId: 'p1',
    ),
    categories: const [
      CategoryStat(
        categoryId: 'Food',
        label: 'Food',
        emoji: '🍽️',
        total: 300000,
        percent: 1.0,
      ),
    ],
    members: const [
      MemberStat(
        participantId: 'p1',
        name: 'Alice',
        paid: 300000,
        consumed: 150000,
        net: 150000,
        joinedCount: 1,
        totalBillsCount: 1,
        participationRate: 1.0,
      ),
    ],
    settlements: [_settlement()],
    paidSettlementsCount: 0,
  );
}

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: Center(child: child))),
);

void main() {
  testWidgets('SummaryReportView renders all sections without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SummaryReportView(
          trip: _trip(),
          stats: _stats(),
          participants: _participants(),
          hostId: 'p1',
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Da Nang Trip'), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
    expect(find.textContaining('300'), findsWidgets);
    expect(find.textContaining('Host'), findsWidgets);
  });

  testWidgets('ExpenseReportView renders expense rows', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ExpenseReportView(
          trip: _trip(),
          expenses: [_expense()],
          participants: _participants(),
          joinedCount: {'e1': 2},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.textContaining('Paid by Alice'), findsOneWidget);
    expect(find.textContaining('300'), findsWidgets);
  });

  testWidgets('ImageExporter captures a report as PNG bytes', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox(width: 100, height: 100)));

    // Phase 1: mount the invisible capture entry (sync, real tree).
    final capture = ImageExporter.startCapture(
      report: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Container(width: 200, height: 200, color: Colors.white)],
      ),
      context: tester.element(find.byType(Scaffold)),
      maxWidth: 200,
    );
    await tester.pump(); // build + paint the entry.

    // Phase 2: rasterize — all engine work inside a single runAsync window.
    final bytes = (await tester.runAsync(
      () => capture.rasterize(pixelRatio: 1.0, delay: Duration.zero),
    ))!;

    // Phase 3: teardown.
    capture.dispose();
    await tester.pump();

    expect(bytes.length, greaterThan(8));
    // PNG magic bytes.
    expect(bytes[0], 0x89);
    expect(bytes[1], 0x50);
    expect(bytes[2], 0x4E);
    expect(bytes[3], 0x47);
  });

  testWidgets(
    'captures the full SummaryReportView without errors or gray image',
    (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(width: 100, height: 100)));

      // Regression guard: the report uses AppLocalizations / formatCurrency /
      // formatDate, which used to break in isolated capture pipelines
      // (missing Localizations) and produced an empty gray image.
      final capture = ImageExporter.startCapture(
        report: SummaryReportView(
          trip: _trip(),
          stats: _stats(),
          participants: _participants(),
          hostId: 'p1',
        ),
        context: tester.element(find.byType(Scaffold)),
        maxWidth: 360,
      );
      await tester.pump(); // builds the real report in-tree; errors surface here.

      final bytes = (await tester.runAsync(
        () => capture.rasterize(pixelRatio: 2.0, delay: Duration.zero),
      ))!;
      capture.dispose();
      await tester.pump();

      // No build/layout exceptions surfaced in the test tree.
      expect(tester.takeException(), isNull);
      expect(bytes.length, greaterThan(1000));
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x4E);
      expect(bytes[3], 0x47);
    },
  );
}