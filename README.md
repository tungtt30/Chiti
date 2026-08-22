# Chiti — Travel Expense Tracker & Bill Splitter

Offline-first Flutter app for tracking shared expenses during a trip and
settling balances among participants. Data lives on-device in SQLite, so it
works fully offline. **Android & iOS only** (desktop/web out of scope).

## Features

- **Trips** — create/edit/delete trips with name, destination, currency
  (VND, USD, …), and a start/end date range.
- **Members & Notes** — add/edit/remove participants with avatar color, contact
  info, and a per-person note for the trip (e.g. *"Paid deposit early"*,
  *"Vegetarian discount"*).
- **Expenses** — title, date, category (Food / Transport / Lodging / Activities /
  Other), **single or multiple payers** with the exact amount each paid, and
  flexible splitting:
  - **Shared expense toggle** — split equally among all active members.
  - **Split Equally** button — instant equal division for the selected people.
  - **Custom Amounts** — exact amount per participant.
  - **Weights** — weighted shares (e.g. 2x for two nights).
  - Per-person inline notes on each portion (e.g. *"Owes flight ticket
    separately"*).
- **Summary dashboard** — 4-column table (Participant | Spent | Share | Net),
  color-coded settlement plan with **Paid/Completed** checkboxes, and a
  **Calculate / Re-balance** button that persists the new plan.

## Architecture

Strict Clean Architecture separation:

```
lib/
├── core/                        # Pure logic, no Flutter deps
│   ├── constants.dart           # Categories, split modes, currencies, colors
│   ├── formatters.dart          # Currency & date formatting (intl)
│   ├── id_generator.dart        # UUID ids (uuid)
│   └── settlement_calculator.dart  # Greedy settlement algorithm + split helpers
├── data/
│   ├── database_helper.dart     # SQLite schema, FKs, migrations (sqflite)
│   ├── repository.dart          # Data access / transactions
│   └── models/                  # Trip, Participant, Expense, ExpenseSplit,
│                                # ExpensePayer, Settlement
├── providers/                    # Riverpod notifiers & derived providers
│   └── providers.dart
└── presentation/
    ├── screens/                 # TripDashboard, TripDetail, AddExpense,
    │                            # AddTrip, ManageParticipants
    └── widgets/                 # SummaryTable, SettlementCard, chips
```

### Settlement engine (greedy algorithm)

`Net Balance = Total Paid − Total Share`. Debts are simplified greedily by always
matching the largest debtor (biggest negative net) with the largest creditor
(biggest positive net), producing a near-minimal transfer list
(`[A] pays 150,000 VND to [B]`). Unit tested in `test/core/settlement_calculator_test.dart`
via `flutter test`.

## Getting started (Android & iOS)

Requirements: Flutter **3.47+** stable and a configured toolchain for your target.

```sh
flutter pub get
flutter run                      # pick an Android emulator or iOS simulator
flutter test                     # runs unit + widget tests
```

### Android setup

1. The app needs no network permission — SQLite is internal storage only.
2. `android/app/build.gradle` already uses Flutter defaults. If you set a custom
   `minSdkVersion`, keep it `>= 21` (sqflite requirement, current default is
   fine).
3. Run:
   ```sh
   flutter run -d <android-device>
   # or a release APK:
   flutter build apk --release
   ```

### iOS setup

1. `sqflite` uses CocoaPods. With Flutter 3.38+, no `Podfile` is required — one
   is generated on first iOS build, but if needed run `pod install` inside
   `ios/`.
2. No Info.plist permission keys are required (no camera/network/location).
3. Run:
   ```sh
   flutter run -d <ios-simulator>
   flutter build ios --release --no-codesign   # CI/simulator build
   ```

### Data & migrations

Database: `chiti.db` in the app documents directory. Foreign keys are enforced
via `PRAGMA foreign_keys = ON`; deleting a trip/participant cascades to its
expenses, splits, payers, and settlements. Current schema version is `2`;
`onUpgrade` recreates the dev database from older versions.

## Package manifest (`pubspec.yaml`)

```yaml
name: chiti
description: "An offline-first Travel Expense Splitting app."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.13.1

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.6.1   # state management
  sqflite: ^2.4.2           # local SQLite
  path: ^1.9.1              # path joins for the DB
  path_provider: ^2.1.5
  intl: ^0.20.2             # currency & date formatting
  uuid: ^4.5.1              # user ids

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  riverpod_generator: ^2.6.3
  build_runner: ^2.4.15

flutter:
  uses-material-design: true
```