import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chiti/core/services/recent_group_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns null when nothing was saved', () async {
    expect(await RecentGroupService.loadRecentGroup(), isNull);
  });

  test('saves and loads the recent group', () async {
    await RecentGroupService.saveRecentGroup('trip-1');
    expect(await RecentGroupService.loadRecentGroup(), 'trip-1');
  });

  test('overwrites the previous recent group', () async {
    await RecentGroupService.saveRecentGroup('trip-1');
    await RecentGroupService.saveRecentGroup('trip-2');
    expect(await RecentGroupService.loadRecentGroup(), 'trip-2');
  });

  test('clears the recent group', () async {
    await RecentGroupService.saveRecentGroup('trip-1');
    await RecentGroupService.clearRecentGroup();
    expect(await RecentGroupService.loadRecentGroup(), isNull);
  });
}