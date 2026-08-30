import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../providers/trip_summary_provider.dart';
import '../formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_en.dart';
import '../../l10n/app_localizations_vi.dart';

const _localePrefsKey = 'app_locale';

/// Keys of the widget data pushed to the native provider.
abstract final class WidgetDataKeys {
  static const groupName = 'groupName';
  static const totalSpent = 'totalSpent';
  static const netLabel = 'netLabel';
  static const netColor = 'netColor';
  static const tripId = 'tripId';
  static const hasData = 'hasData';
}

/// The fully resolved widget provider on Android.
const kWidgetQualifiedName = 'com.example.chiti.ExpenseWidgetProvider';

/// The deep-link host used by the widget to open a group's detail screen.
const kWidgetDeepLinkHost = 'group';

/// One rendered snapshot of the home-screen widget's content.
class WidgetPayload {
  final bool hasData;
  final String? groupName;
  final String? totalSpent;
  final String? netLabel;
  final String? netColor; // 'red' | 'green' | null (neutral)
  final String? tripId;

  const WidgetPayload({
    required this.hasData,
    this.groupName,
    this.totalSpent,
    this.netLabel,
    this.netColor,
    this.tripId,
  });

  /// Placeholder shown when no group is active yet.
  static const WidgetPayload empty = WidgetPayload(hasData: false);
}

/// Builds the widget payload from a trip + its summary.
///
/// The "current user" is the Host (Thủ quỹ): `trip.hostId`, falling back to
/// the first member. Pure function — unit-testable without the widget plugin.
WidgetPayload buildWidgetPayload({
  required Trip trip,
  required TripSummaryStats stats,
  required AppLocalizations l10n,
}) {
  final members = stats.members;
  if (members.isEmpty) return WidgetPayload.empty;

  final hostId =
      trip.hostId ??
      members.first.participantId;
  MemberStat host = members.first;
  for (final m in members) {
    if (m.participantId == hostId) {
      host = m;
      break;
    }
  }

  final (netLabel, netColor) = switch (host.net) {
    > 0.01 => (
      l10n.widgetNetReceive(formatCurrency(host.net, trip.currency)),
      'green',
    ),
    < -0.01 => (
      l10n.widgetNetPay(formatCurrency(host.net.abs(), trip.currency)),
      'red',
    ),
    _ => (l10n.netSettled, 'neutral'),
  };

  return WidgetPayload(
    hasData: true,
    groupName: trip.name,
    totalSpent:
        '${l10n.kpiTotalSpent}: ${formatCurrency(stats.totalSpent, trip.currency)}',
    netLabel: netLabel,
    netColor: netColor,
    tripId: trip.id,
  );
}

/// Pushes [payload] to the widget storage and triggers an `APPWIDGET_UPDATE`.
Future<void> pushWidgetUpdate(WidgetPayload payload) async {
  await HomeWidget.saveWidgetData<String>(
    WidgetDataKeys.groupName,
    payload.groupName,
  );
  await HomeWidget.saveWidgetData<String>(
    WidgetDataKeys.totalSpent,
    payload.totalSpent,
  );
  await HomeWidget.saveWidgetData<String>(
    WidgetDataKeys.netLabel,
    payload.netLabel,
  );
  await HomeWidget.saveWidgetData<String>(
    WidgetDataKeys.netColor,
    payload.netColor,
  );
  await HomeWidget.saveWidgetData<String>(WidgetDataKeys.tripId, payload.tripId);
  await HomeWidget.saveWidgetData<bool>(WidgetDataKeys.hasData, payload.hasData);
  await HomeWidget.updateWidget(
    qualifiedAndroidName: kWidgetQualifiedName,
  );
}

/// The widget reflects the most recently active group: every data change in
/// [tripId] re-pushes that group's payload and refreshes the widget.
///
/// Android-only and fail-safe: any platform/plugin error is swallowed so
/// provider flows never break (and widget tests stay inert on the host).
Future<void> refreshWidgetForTrip(Ref ref, String tripId) async {
  if (!Platform.isAndroid) return;
  try {
    // Ensure the trip detail is loaded before reading its snapshot.
    await ref.read(tripDetailProvider(tripId).notifier).load();
    final trip = ref.read(tripDetailProvider(tripId)).valueOrNull;
    if (trip == null) return;
    final stats = await ref.read(tripSummaryProvider(tripId).future);
    final l10n = await _l10nForApp();
    await pushWidgetUpdate(
      buildWidgetPayload(trip: trip, stats: stats, l10n: l10n),
    );
  } catch (_) {
    // Best-effort: the widget must never break app data flows.
  }
}

/// Clears the widget to its placeholder after the active group is deleted.
Future<void> clearWidgetData() async {
  if (!Platform.isAndroid) return;
  try {
    await pushWidgetUpdate(WidgetPayload.empty);
  } catch (_) {
    // Best-effort.
  }
}

/// Resolves the app's effective localizations for widget strings.
Future<AppLocalizations> _l10nForApp() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString(_localePrefsKey);
  if (code == 'vi') return AppLocalizationsVi();
  if (code == 'en') return AppLocalizationsEn();
  // Follow the device locale like the app does.
  final system = Platform.localeName.toLowerCase();
  return system.startsWith('vi') ? AppLocalizationsVi() : AppLocalizationsEn();
}