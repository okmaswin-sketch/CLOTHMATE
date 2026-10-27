import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clothmate/data/database.dart';
import 'package:clothmate/providers.dart';
import 'package:clothmate/app/theme.dart';
import 'package:clothmate/screens/garments/garments_screen.dart';
import 'package:clothmate/screens/garments/add_garment_screen.dart';
import 'package:clothmate/screens/sales/sales_screen.dart';
import 'package:clothmate/screens/sales/create_sale_screen.dart';
import 'package:clothmate/screens/workers/workers_screen.dart';
import 'package:clothmate/screens/workers/daily_wages_screen.dart';
import 'package:clothmate/screens/accounts/accounts_screen.dart';
import 'package:clothmate/screens/accounts/income_expenses_screen.dart';
import 'package:clothmate/screens/accounts/transfers_screen.dart';
import 'package:clothmate/screens/accounts/transaction_history_screen.dart';
import 'package:clothmate/screens/reports/reports_screen.dart';
import 'package:clothmate/screens/settings/settings_screen.dart';
import 'package:clothmate/screens/settings/pin_screen.dart';
import 'package:clothmate/screens/backup/backup_screen.dart';
import 'package:clothmate/screens/dashboard/first_time_setup.dart';

AppDatabase createTestDb() => AppDatabase.test(NativeDatabase.memory());

Future<void> seedTestData(AppDatabase db) async {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;

  await db.into(db.garmentTypes).insert(
    GarmentTypesCompanion.insert(name: 'Shirt', createdAt: now),
  );
  await db.into(db.garmentTypes).insert(
    GarmentTypesCompanion.insert(name: 'Trousers with a Very Long Name for Testing', createdAt: now),
  );
  await db.into(db.materials).insert(
    MaterialsCompanion.insert(garmentTypeId: 1, name: 'Cotton Premium Extra Soft'),
  );
  await db.into(db.materials).insert(
    MaterialsCompanion.insert(garmentTypeId: 2, name: 'Polyester'),
  );
  await db.into(db.sizes).insert(SizesCompanion.insert(name: 'XS'));
  await db.into(db.sizes).insert(SizesCompanion.insert(name: 'XXL with Extra Long Label'));
  await db.into(db.products).insert(
    ProductsCompanion.insert(
      garmentTypeId: 1, materialId: 1, sizeId: 1,
      sku: 'SKU-001', sellingPrice: 99999, stockQty: const Value(3),
      createdAt: now, updatedAt: now,
    ),
  );
  await db.into(db.workers).insert(
    WorkersCompanion.insert(
      name: 'Ravi Kumar with a very very very long name for testing',
      dailyWage: 50000, createdAt: now,
    ),
  );
  await db.into(db.workers).insert(
    WorkersCompanion.insert(name: 'A', dailyWage: 15000000, createdAt: now),
  );
  await db.into(db.accounts).insert(
    AccountsCompanion.insert(name: 'Main Cash', accountType: 'cash', createdAt: now),
  );
  await db.into(db.accounts).insert(
    AccountsCompanion.insert(name: 'HDFC Bank Savings Account', accountType: 'bank', createdAt: now),
  );
}

Widget wrapInApp(Widget child, AppDatabase db) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDb();
    await seedTestData(db);
  });

  tearDown(() async {
    await db.close();
  });

  WidgetOverflowTest(String screenName, Widget Function() builder) {
    testWidgets('$screenName renders at 320px without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = ui.Size(320 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(builder());
      await tester.pump();

      final errors = <Object>[];
      while (tester.takeException() != null) {
        errors.add(tester.takeException()!);
      }

      final overflowErrors = errors.where((e) {
        final msg = e.toString().toLowerCase();
        return msg.contains('overflowed') || msg.contains('overflow');
      }).toList();

      expect(overflowErrors, isEmpty,
        reason: '$screenName had RenderFlex overflow at 320px: ${overflowErrors.map((e) => e.toString().substring(0, 200)).join('\n')}');
    });
  }

  group('Workers Screen', () {
    WidgetOverflowTest('WorkersScreen', () => wrapInApp(const WorkersScreen(), db));
  });
  group('Daily Wages Screen', () {
    WidgetOverflowTest('DailyWagesScreen', () => wrapInApp(const DailyWagesScreen(), db));
  });
  group('Sales Screen', () {
    WidgetOverflowTest('SalesScreen', () => wrapInApp(const SalesScreen(), db));
  });
  group('Garments Screen', () {
    WidgetOverflowTest('GarmentsScreen', () => wrapInApp(const GarmentsScreen(), db));
  });
  group('Add Garment Screen', () {
    WidgetOverflowTest('AddGarmentScreen', () => wrapInApp(const AddGarmentScreen(), db));
  });
  group('Create Sale Screen', () {
    WidgetOverflowTest('CreateSaleScreen', () => wrapInApp(const CreateSaleScreen(), db));
  });
  group('Accounts Screen', () {
    WidgetOverflowTest('AccountsScreen', () => wrapInApp(const AccountsScreen(), db));
  });
  group('Income Expenses Screen', () {
    WidgetOverflowTest('IncomeExpensesScreen', () => wrapInApp(const IncomeExpensesScreen(), db));
  });
  group('Transfers Screen', () {
    WidgetOverflowTest('TransfersScreen', () => wrapInApp(const TransfersScreen(), db));
  });
  group('Transaction History Screen', () {
    WidgetOverflowTest('TransactionHistoryScreen', () => wrapInApp(const TransactionHistoryScreen(), db));
  });
  group('Reports Screen', () {
    WidgetOverflowTest('ReportsScreen', () => wrapInApp(const ReportsScreen(), db));
  });
  group('Settings Screen', () {
    WidgetOverflowTest('SettingsScreen', () => wrapInApp(const SettingsScreen(), db));
  });
  group('PIN Screen', () {
    WidgetOverflowTest('PinScreen', () => wrapInApp(const PinScreen(), db));
  });
  group('Backup Screen', () {
    WidgetOverflowTest('BackupScreen', () => wrapInApp(const BackupScreen(), db));
  });
  group('First Time Setup Screen', () {
    WidgetOverflowTest('FirstTimeSetupScreen', () => wrapInApp(const FirstTimeSetupScreen(), db));
  });
}
