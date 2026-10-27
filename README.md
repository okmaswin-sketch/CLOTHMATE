# ClothMate — Garment Business Management App

A cross-platform (Android + iOS) offline-first garment business management app built with Flutter, Drift (SQLite), and Riverpod.

## Features

- **Garment Management** — CRUD for garment types, materials, sizes, and product variants (type × material × size) with SKU, price, cost price, and stock tracking
- **Sales** — Cascading picker (type → material → size → quantity), cart, discount, GST, multi-payment (Cash/UPI/Bank), automatic stock decrement, ledger entry
- **Returns** — Partial/full returns with stock restoration, negative ledger entry, status update
- **Cash & Bank Balances** — Dual-account system, balances computed from ledger, opening balance setup, daily auto-rollover
- **Workers & Wages** — Worker CRUD, daily wage management, paid/pending status, ledger integration
- **Income & Expenses** — Category-based expense tracking (maintenance/general), income entry, ledger integration
- **Transfers** — Cash ↔ Bank transfers with dual ledger rows (total assets invariant)
- **Transaction History** — Filterable ledger view (by type, account, date range)
- **Reports** — Daily statement, weekly bar chart, monthly line chart with profit/loss
- **PDF Generation** — Daily statement PDF with share support
- **Backup & Restore** — Zip backup with typed "RESTORE" confirmation
- **Security** — Optional PIN lock, biometric auth (local_auth), auto-lock
- **Settings** — Business name, GST, price override, low stock threshold

## Tech Stack

| Layer | Choice |
|---|---|
| UI | Flutter 3.x, Dart 3.x |
| Database | SQLite via **Drift** (compile-time safe, built-in migrations) |
| State | **Riverpod** |
| Navigation | **go_router** |
| PDF | `pdf` + `printing` |
| Charts | `fl_chart` |
| Backup | `archive` |

## Prerequisites

- Flutter SDK 3.x
- Dart SDK 3.x
- Android Studio / Xcode
- Android SDK (for Android builds)
- Xcode with CocoaPods (for iOS builds)

## Getting Started

```bash
# Clone the repository
git clone <repo-url>
cd clothmate

# Install dependencies
flutter pub get

# Generate Drift code
dart run build_runner build --delete-conflicting-outputs
```

## Building

### Debug APK (Android)
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK (Android)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### App Bundle (Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ios --debug
# or for release:
flutter build ipa --release
```

### Signing (Release Builds)
1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore android/app/key.properties -keyalg RSA -keysize 2048 -validity 10000 -alias clothmate
   ```
2. Create `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=clothmate
   storeFile=<path-to-keystore>
   ```
3. Never commit `key.properties` or keystore files.

### Install on Device
```bash
flutter install
# or
adb install build/app/outputs/flutter-apk/app-debug.apk
```

## Project Structure

```
lib/
├── main.dart                      # App entry, initialization
├── providers.dart                 # Global Riverpod providers
├── app/
│   ├── routes.dart                # go_router config, bottom nav
│   └── theme.dart                 # Light/dark themes, colors
├── core/
│   ├── constants.dart             # Enums, defaults
│   ├── currency.dart              # Paise ↔ ₹ formatting (Indian grouping)
│   ├── transaction_id.dart        # ID generation (S2608250001, etc.)
│   └── utils.dart                 # Date helpers
├── data/
│   ├── database.dart              # Drift schema (14 tables), all DAOs
│   └── database.g.dart            # Generated Drift code
├── repositories/
│   ├── balance_repository.dart    # Computed balances, opening balance, rollover
│   ├── sales_repository.dart      # Atomic sale + stock + ledger
│   ├── worker_repository.dart     # Wage payment flow
│   ├── report_repository.dart     # Income/Expense/Transfer repos
│   ├── pdf_repository.dart        # PDF daily statement generation
│   └── backup_repository.dart     # Zip backup/restore
├── services/
│   ├── share_service.dart         # Platform file sharing
│   └── biometric_service.dart     # Biometric auth
└── screens/
    ├── dashboard/                 # Dashboard, first-time setup
    ├── sales/                     # Create sale, sales list
    ├── garments/                  # Garment CRUD
    ├── workers/                   # Workers, daily wages
    ├── accounts/                  # Transaction history, income/expenses, transfers
    ├── reports/                   # Daily/weekly/monthly reports
    ├── settings/                  # Settings, PIN
    └── backup/                    # Backup/restore
```

## Database Schema

14 tables with full foreign key constraints:

| Table | Purpose |
|---|---|
| `users_settings` | App config (PIN, GST, thresholds) |
| `garment_types` | Garment categories |
| `materials` | Materials per type |
| `sizes` | Available sizes |
| `products` | Type × Material × Size variants |
| `stock_adjustments` | Restock/damage/correction/return records |
| `workers` | Worker roster |
| `wages` | Daily wage records |
| `sales` | Sale transactions |
| `sale_items` | Line items per sale |
| `sale_returns` | Return records |
| `income` | Other income entries |
| `expenses` | Expense entries |
| `transfers` | Cash ↔ Bank transfers |
| `ledger_transactions` | **Single source of truth** for all balances |
| `daily_opening_balances` | Day-start balances |

## Architecture Rules

- **Balances are never stored** — always computed from `ledger_transactions` + `daily_opening_balances`
- **Every financial write is atomic** — domain row + ledger row inserted in a single Drift `transaction()`
- **All money is integer paise** — no floats/doubles in financial code
- **Transfers maintain invariant** — cash + bank total assets unchanged after any transfer

## Testing

```bash
flutter test
```

Unit tests cover:
- Balance derivation from ledger
- Balance with every transaction type
- Balance with returns
- Balance with transfers (total invariant)
- Opening balance contribution
- Filtered ledger queries

## License

Private — All rights reserved.
