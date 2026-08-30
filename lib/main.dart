import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quick_actions/quick_actions.dart';

import 'core/services/quick_actions_service.dart';
import 'core/services/widget_service.dart';
import 'l10n/app_localizations.dart';
import 'presentation/screens/add_edit_expense_screen.dart';
import 'presentation/screens/add_trip_screen.dart';
import 'presentation/screens/trip_dashboard_screen.dart';
import 'presentation/screens/trip_detail_screen.dart';
import 'providers/locale_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Enable the Semantics tree so assistive tools and OS capture services
  // (e.g. Samsung Smart Capture / Android 12+ Scroll Capture) can discover
  // Flutter's scrollable containers.
  SemanticsBinding.instance.ensureSemantics();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  /// The group detail currently on top of the stack, to avoid pushing the
  /// same screen twice when a shortcut / widget is tapped repeatedly.
  String? _openTripId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cold start via the home-screen widget: open the tapped group.
      _handleWidgetLaunch();
      // Register the app-icon quick actions and listen for taps (this also
      // covers cold-start launches, which the framework delivers here).
      _initQuickActions();
    });
  }

  Future<void> _handleWidgetLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    final tripId = _tripIdFromUri(uri);
    if (tripId != null) _openGroup(tripId);
    // Warm start: the app is already running when the widget is tapped.
    HomeWidget.widgetClicked.listen((uri) {
      final id = _tripIdFromUri(uri);
      if (id != null) _openGroup(id);
    });
  }

  Future<void> _initQuickActions() async {
    await QuickActionsService.register(ref);
    // The initialize callback fires for both cold and warm launches.
    QuickActions().initialize((String type) {
      if (type.isEmpty) return;
      QuickActionsService.handle(
        ref,
        type,
        openGroup: (tripId) => _openGroup(tripId, tab: 2),
        openAddExpense: (tripId) {
          _openGroup(tripId);
          _openAddExpense(tripId);
        },
        openCreateGroup: () => _push(const AddTripScreen()),
      );
    });
  }

  /// Extracts `chiti://group/<tripId>` from a widget deep link.
  String? _tripIdFromUri(Uri? uri) {
    if (uri == null || uri.host != kWidgetDeepLinkHost) return null;
    final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    return segment.isEmpty ? null : segment;
  }

  void _openGroup(String tripId, {int tab = 0}) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || !mounted) return;
    if (_openTripId == tripId) return;
    _openTripId = tripId;
    navigator
        .push(
          MaterialPageRoute(
            settings: RouteSettings(arguments: tripId),
            builder: (_) => TripDetailScreen(tripId: tripId, initialTab: tab),
          ),
        )
        .then((_) {
          if (_openTripId == tripId) _openTripId = null;
        });
  }

  void _openAddExpense(String tripId) {
    _push(AddEditExpenseScreen(tripId: tripId));
  }

  void _push(Widget screen) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || !mounted) return;
    navigator.push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appTitle ?? 'Chiti',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const TripDashboardScreen(),
    );
  }
}