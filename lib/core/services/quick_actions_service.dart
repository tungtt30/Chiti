import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_en.dart';
import '../../l10n/app_localizations_vi.dart';
import '../../providers/providers.dart';
import 'recent_group_service.dart';

const _localePrefsKey = 'app_locale';

/// Type strings for the home-screen app icon shortcuts. Routing happens by
/// type (QuickActions 1.x has no per-item payload); the target group is the
/// most recently active one, looked up at navigation time.
abstract final class QuickActionType {
  static const addExpense = 'action_add_expense';
  static const createGroup = 'action_create_group';
  static const latestSummary = 'action_latest_summary';

  static const all = [addExpense, createGroup, latestSummary];
}

/// Registers the app icon quick actions and routes taps into navigation.
abstract final class QuickActionsService {
  static final QuickActions _quickActions = QuickActions();

  /// Registers the three dynamic shortcuts (Android launcher long-press menu).
  static Future<void> register(WidgetRef ref) async {
    if (!Platform.isAndroid) return;
    try {
      final l10n = await _l10nForApp();
      await _quickActions.setShortcutItems([
        ShortcutItem(
          type: QuickActionType.addExpense,
          localizedTitle: l10n.qaAddExpense,
          localizedSubtitle: l10n.qaAddExpenseSubtitle,
          icon: 'ic_quick_add',
        ),
        ShortcutItem(
          type: QuickActionType.createGroup,
          localizedTitle: l10n.qaCreateGroup,
          localizedSubtitle: l10n.qaCreateGroupSubtitle,
          icon: 'ic_quick_group',
        ),
        ShortcutItem(
          type: QuickActionType.latestSummary,
          localizedTitle: l10n.qaLatestSummary,
          localizedSubtitle: l10n.qaLatestSummarySubtitle,
          icon: 'ic_quick_summary',
        ),
      ]);
    } catch (_) {
      // Shortcuts are best-effort; never break app startup.
    }
  }

  /// Handles a tapped quick action.
  ///
  /// [openGroup] opens a group detail screen (tab 0) and [openAddExpense] /
  /// [openCreateGroup] are the navigation callbacks provided by the root
  /// widget. Callers must run this after the first frame for cold starts.
  static Future<void> handle(
    WidgetRef ref,
    String type, {
    required void Function(String tripId) openGroup,
    required void Function(String tripId) openAddExpense,
    required void Function() openCreateGroup,
  }) async {
    switch (type) {
      case QuickActionType.createGroup:
        openCreateGroup();
      case QuickActionType.addExpense:
        final tripId = await _recentGroupId(ref);
        if (tripId != null) openAddExpense(tripId);
      case QuickActionType.latestSummary:
        final tripId = await _recentGroupId(ref);
        if (tripId != null) openGroup(tripId);
    }
  }

  /// The most recently active group, falling back to the newest trip when the
  /// marker is missing (e.g. after an app reinstall or prefs wipe).
  static Future<String?> _recentGroupId(WidgetRef ref) async {
    final recent = await RecentGroupService.loadRecentGroup();
    if (recent != null) return recent;
    final trips = ref.read(tripListProvider).valueOrNull ?? const [];
    if (trips.isEmpty) return null;
    final sorted = [...trips]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first.id;
  }

  static Future<AppLocalizations> _l10nForApp() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localePrefsKey);
    if (code == 'vi') return AppLocalizationsVi();
    if (code == 'en') return AppLocalizationsEn();
    final system = Platform.localeName.toLowerCase();
    return system.startsWith('vi') ? AppLocalizationsVi() : AppLocalizationsEn();
  }
}