// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Chiti';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get required => 'Required';

  @override
  String get unknown => 'Unknown';

  @override
  String errorLabel(String error) {
    return 'Error: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get systemDefault => 'System default';

  @override
  String get englishLanguage => 'English';

  @override
  String get vietnameseLanguage => 'Tiếng Việt';

  @override
  String get myGroups => 'My Groups';

  @override
  String get noGroupsYet => 'No groups yet';

  @override
  String get noGroupsHint => 'Tap + to create your first group';

  @override
  String get newGroup => 'New Group';

  @override
  String get deleteGroupTitle => 'Delete group?';

  @override
  String deleteGroupContent(String groupName) {
    return 'Remove \"$groupName\" and all its expenses?';
  }

  @override
  String get tabExpenses => 'Expenses';

  @override
  String get tabMembersAndNotes => 'Members & Notes';

  @override
  String get tabSummary => 'Summary';

  @override
  String get editGroup => 'Edit Group';

  @override
  String get groupNotFound => 'Group not found';

  @override
  String get noExpensesYet => 'No expenses yet';

  @override
  String get noExpensesHint => 'Tap + to add an expense';

  @override
  String expenseSubtitle(String paidBy, int joined, int total) {
    return 'Paid by $paidBy · $joined of $total joined';
  }

  @override
  String get createGroup => 'Create Group';

  @override
  String get groupName => 'Group Name';

  @override
  String get location => 'Location';

  @override
  String get currency => 'Currency';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get editExpense => 'Edit Expense';

  @override
  String get saveExpense => 'Save Expense';

  @override
  String get deleteExpense => 'Delete Expense';

  @override
  String get deleteExpenseDialogTitle => 'Delete expense?';

  @override
  String deleteExpenseDialogContent(String title) {
    return 'Delete \"$title\"? This cannot be undone.';
  }

  @override
  String get expenseTitle => 'Title';

  @override
  String get expenseTitleHint => 'Dinner, badminton court, rent, Grab…';

  @override
  String get amount => 'Amount';

  @override
  String get amountMustBePositive => 'Must be > 0';

  @override
  String get category => 'Category';

  @override
  String get whoPaid => 'Who paid?';

  @override
  String get whoJoined => 'Who joined?';

  @override
  String selectedOfMembers(int selected, int total) {
    return 'Selected: $selected of $total members';
  }

  @override
  String eachApprox(String amount) {
    return ' (each ~ $amount)';
  }

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get liveSplitPreview => 'Live Split Preview';

  @override
  String eachPaysPreview(String amount) {
    return 'Each person pays: $amount';
  }

  @override
  String participantsCount(int count) {
    return '($count participants)';
  }

  @override
  String payerSummary(String name, String amount, String suffix) {
    return '$name paid $amount$suffix';
  }

  @override
  String get notJoinedSuffix => ' (not joined)';

  @override
  String get amountGreaterThanZero => 'Amount must be greater than 0';

  @override
  String get selectParticipantToSplit =>
      'Select at least one participant to split';

  @override
  String get selectWhoPaid => 'Select who paid';

  @override
  String get addParticipantsFirst => 'Add participants first';

  @override
  String get joinPreviewText =>
      'No participants selected. Select who joined this expense.';

  @override
  String get enterAmountPreview =>
      'Enter an amount to see the split right away.';

  @override
  String get membersAndNotesTitle => 'Members & Notes';

  @override
  String get addMember => 'Add Member';

  @override
  String get editMember => 'Edit Member';

  @override
  String get noParticipantsYet => 'No participants yet';

  @override
  String get noParticipantsHint => 'Add the group so you can split expenses';

  @override
  String get memberNotePlaceholder => 'No note yet';

  @override
  String get editAction => 'Edit';

  @override
  String get removeAction => 'Remove';

  @override
  String get removeParticipantTitle => 'Remove participant?';

  @override
  String removeParticipantContent(String name) {
    return 'Remove $name from this group?\nTheir shares and payers will be removed too.';
  }

  @override
  String get qaAddExpense => 'Add Expense';

  @override
  String get qaAddExpenseSubtitle => 'Quick add to your active group';

  @override
  String get qaCreateGroup => 'New Group';

  @override
  String get qaCreateGroupSubtitle => 'Create a new group';

  @override
  String get qaLatestSummary => 'Latest Summary';

  @override
  String get qaLatestSummarySubtitle => 'Open the latest settlement summary';

  @override
  String get editExpenseAction => 'Edit expense';

  @override
  String get duplicateExpenseAction => 'Duplicate expense';

  @override
  String get deleteExpenseAction => 'Delete expense';

  @override
  String get setAsHost => 'Set as Host (Thủ quỹ)';

  @override
  String get hostAlready => 'Already the Host';

  @override
  String get viewExpenseHistory => 'View expense history';

  @override
  String get removeFromGroup => 'Remove from group';

  @override
  String get nameField => 'Name';

  @override
  String get contactOptional => 'Contact (optional)';

  @override
  String get contactHint => 'Phone / email / handle';

  @override
  String get noteForGroupOptional => 'Note for this group (optional)';

  @override
  String get noteHint => 'e.g. Paid deposit early, vegetarian discount…';

  @override
  String get avatarColor => 'Avatar color';

  @override
  String get expenseDetails => 'Expense Details';

  @override
  String get expenseNotFound => 'Expense not found';

  @override
  String joinedCount(int count) {
    return 'Joined ($count)';
  }

  @override
  String excludedCount(int count) {
    return 'Excluded ($count)';
  }

  @override
  String get everyoneJoined => 'Everyone joined this expense.';

  @override
  String get noShare => 'No share';

  @override
  String splitEquallyPaidBy(String payer) {
    return 'Split equally · Paid by $payer';
  }

  @override
  String get memberAuditTitle => 'Member Audit';

  @override
  String get categoryAnalysisTitle => 'Category Analysis';

  @override
  String get settlementPlanTitle => 'Settlement Plan';

  @override
  String get settlementModeTitle => 'Settlement settings';

  @override
  String get settlementModeHostLabel => 'Host / Treasurer (Thủ quỹ)';

  @override
  String get settlementModeHostHint =>
      'Debtors transfer to the host; the host refunds creditors';

  @override
  String get settlementModePeerToPeerLabel => 'Peer-to-peer';

  @override
  String get selectHost => 'Host (Thủ quỹ)';

  @override
  String get hostBadge => 'Host / Treasurer';

  @override
  String hostIs(String name) {
    return 'Host: $name';
  }

  @override
  String hostTransferSuffix(String host) {
    return '(via $host)';
  }

  @override
  String get recalculate => 'Recalculate';

  @override
  String get allSettledNoTransfer => 'All settled, no transfers needed 🎉';

  @override
  String paidProgress(int count, int total) {
    return 'Paid: $count of $total';
  }

  @override
  String get copyGroupReport => 'Copy group report';

  @override
  String get shareSummary => 'Share Summary';

  @override
  String get groupReportCopied => 'Group report copied';

  @override
  String get captureReport => 'Capture full report as image';

  @override
  String get reportPreviewTitle => 'Report preview';

  @override
  String get shareAction => 'Share';

  @override
  String get saveToGallery => 'Save to gallery';

  @override
  String get savedToGallery => 'Saved to gallery';

  @override
  String captureFailed(String error) {
    return 'Could not generate image: $error';
  }

  @override
  String get reportGeneratedFooter => 'Made with Chiti';

  @override
  String shareReportText(String groupName) {
    return 'Group expense report for $groupName';
  }

  @override
  String get statsEmptyTitle => 'No expenses yet';

  @override
  String get statsEmptyHint =>
      'Add expenses to see statistics and the payment plan.';

  @override
  String get kpiTotalSpent => 'Total spent';

  @override
  String get kpiAveragePerPerson => 'Avg / person';

  @override
  String get kpiExpenseCount => 'Expenses';

  @override
  String get kpiLargestExpense => 'Largest expense';

  @override
  String get auditMember => 'Member';

  @override
  String get auditPaid => 'Paid';

  @override
  String get auditOwes => 'Owes';

  @override
  String get auditNetRule => 'Net balance = Paid − Owes';

  @override
  String netReceiveBack(String amount) {
    return '+ Receive back $amount';
  }

  @override
  String netPayMore(String amount) {
    return '- Pay more $amount';
  }

  @override
  String get netSettled => 'Settled';

  @override
  String widgetNetPay(String amount) {
    return 'To pay: $amount';
  }

  @override
  String widgetNetReceive(String amount) {
    return 'To receive: $amount';
  }

  @override
  String get noCategoryData => 'No category data yet.';

  @override
  String billsParticipation(int joined, int total) {
    return '$joined/$total bills';
  }

  @override
  String transferLine(String from, String to, String amount) {
    return '$from pays $to: $amount';
  }

  @override
  String get transferStatusSettled => 'Settled';

  @override
  String get transferStatusPending => 'Not settled';

  @override
  String get copyText => 'Copy';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String reportTitle(String groupName) {
    return 'GROUP REPORT \"$groupName\"';
  }

  @override
  String reportTotalAverage(String amount, String average) {
    return 'Total spent: $amount · Average: $average/person';
  }

  @override
  String get reportMembersHeader => 'Members:';

  @override
  String reportMemberLine(
    String name,
    String paid,
    String spent,
    int joined,
    int total,
    String net,
  ) {
    return '• $name — paid: $paid · spent: $spent · joined $joined/$total bills · $net';
  }

  @override
  String reportNetReceiveBack(String amount) {
    return 'receive back +$amount';
  }

  @override
  String reportNetPayMore(String amount) {
    return 'pay more $amount';
  }

  @override
  String get reportNetSettled => 'settled';

  @override
  String get reportCategoriesHeader => 'Spending by category:';

  @override
  String reportCategoryLine(
    String emoji,
    String label,
    String amount,
    int percent,
  ) {
    return '• $emoji $label: $amount ($percent%)';
  }

  @override
  String get reportSettlementsHeader => 'Payments:';

  @override
  String get reportAllSettled => '• All settled, no transfers needed 🎉';

  @override
  String reportSettlementLine(
    String from,
    String to,
    String amount,
    String paid,
  ) {
    return '• $from transfers to $to: $amount$paid';
  }

  @override
  String reportPaidProgress(int count, int total) {
    return '✅ Paid: $count/$total';
  }

  @override
  String transferReportLine(String from, String to, String amount) {
    return '$from to $to: $amount';
  }

  @override
  String get categorySports => 'Sports & Court';

  @override
  String get categoryDining => 'Dining & Drinks';

  @override
  String get categoryCafe => 'Coffee & Hangouts';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryHousing => 'Housing & Utilities';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryShopping => 'Shared Shopping';

  @override
  String get categoryOther => 'Other';
}
