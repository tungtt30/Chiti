import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Application title.
  ///
  /// In en, this message translates to:
  /// **'Chiti'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Error placeholder text.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorLabel(String error);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @vietnameseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnameseLanguage;

  /// No description provided for @myTrips.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get myTrips;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get noTripsYet;

  /// No description provided for @noTripsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first trip'**
  String get noTripsHint;

  /// No description provided for @newTrip.
  ///
  /// In en, this message translates to:
  /// **'New Trip'**
  String get newTrip;

  /// No description provided for @deleteTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete trip?'**
  String get deleteTripTitle;

  /// No description provided for @deleteTripContent.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{tripName}\" and all its expenses?'**
  String deleteTripContent(String tripName);

  /// No description provided for @tabExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get tabExpenses;

  /// No description provided for @tabMembersAndNotes.
  ///
  /// In en, this message translates to:
  /// **'Members & Notes'**
  String get tabMembersAndNotes;

  /// No description provided for @tabSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get tabSummary;

  /// No description provided for @editTrip.
  ///
  /// In en, this message translates to:
  /// **'Edit Trip'**
  String get editTrip;

  /// No description provided for @tripNotFound.
  ///
  /// In en, this message translates to:
  /// **'Trip not found'**
  String get tripNotFound;

  /// No description provided for @noExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesYet;

  /// No description provided for @noExpensesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add an expense'**
  String get noExpensesHint;

  /// No description provided for @expenseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paid by {paidBy} · {joined} of {total} joined'**
  String expenseSubtitle(String paidBy, int joined, int total);

  /// No description provided for @createTrip.
  ///
  /// In en, this message translates to:
  /// **'Create Trip'**
  String get createTrip;

  /// No description provided for @tripName.
  ///
  /// In en, this message translates to:
  /// **'Trip Name'**
  String get tripName;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpense;

  /// No description provided for @saveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save Expense'**
  String get saveExpense;

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get deleteExpense;

  /// No description provided for @deleteExpenseDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete expense?'**
  String get deleteExpenseDialogTitle;

  /// No description provided for @deleteExpenseDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? This cannot be undone.'**
  String deleteExpenseDialogContent(String title);

  /// No description provided for @expenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get expenseTitle;

  /// No description provided for @expenseTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Dinner at Beach, Grab to Hotel…'**
  String get expenseTitleHint;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amountMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Must be > 0'**
  String get amountMustBePositive;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @whoPaid.
  ///
  /// In en, this message translates to:
  /// **'Who paid?'**
  String get whoPaid;

  /// No description provided for @whoJoined.
  ///
  /// In en, this message translates to:
  /// **'Who joined?'**
  String get whoJoined;

  /// No description provided for @selectedOfMembers.
  ///
  /// In en, this message translates to:
  /// **'Selected: {selected} of {total} members'**
  String selectedOfMembers(int selected, int total);

  /// No description provided for @eachApprox.
  ///
  /// In en, this message translates to:
  /// **' (each ~ {amount})'**
  String eachApprox(String amount);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @liveSplitPreview.
  ///
  /// In en, this message translates to:
  /// **'Live Split Preview'**
  String get liveSplitPreview;

  /// No description provided for @eachPaysPreview.
  ///
  /// In en, this message translates to:
  /// **'Each person pays: {amount}'**
  String eachPaysPreview(String amount);

  /// No description provided for @participantsCount.
  ///
  /// In en, this message translates to:
  /// **'({count} participants)'**
  String participantsCount(int count);

  /// No description provided for @payerSummary.
  ///
  /// In en, this message translates to:
  /// **'{name} paid {amount}{suffix}'**
  String payerSummary(String name, String amount, String suffix);

  /// No description provided for @notJoinedSuffix.
  ///
  /// In en, this message translates to:
  /// **' (not joined)'**
  String get notJoinedSuffix;

  /// No description provided for @amountGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get amountGreaterThanZero;

  /// No description provided for @selectParticipantToSplit.
  ///
  /// In en, this message translates to:
  /// **'Select at least one participant to split'**
  String get selectParticipantToSplit;

  /// No description provided for @selectWhoPaid.
  ///
  /// In en, this message translates to:
  /// **'Select who paid'**
  String get selectWhoPaid;

  /// No description provided for @addParticipantsFirst.
  ///
  /// In en, this message translates to:
  /// **'Add participants first'**
  String get addParticipantsFirst;

  /// No description provided for @joinPreviewText.
  ///
  /// In en, this message translates to:
  /// **'No participants selected. Select who joined this expense.'**
  String get joinPreviewText;

  /// No description provided for @enterAmountPreview.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount to see the split right away.'**
  String get enterAmountPreview;

  /// No description provided for @membersAndNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Members & Notes'**
  String get membersAndNotesTitle;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// No description provided for @editMember.
  ///
  /// In en, this message translates to:
  /// **'Edit Member'**
  String get editMember;

  /// No description provided for @noParticipantsYet.
  ///
  /// In en, this message translates to:
  /// **'No participants yet'**
  String get noParticipantsYet;

  /// No description provided for @noParticipantsHint.
  ///
  /// In en, this message translates to:
  /// **'Add the group so you can split expenses'**
  String get noParticipantsHint;

  /// No description provided for @memberNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'No note yet'**
  String get memberNotePlaceholder;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @removeParticipantTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove participant?'**
  String get removeParticipantTitle;

  /// No description provided for @removeParticipantContent.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this trip?\nTheir shares and payers will be removed too.'**
  String removeParticipantContent(String name);

  /// No description provided for @nameField.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameField;

  /// No description provided for @contactOptional.
  ///
  /// In en, this message translates to:
  /// **'Contact (optional)'**
  String get contactOptional;

  /// No description provided for @contactHint.
  ///
  /// In en, this message translates to:
  /// **'Phone / email / handle'**
  String get contactHint;

  /// No description provided for @noteForTripOptional.
  ///
  /// In en, this message translates to:
  /// **'Note for this trip (optional)'**
  String get noteForTripOptional;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Paid deposit early, vegetarian discount…'**
  String get noteHint;

  /// No description provided for @avatarColor.
  ///
  /// In en, this message translates to:
  /// **'Avatar color'**
  String get avatarColor;

  /// No description provided for @expenseDetails.
  ///
  /// In en, this message translates to:
  /// **'Expense Details'**
  String get expenseDetails;

  /// No description provided for @expenseNotFound.
  ///
  /// In en, this message translates to:
  /// **'Expense not found'**
  String get expenseNotFound;

  /// No description provided for @joinedCount.
  ///
  /// In en, this message translates to:
  /// **'Joined ({count})'**
  String joinedCount(int count);

  /// No description provided for @excludedCount.
  ///
  /// In en, this message translates to:
  /// **'Excluded ({count})'**
  String excludedCount(int count);

  /// No description provided for @everyoneJoined.
  ///
  /// In en, this message translates to:
  /// **'Everyone joined this expense.'**
  String get everyoneJoined;

  /// No description provided for @noShare.
  ///
  /// In en, this message translates to:
  /// **'No share'**
  String get noShare;

  /// No description provided for @splitEquallyPaidBy.
  ///
  /// In en, this message translates to:
  /// **'Split equally · Paid by {payer}'**
  String splitEquallyPaidBy(String payer);

  /// No description provided for @memberAuditTitle.
  ///
  /// In en, this message translates to:
  /// **'Member Audit'**
  String get memberAuditTitle;

  /// No description provided for @categoryAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Category Analysis'**
  String get categoryAnalysisTitle;

  /// No description provided for @settlementPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Settlement Plan'**
  String get settlementPlanTitle;

  /// No description provided for @recalculate.
  ///
  /// In en, this message translates to:
  /// **'Recalculate'**
  String get recalculate;

  /// No description provided for @allSettledNoTransfer.
  ///
  /// In en, this message translates to:
  /// **'All settled, no transfers needed 🎉'**
  String get allSettledNoTransfer;

  /// No description provided for @paidProgress.
  ///
  /// In en, this message translates to:
  /// **'Paid: {count} of {total}'**
  String paidProgress(int count, int total);

  /// No description provided for @copyTripReport.
  ///
  /// In en, this message translates to:
  /// **'Copy trip report'**
  String get copyTripReport;

  /// No description provided for @shareSummary.
  ///
  /// In en, this message translates to:
  /// **'Share Summary'**
  String get shareSummary;

  /// No description provided for @reportCopied.
  ///
  /// In en, this message translates to:
  /// **'Trip report copied'**
  String get reportCopied;

  /// No description provided for @statsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get statsEmptyTitle;

  /// No description provided for @statsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add expenses to see statistics and the payment plan.'**
  String get statsEmptyHint;

  /// No description provided for @kpiTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get kpiTotalSpent;

  /// No description provided for @kpiAveragePerPerson.
  ///
  /// In en, this message translates to:
  /// **'Avg / person'**
  String get kpiAveragePerPerson;

  /// No description provided for @kpiExpenseCount.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get kpiExpenseCount;

  /// No description provided for @kpiLargestExpense.
  ///
  /// In en, this message translates to:
  /// **'Largest expense'**
  String get kpiLargestExpense;

  /// No description provided for @auditMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get auditMember;

  /// No description provided for @auditPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get auditPaid;

  /// No description provided for @auditOwes.
  ///
  /// In en, this message translates to:
  /// **'Owes'**
  String get auditOwes;

  /// No description provided for @auditNetRule.
  ///
  /// In en, this message translates to:
  /// **'Net balance = Paid − Owes'**
  String get auditNetRule;

  /// No description provided for @netReceiveBack.
  ///
  /// In en, this message translates to:
  /// **'+ Receive back {amount}'**
  String netReceiveBack(String amount);

  /// No description provided for @netPayMore.
  ///
  /// In en, this message translates to:
  /// **'- Pay more {amount}'**
  String netPayMore(String amount);

  /// No description provided for @netSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get netSettled;

  /// No description provided for @noCategoryData.
  ///
  /// In en, this message translates to:
  /// **'No category data yet.'**
  String get noCategoryData;

  /// No description provided for @billsParticipation.
  ///
  /// In en, this message translates to:
  /// **'{joined}/{total} bills'**
  String billsParticipation(int joined, int total);

  /// No description provided for @transferLine.
  ///
  /// In en, this message translates to:
  /// **'{from} pays {to}: {amount}'**
  String transferLine(String from, String to, String amount);

  /// No description provided for @transferStatusSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get transferStatusSettled;

  /// No description provided for @transferStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Not settled'**
  String get transferStatusPending;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyText;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'TRIP REPORT \"{tripName}\"'**
  String reportTitle(String tripName);

  /// No description provided for @reportTotalAverage.
  ///
  /// In en, this message translates to:
  /// **'Total spent: {amount} · Average: {average}/person'**
  String reportTotalAverage(String amount, String average);

  /// No description provided for @reportMembersHeader.
  ///
  /// In en, this message translates to:
  /// **'Members:'**
  String get reportMembersHeader;

  /// No description provided for @reportMemberLine.
  ///
  /// In en, this message translates to:
  /// **'• {name} — paid: {paid} · spent: {spent} · joined {joined}/{total} bills · {net}'**
  String reportMemberLine(
    String name,
    String paid,
    String spent,
    int joined,
    int total,
    String net,
  );

  /// No description provided for @reportNetReceiveBack.
  ///
  /// In en, this message translates to:
  /// **'receive back +{amount}'**
  String reportNetReceiveBack(String amount);

  /// No description provided for @reportNetPayMore.
  ///
  /// In en, this message translates to:
  /// **'pay more {amount}'**
  String reportNetPayMore(String amount);

  /// No description provided for @reportNetSettled.
  ///
  /// In en, this message translates to:
  /// **'settled'**
  String get reportNetSettled;

  /// No description provided for @reportCategoriesHeader.
  ///
  /// In en, this message translates to:
  /// **'Spending by category:'**
  String get reportCategoriesHeader;

  /// No description provided for @reportCategoryLine.
  ///
  /// In en, this message translates to:
  /// **'• {emoji} {label}: {amount} ({percent}%)'**
  String reportCategoryLine(
    String emoji,
    String label,
    String amount,
    int percent,
  );

  /// No description provided for @reportSettlementsHeader.
  ///
  /// In en, this message translates to:
  /// **'Payments:'**
  String get reportSettlementsHeader;

  /// No description provided for @reportAllSettled.
  ///
  /// In en, this message translates to:
  /// **'• All settled, no transfers needed 🎉'**
  String get reportAllSettled;

  /// No description provided for @reportSettlementLine.
  ///
  /// In en, this message translates to:
  /// **'• {from} transfers to {to}: {amount}{paid}'**
  String reportSettlementLine(
    String from,
    String to,
    String amount,
    String paid,
  );

  /// No description provided for @reportPaidProgress.
  ///
  /// In en, this message translates to:
  /// **'✅ Paid: {count}/{total}'**
  String reportPaidProgress(int count, int total);

  /// No description provided for @transferReportLine.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}: {amount}'**
  String transferReportLine(String from, String to, String amount);

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryLodging.
  ///
  /// In en, this message translates to:
  /// **'Lodging'**
  String get categoryLodging;

  /// No description provided for @categoryActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get categoryActivities;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
