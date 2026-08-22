import '../core/formatters.dart';
import '../data/models/models.dart';

/// Builds the plain-text trip report for group-chat sharing (Zalo / Telegram /
/// Messenger).
///
/// Example:
/// ─────────────────────────────
/// 🧾 BÁO CÁO CHUYẾN ĐI "Phố Cổ"
/// 💰 Tổng chi tiêu: 1.500.000 ₫ · Trung bình: 375.000 ₫/người
/// 👥 Thành viên:
/// • Vũ Ngọc Linh — đã ứng: 500.000 ₫ · đã tiêu: 400.000 ₫ · nhận lại: +100.000 ₫
/// ➡ Thanh toán:
/// • Nguyễn Văn A chuyển cho Trần Thị B: 250.000 ₫
/// ✅ Đã thanh toán: 0/1
/// ─────────────────────────────
String buildTripReportText({
  required String tripName,
  required String currency,
  required TripSummaryStats stats,
  required Map<String, String> nameMap,
}) {
  final buf = StringBuffer();

  buf.writeln('🧾 BÁO CÁO CHUYẾN ĐI "$tripName"');
  buf.writeln(
    '💰 Tổng chi tiêu: ${formatCurrency(stats.totalSpent, currency)} '
    '· Trung bình: ${formatCurrency(stats.averagePerMember, currency)}/người',
  );

  if (stats.expenseCount > 0) {
    buf.write('\n👥 Thành viên:\n');
    for (final m in stats.members) {
      final netText = switch (m.net) {
        > 0.01 => 'nhận lại: +${formatCurrency(m.net, currency)}',
        < -0.01 => 'đóng thêm: ${formatCurrency(m.net.abs(), currency)}',
        _ => 'đã cân bằng',
      };
      buf.writeln(
        '• ${m.name} — đã ứng: ${formatCurrency(m.paid, currency)}'
        ' · đã tiêu: ${formatCurrency(m.consumed, currency)}'
        ' · tham gia ${m.joinedCount}/${m.totalBillsCount} khoản'
        ' · $netText',
      );
    }

    buf.write('\n📊 Danh mục chi tiêu:\n');
    for (final c in stats.categories) {
      final pct = (c.percent * 100).round();
      buf.writeln(
        '• ${c.emoji} ${c.label}: ${formatCurrency(c.total, currency)} '
        '($pct%)',
      );
    }
  }

  buf.write('\n➡ Thanh toán:\n');
  if (stats.settlements.isEmpty) {
    buf.writeln('• Đã cân bằng, không cần chuyển khoản 🎉');
  } else {
    for (final s in stats.settlements) {
      final from = nameMap[s.fromParticipantId] ?? '?';
      final to = nameMap[s.toParticipantId] ?? '?';
      buf.writeln(
        '• $from chuyển cho $to: ${formatCurrency(s.amount, currency)}'
        '${s.isPaid ? ' ✅' : ''}',
      );
    }
    buf.writeln(
      '✅ Đã thanh toán: ${stats.paidSettlementsCount}/'
      '${stats.settlements.length}',
    );
  }

  return buf.toString().trim();
}

/// Single settlement transfer line for the per-card "Copy" action.
String buildTransferText({
  required String fromName,
  required String toName,
  required double amount,
  required String currency,
}) {
  return '$fromName chuyển cho $toName: ${formatCurrency(amount, currency)}';
}