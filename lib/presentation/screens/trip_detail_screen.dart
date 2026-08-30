import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/trip_report_text.dart';
import '../../core/utils/image_exporter.dart';
import '../../data/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../providers/trip_summary_provider.dart';
import '../widgets/expenses/expense_report_view.dart';
import '../widgets/participant_edit_dialog.dart';
import '../widgets/summary/summary_report_view.dart';
import '../widgets/summary/summary_screen.dart';
import 'add_edit_expense_screen.dart';
import 'add_trip_screen.dart';
import 'expense_detail_screen.dart';
import 'manage_participants_screen.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTab = 0;

  String get _tripId => widget.tripId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddExpense() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditExpenseScreen(tripId: _tripId),
      ),
    );
  }

  Future<void> _openAddMember() async {
    HapticFeedback.lightImpact();
    final participants =
        ref.read(participantsProvider(_tripId)).valueOrNull ?? [];
    final result = await showParticipantEditDialog(
      context,
      defaultColor:
          kParticipantColors[participants.length % kParticipantColors.length],
    );
    if (result == null || !mounted) return;
    await ref
        .read(participantsProvider(_tripId).notifier)
        .addParticipant(
          name: result.name,
          color: result.color,
          contact: result.contact,
          note: result.note,
        );
  }

  Future<void> _shareSummaryReport() async {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    final trip = ref.read(tripDetailProvider(_tripId)).valueOrNull;
    if (trip == null) return;
    final stats = await ref.read(tripSummaryProvider(_tripId).future);
    final participants =
        ref.read(participantsProvider(_tripId)).valueOrNull ?? [];
    final nameMap = {for (final p in participants) p.id: p.name};

    final text = buildTripReportText(
      l10n: l10n,
      tripName: trip.name,
      currency: trip.currency,
      stats: stats,
      nameMap: nameMap,
      hostId: trip.hostId,
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.reportCopied)),
    );
  }

  /// Builds the off-screen report Column for the current tab.
  Future<Widget> _buildReportWidget(Trip trip) async {
    final participants =
        ref.read(participantsProvider(_tripId)).valueOrNull ?? [];
    if (_currentTab == 0) {
      final expenses =
          ref.read(expensesProvider(_tripId)).valueOrNull ?? const [];
      final joined = await ref.read(
        expenseParticipantsForTripProvider(_tripId).future,
      );
      final joinedCount = <String, int>{};
      for (final member in joined) {
        joinedCount[member.expenseId] =
            (joinedCount[member.expenseId] ?? 0) + 1;
      }
      return ExpenseReportView(
        trip: trip,
        expenses: expenses,
        participants: participants,
        joinedCount: joinedCount,
      );
    }
    final stats = await ref.read(tripSummaryProvider(_tripId).future);
    return SummaryReportView(
      trip: trip,
      stats: stats,
      participants: participants,
      hostId: trip.hostId,
    );
  }

  /// "Export as long image" (Chụp ảnh bảng kê) for the current tab.
  Future<void> _captureCurrentTab() async {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    final trip = ref.read(tripDetailProvider(_tripId)).valueOrNull;
    if (trip == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final report = await _buildReportWidget(trip);
      if (!mounted) return;
      final bytes = await ImageExporter.captureLongReport(
        report: report,
        context: context,
      );
      final file = await ImageExporter.writePng(bytes);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close the spinner
      await _showReportPreview(
        bytes: bytes,
        file: file,
        trip: trip,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close the spinner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.captureFailed(e.toString()))),
      );
    }
  }

  Future<void> _showReportPreview({
    required Uint8List bytes,
    required File file,
    required Trip trip,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    l10n.reportPreviewTitle,
                    style: Theme.of(dialogContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(dialogContext).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await ImageExporter.sharePng(
                        file,
                        text: l10n.shareReportText(trip.name),
                      );
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: Text(l10n.shareAction),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        await ImageExporter.saveToGallery(file);
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.savedToGallery)),
                        );
                      } catch (e) {
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(l10n.captureFailed(e.toString())),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(l10n.saveToGallery),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFabForCurrentTab() {
    final l10n = AppLocalizations.of(context)!;
    return switch (_currentTab) {
      0 => FloatingActionButton.extended(
        key: const ValueKey('fab_expense'),
        onPressed: _openAddExpense,
        icon: const Icon(Icons.receipt_long),
        label: Text(l10n.addExpense),
      ),
      1 => FloatingActionButton.extended(
        key: const ValueKey('fab_member'),
        onPressed: _openAddMember,
        icon: const Icon(Icons.person_add),
        label: Text(l10n.addMember),
      ),
      2 => FloatingActionButton.extended(
        key: const ValueKey('fab_summary'),
        onPressed: _shareSummaryReport,
        icon: const Icon(Icons.share),
        label: Text(l10n.shareSummary),
      ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(_tripId));
    final l10n = AppLocalizations.of(context)!;

    return tripAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text(l10n.errorLabel(e.toString())))),
      data: (trip) {
        if (trip == null) {
          return Scaffold(body: Center(child: Text(l10n.tripNotFound)));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(trip.name),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  icon: const Icon(Icons.receipt_long),
                  text: l10n.tabExpenses,
                ),
                Tab(
                  icon: const Icon(Icons.people),
                  text: l10n.tabMembersAndNotes,
                ),
                Tab(
                  icon: const Icon(Icons.balance),
                  text: l10n.tabSummary,
                ),
              ],
            ),
            actions: [
              if (_currentTab == 0 || _currentTab == 2)
                IconButton(
                  icon: const Icon(Icons.photo_camera_outlined),
                  tooltip: l10n.captureReport,
                  onPressed: _captureCurrentTab,
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.editTrip,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddTripScreen(existing: trip),
                    ),
                  );
                },
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _ExpensesTab(tripId: _tripId, currency: trip.currency),
              ManageParticipantsScreen(tripId: _tripId),
              SummaryScreen(tripId: _tripId, currency: trip.currency),
            ],
          ),
          // A single, tab-aware action button at the root Scaffold. The
          // AnimatedSwitcher cross-fades between the per-tab FABs so the
          // button never overlaps another tab's content or actions.
          floatingActionButton: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: _buildFabForCurrentTab(),
          ),
        );
      },
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  final String tripId;
  final String currency;
  const _ExpensesTab({required this.tripId, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(tripId));
    final participantsAsync = ref.watch(participantsProvider(tripId));
    final joinedAsync = ref.watch(expenseParticipantsForTripProvider(tripId));
    final l10n = AppLocalizations.of(context)!;

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.errorLabel(e.toString()))),
      data: (expenses) {
        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noExpensesYet,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.noExpensesHint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final participants = participantsAsync.valueOrNull ?? [];
        final nameMap = {for (final p in participants) p.id: p.name};
        final joinedCount = <String, int>{};
        for (final member in joinedAsync.valueOrNull ?? <ExpenseParticipant>[]) {
          joinedCount[member.expenseId] =
              (joinedCount[member.expenseId] ?? 0) + 1;
        }

        return ListView.builder(
          primary: false,
          semanticChildCount: expenses.length,
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final e = expenses[index];
            final payerLabel = nameMap[e.payerId] ?? l10n.unknown;
            final joined = joinedCount[e.id] ?? 0;

            return Dismissible(
              key: Key(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                ref.read(expensesProvider(tripId).notifier).deleteExpense(e.id);
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: Text(
                    e.title.isNotEmpty ? e.title[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(e.title),
                subtitle: Text(
                  l10n.expenseSubtitle(
                    payerLabel,
                    joined,
                    participants.length,
                  ),
                ),
                trailing: Text(
                  formatCurrency(e.amount, currency),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ExpenseDetailScreen(expenseId: e.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

