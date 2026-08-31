# 💸 Chiti — Multipurpose Group Expense & Bill Splitting

> A fast, elegant, and privacy-focused Android app to split bills, manage group funds, and settle debts for sports clubs, hangouts, and trips.

<p align="center">
  <img alt="Platform: Android" src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white">
  <img alt="CI" src="https://img.shields.io/github/actions/workflow/status/tungtt30/Chiti/build.yml?label=CI&logo=githubactions&logoColor=white">
  <img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg">
</p>

---

## 🌟 Why Chiti?

Most bill-splitting apps force you to sign up for an account, sync your data to
the cloud, and wade through ads and subscription upsells just to split a
dinner bill. Chiti flips that script: it's a **local-first, serverless**
expense tracker that lives entirely on your device. Open the app, create a
group, and start splitting in seconds — no sign-up, no ads, no internet
required.

Whether it's a **badminton club** chipping in for court fees, a **group trip**
with a shared budget, **roommates** splitting rent and groceries, or a Friday
night **dinner hangout**, Chiti handles it all with a beautiful, calm interface
that makes settling up genuinely pleasant.

## ✨ Key Features

### 🎯 Smart & Flexible Splitting

- **Selective subset splitting** — pick exactly who joined each activity (e.g.,
  only 4 of 10 people go for drinks); non-participants owe nothing.
- **Three split modes** — split equally, enter exact custom amounts, or use
  weighted shares (e.g., 2× for a two-night stay).
- **Multiple payers per expense** — record exactly how much each person paid
  (A paid the bill, B covered the tip).
- **Per-person notes** — annotate any portion (*"Owes flight ticket
  separately"*, *"Vegetarian discount"*) for full transparency.
- **8 smart categories** — Sports 🏸, Dining 🍜, Coffee ☕, Transport 🚗,
  Housing 🏠, Entertainment 🎟️, Shopping 🛍️, and Other 📦.

### 👑 Host Settlement System

- **Host / Thủ quỹ mode** — debtors transfer once to a single **Host**, who
  then refunds every creditor: two phases, zero mathematical discrepancy.
- **Peer-to-peer mode** — the greedy settlement engine simplifies debts into a
  near-minimal transfer list (`A pays 150,000 ₫ to B`).
- **Live settlement plan** — color-coded, with Paid/Completed checkboxes and a
  one-tap **Recalculate** that persists the new plan.

### 📊 Visual Statistics & Export

- **Real-time summary dashboard** — per-member audit (Paid / Owes / Net), KPI
  cards, and category distribution charts.
- **1-tap copy & share** — export a plain-text report straight to group chats
  (Zalo, Telegram, Messenger).
- **Long-image export** — capture the full summary or expense list as a PNG and
  share or save it to the gallery.

### 🌸 Polished Material 3 & Sakura Theme

- **Material 3** design with Light, Dark, and System theme modes.
- **Custom Pastel Sakura theme** — a soft cherry-blossom pink palette with
  falling **petal particle effects** across the app.
- Smooth, responsive animations and rounded, card-based layouts.

### 🔒 Local & Serverless Security

- **100% offline** — all data stored in local SQLite (`chiti.db`). No accounts,
  no internet tracking, no cloud sync.
- **No network permission** — the app literally cannot phone home.
- **Ultra-fast** — instant startup, instant queries, even with years of
  expenses.

### ⚡ Smart Input UX

- **Real-time thousands separator** formatting as you type (`100,000`).
- **VND by default** — with 10 currencies available per group
  (VND, USD, EUR, GBP, JPY, THB, KRW, CNY, AUD, CAD).
- **Launcher quick shortcuts** — long-press the app icon for *Add Expense*,
  *Create Group*, or *Latest Summary*.
- **Home-screen widget** — jump straight into your recent group.

## 📱 Screenshots & Demo

> Screenshots coming soon — the app is in active development.

| Home Dashboard | Expense Entry | Summary & Settlement |
|:---:|:---:|:---:|
| ![Home Dashboard](docs/screenshots/home.png) | ![Expense Entry](docs/screenshots/expense.png) | ![Summary](docs/screenshots/summary.png) |

## 🛠️ Tech Stack

- **Framework:** Flutter (Android-optimized, stable channel)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Local Database:** SQLite (`sqflite`)
- **Localization:** Vietnamese (`vi`) & English (`en`)
- **CI/CD:** GitHub Actions — automated analyze, test, and release APK builds

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (Stable channel, 3.47+)
- Android Studio / Android SDK 21+

### Installation & Run

```bash
git clone https://github.com/tungtt30/Chiti.git
cd chiti
flutter pub get
flutter run
```

### Build a Release APK

```bash
flutter build apk --release
```

### Run Tests

```bash
flutter test
```

### CI / Automated Releases

Pushing to `android-release` triggers the automated pipeline: static analysis,
tests, a release APK build, and a **GitHub Release** with the APK attached.
Pushes/PRs to `main` run analyze + test + build (APK & AppBundle) instead.

## 🧱 Architecture

Strict Clean Architecture separation:

```
lib/
├── core/                        # Pure logic, no Flutter deps
│   ├── constants.dart           # Categories, split modes, currencies, colors
│   ├── formatters.dart          # Currency & date formatting (intl)
│   ├── settlement_calculator.dart  # Greedy settlement algorithm + split helpers
│   ├── summary_calculator.dart  # Net balances & summary aggregation
│   ├── trip_report_text.dart    # Plain-text report for group-chat sharing
│   └── theme/sakura_theme.dart  # Pastel Sakura design system
├── data/
│   ├── database_helper.dart     # SQLite schema, FKs, migrations (sqflite)
│   ├── repository.dart          # Data access / transactions
│   └── models/                  # Trip, Participant, Expense, ExpenseSplit,
│                                # ExpensePayer, Settlement
├── providers/                   # Riverpod notifiers & derived providers
└── presentation/
    ├── screens/                 # Dashboard, TripDetail, AddExpense, AddTrip,
    │                            # ManageParticipants, Settings
    └── widgets/                 # SummaryTable, SettlementCard, chips,
                                 # PetalField, KPI cards, category breakdown
```

### Settlement engine (greedy algorithm)

`Net Balance = Total Paid − Total Share`. Debts are simplified greedily by always
matching the largest debtor (biggest negative net) with the largest creditor
(biggest positive net), producing a near-minimal transfer list
(`[A] pays 150,000 VND to [B]`). In **Host mode**, all debtors pay the Host
first, then the Host refunds every creditor — a two-phase flow with zero
discrepancy. Unit tested in `test/core/settlement_calculator_test.dart`.

## 📜 License

This project is open source under the **MIT License** — free to use, modify,
and distribute.

> **Note:** The `LICENSE` file has not been added to the repository yet. If you
> plan to publish or distribute this project, add an official MIT `LICENSE`
> file before your first release.