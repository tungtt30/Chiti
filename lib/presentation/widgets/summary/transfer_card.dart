import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/trip_report_text.dart';
import '../../../data/models/models.dart';
import '../../../l10n/app_localizations.dart';
import '../participant_chips.dart';

/// Section D — One optimized settlement transfer with copy action and settled
/// toggle: `[Nguyễn A] chuyển cho [Trần B]: 250.000 ₫`.
///
/// When [hostName] is provided, the transfer involves the Host / Thủ quỹ and
/// gets a badge plus a "via `host`" suffix in the copied text.
class TransferCard extends StatelessWidget {
  final Settlement settlement;
  final String fromName;
  final String toName;
  final Participant? fromAvatar;
  final Participant? toAvatar;
  final String currency;
  final String? hostName;
  final ValueChanged<bool> onSettledChanged;

  const TransferCard({
    super.key,
    required this.settlement,
    required this.fromName,
    required this.toName,
    required this.fromAvatar,
    required this.toAvatar,
    required this.currency,
    this.hostName,
    required this.onSettledChanged,
  });

  static final Participant _fallback = Participant(
        id: '',
        tripId: '',
        name: '?',
        color: 0xFF9E9E9E,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.copiedToClipboard)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final settled = settlement.isPaid;
    final from = fromAvatar ?? _fallback;
    final to = toAvatar ?? _fallback;

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ParticipantAvatar(participant: from, radius: 17),
                const SizedBox(width: 8),
                Text(
                  fromName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    decoration: settled ? TextDecoration.lineThrough : null,
                    color: settled ? theme.disabledColor : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child:
                      Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                ),
                ParticipantAvatar(participant: to, radius: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    toName,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      decoration: settled ? TextDecoration.lineThrough : null,
                      color: settled ? theme.disabledColor : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(
                  child: Text(
                    l10n.transferLine(
                      fromName,
                      toName,
                      formatCurrency(settlement.amount, currency),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (hostName != null) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: l10n.hostTransferSuffix(hostName!),
                    child: const Icon(Icons.emoji_events, size: 16),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  settled
                      ? l10n.transferStatusSettled
                      : l10n.transferStatusPending,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: settled
                        ? Colors.green.shade700
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _copy(
                    context,
                    buildTransferText(
                      l10n: l10n,
                      fromName: fromName,
                      toName: toName,
                      amount: settlement.amount,
                      currency: currency,
                      hostName: hostName,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(l10n.copyText),
                ),
                Checkbox(
                  value: settled,
                  onChanged: (v) => onSettledChanged(v ?? false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}