import 'package:shared_preferences/shared_preferences.dart';

const _recentGroupKey = 'recent_group_id';

/// Tracks the most recently active group so home-screen quick actions and
/// shortcuts can target it without a DB scan.
///
/// All calls are fail-safe: prefs hiccups must never break data flows.
abstract final class RecentGroupService {
  /// Marks [tripId] as the most recently active group.
  static Future<void> saveRecentGroup(String tripId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recentGroupKey, tripId);
    } catch (_) {
      // Best-effort.
    }
  }

  /// The most recently active group id, or null when none was ever opened.
  static Future<String?> loadRecentGroup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_recentGroupKey);
    } catch (_) {
      return null;
    }
  }

  /// Clears the recent group marker (e.g. after the group is deleted).
  static Future<void> clearRecentGroup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentGroupKey);
    } catch (_) {
      // Best-effort.
    }
  }
}