import '../data/models/models.dart';
import '../l10n/app_localizations.dart';
import 'constants.dart';
import 'formatters.dart';

/// Builds the plain-text trip report for group-chat sharing (Zalo / Telegram /
/// Messenger).
String buildTripReportText({
  required AppLocalizations l10n,
  required String tripName,
  required String currency,
  required TripSummaryStats stats,
  required Map<String, String> nameMap,
}) {
  final buf = StringBuffer();

  buf.writeln('🧾 ${l10n.reportTitle(tripName)}');
  buf.writeln(
    '💰 ${l10n.reportTotalAverage(formatCurrency(stats.totalSpent, currency), formatCurrency(stats.averagePerMember, currency))}',
  );

  if (stats.expenseCount > 0) {
    buf.write('\n👥 ${l10n.reportMembersHeader}\n');
    for (final m in stats.members) {
      final netText = switch (m.net) {
        > 0.01 => l10n.reportNetReceiveBack(
          formatCurrency(m.net, currency),
        ),
        < -0.01 => l10n.reportNetPayMore(
          formatCurrency(m.net.abs(), currency),
        ),
        _ => l10n.reportNetSettled,
      };
      buf.writeln(
        l10n.reportMemberLine(
          m.name,
          formatCurrency(m.paid, currency),
          formatCurrency(m.consumed, currency),
          m.joinedCount,
          m.totalBillsCount,
          netText,
        ),
      );
    }

    buf.writeln('\n📊 ${l10n.reportCategoriesHeader}');
    for (final c in stats.categories) {
      final pct = (c.percent * 100).round();
      buf.writeln(
        l10n.reportCategoryLine(
          c.emoji,
          ExpenseCategory.localizedLabel(c.categoryId, l10n),
          formatCurrency(c.total, currency),
          pct,
        ),
      );
    }
  }

  buf.writeln('\n➡ ${l10n.reportSettlementsHeader}');
  if (stats.settlements.isEmpty) {
    buf.writeln(l10n.reportAllSettled);
  } else {
    for (final s in stats.settlements) {
      final from = nameMap[s.fromParticipantId] ?? '?';
      final to = nameMap[s.toParticipantId] ?? '?';
      buf.writeln(
        l10n.reportSettlementLine(
          from,
          to,
          formatCurrency(s.amount, currency),
          s.isPaid ? ' ✅' : '',
        ),
      );
    }
    buf.writeln(
      l10n.reportPaidProgress(
        stats.paidSettlementsCount,
        stats.settlements.length,
      ),
    );
  }

  return buf.toString().trim();
}

/// Single settlement transfer line for the per-card "Copy" action.
String buildTransferText({
  required AppLocalizations l10n,
  required String fromName,
  required String toName,
  required double amount,
  required String currency,
}) {
  return l10n.transferReportLine(fromName, toName, formatCurrency(amount, currency));
}