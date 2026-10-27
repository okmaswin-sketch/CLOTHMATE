import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class UsersSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get pinHash => text().nullable()();
  IntColumn get biometricEnabled => integer().withDefault(const Constant(0))();
  IntColumn get autoLockMinutes => integer().withDefault(const Constant(5))();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(5))();
  IntColumn get allowPriceOverride => integer().withDefault(const Constant(0))();
  TextColumn get currencySymbol => text().withDefault(const Constant('₹'))();
  TextColumn get businessName => text().withDefault(const Constant('ClothMate'))();
  TextColumn get businessAddress => text().nullable()();
  IntColumn get gstEnabled => integer().withDefault(const Constant(0))();
  TextColumn get gstNumber => text().nullable()();
  IntColumn get createdAt => integer()();
}

class GarmentTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  IntColumn get createdAt => integer()();
}

class Materials extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get garmentTypeId => integer().references(GarmentTypes, #id)();
  TextColumn get name => text()();
  IntColumn get isActive => integer().withDefault(const Constant(1))();

  @override
  List<Set<Column>> get uniqueKeys => [{garmentTypeId, name}];
}

class Sizes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get garmentTypeId => integer().references(GarmentTypes, #id)();
  IntColumn get materialId => integer().references(Materials, #id)();
  IntColumn get sizeId => integer().references(Sizes, #id)();
  TextColumn get sku => text().unique()();
  IntColumn get sellingPrice => integer()();
  IntColumn get costPrice => integer().nullable()();
  IntColumn get stockQty => integer().withDefault(const Constant(0))();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [{garmentTypeId, materialId, sizeId}];
}

class StockAdjustments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get changeQty => integer()();
  TextColumn get reason => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
}

class Workers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get dailyWage => integer()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
}

class Wages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workerId => integer().references(Workers, #id)();
  IntColumn get amount => integer()();
  IntColumn get wageDate => integer()();
  TextColumn get paymentStatus => text()();
  TextColumn get paymentMethod => text().nullable()();
  IntColumn get paidAt => integer().nullable()();
  TextColumn get transactionId => text().nullable().unique()();
}

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionId => text().unique()();
  IntColumn get saleDate => integer()();
  TextColumn get paymentMethod => text()();
  IntColumn get subtotal => integer()();
  IntColumn get discount => integer().withDefault(const Constant(0))();
  IntColumn get taxAmount => integer().withDefault(const Constant(0))();
  IntColumn get totalAmount => integer()();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  TextColumn get notes => text().nullable()();
}

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  IntColumn get unitPrice => integer()();
  IntColumn get lineTotal => integer()();
}

class SaleReturns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleItemId => integer().references(SaleItems, #id)();
  IntColumn get quantityReturned => integer()();
  IntColumn get refundAmount => integer()();
  TextColumn get refundMethod => text()();
  IntColumn get returnDate => integer()();
  TextColumn get reason => text().nullable()();
}

class Income extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get source => text()();
  IntColumn get amount => integer()();
  TextColumn get paymentType => text()();
  TextColumn get description => text().nullable()();
  IntColumn get occurredAt => integer()();
  TextColumn get transactionId => text().nullable().unique()();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  TextColumn get description => text().nullable()();
  IntColumn get amount => integer()();
  TextColumn get paymentType => text()();
  IntColumn get occurredAt => integer()();
  TextColumn get notes => text().nullable()();
  TextColumn get transactionId => text().nullable().unique()();
}

class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transferId => text().unique()();
  TextColumn get fromAccount => text()();
  TextColumn get toAccount => text()();
  IntColumn get fromAccountId => integer().nullable().references(Accounts, #id)();
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();
  IntColumn get amount => integer()();
  TextColumn get reason => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get occurredAt => integer()();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get accountType => text()(); // 'cash', 'bank', 'other'
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  IntColumn get createdAt => integer()();
}

class LedgerTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionId => text().unique()();
  TextColumn get type => text()();
  TextColumn get account => text()();
  IntColumn get amount => integer()();
  TextColumn get referenceTable => text().nullable()();
  IntColumn get referenceId => integer().nullable()();
  IntColumn get occurredAt => integer()();
  TextColumn get description => text().nullable()();
}

class DailyOpeningBalances extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get balanceDate => text().unique()();
  IntColumn get openingCash => integer()();
  IntColumn get openingBank => integer()();
  IntColumn get isLocked => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [
  UsersSettings,
  GarmentTypes,
  Materials,
  Sizes,
  Products,
  StockAdjustments,
  Workers,
  Wages,
  Sales,
  SaleItems,
  SaleReturns,
  Income,
  Expenses,
  Transfers,
  Accounts,
  LedgerTransactions,
  DailyOpeningBalances,
], daos: [
  SettingsDao,
  GarmentDao,
  ProductDao,
  SalesDao,
  LedgerDao,
  WorkerDao,
  WageDao,
  IncomeDao,
  ExpenseDao,
  TransferDao,
  AccountDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.test(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(usersSettings).insert(UsersSettingsCompanion.insert(
            createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
          ));
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(accounts);
          }
        },
        beforeOpen: (details) async {
          if (details.wasCreated) {
            final now = DateTime.now().toUtc().millisecondsSinceEpoch;
            await accountDao.seedDefaultAccounts(now);
          }
          if (details.hadUpgrade && details.versionBefore! < 2) {
            final now = DateTime.now().toUtc().millisecondsSinceEpoch;
            if (!await accountDao.hasAnyAccount()) {
              await accountDao.seedDefaultAccounts(now);
            }
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'clothmate.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// ═══════════════════════════════════════════
// DAOs
// ═══════════════════════════════════════════

@DriftAccessor(tables: [UsersSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<dynamic> getSettings() async {
    final rows = await select(usersSettings).get();
    return rows.first;
  }

  Future<void> updateSettings(UsersSettingsCompanion companion) async {
    await (update(usersSettings)..where((t) => t.id.equals(1))).write(companion);
  }
}

@DriftAccessor(tables: [GarmentTypes, Materials, Sizes])
class GarmentDao extends DatabaseAccessor<AppDatabase>
    with _$GarmentDaoMixin {
  GarmentDao(super.db);

  Future<List<GarmentType>> getAllGarmentTypes() =>
      (select(garmentTypes)..where((t) => t.isActive.equals(1))).get();

  Stream<List<GarmentType>> watchAllGarmentTypes() =>
      (select(garmentTypes)..where((t) => t.isActive.equals(1))).watch();

  Future<int> insertGarmentType(GarmentTypesCompanion entry) =>
      into(garmentTypes).insert(entry);

  Future<void> updateGarmentType(int id, GarmentTypesCompanion companion) =>
      (update(garmentTypes)..where((t) => t.id.equals(id))).write(companion);

  Future<List<Material>> getMaterialsForType(int typeId) =>
      (select(materials)..where((t) => t.garmentTypeId.equals(typeId) & t.isActive.equals(1)))
          .get();

  Future<List<Material>> getAllMaterials() =>
      (select(materials)..where((t) => t.isActive.equals(1))).get();

  Stream<List<Material>> watchMaterialsForType(int typeId) =>
      (select(materials)..where((t) => t.garmentTypeId.equals(typeId) & t.isActive.equals(1)))
          .watch();

  Future<int> insertMaterial(MaterialsCompanion entry) =>
      into(materials).insert(entry);

  Future<List<Size>> getAllSizes() =>
      (select(sizes)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Stream<List<Size>> watchAllSizes() =>
      (select(sizes)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();

  Future<int> insertSize(SizesCompanion entry) => into(sizes).insert(entry);

  Future<Material?> getMaterial(int id) =>
      (select(materials)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Size?> getSize(int id) =>
      (select(sizes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<GarmentType?> getGarmentType(int id) =>
      (select(garmentTypes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> disableGarmentType(int id) =>
      (update(garmentTypes)..where((t) => t.id.equals(id)))
          .write(const GarmentTypesCompanion(isActive: Value(0)));
}

@DriftAccessor(tables: [Products, GarmentTypes, Materials, Sizes, StockAdjustments])
class ProductDao extends DatabaseAccessor<AppDatabase>
    with _$ProductDaoMixin {
  ProductDao(super.db);

  Future<List<Product>> getAllActiveProducts() =>
      (select(products)..where((t) => t.isActive.equals(1))).get();

  Stream<List<Product>> watchAllActiveProducts() =>
      (select(products)..where((t) => t.isActive.equals(1))).watch();

  Future<List<Product>> getProductsForVariant(
      int typeId, int materialId, int sizeId) =>
      (select(products)
            ..where((t) =>
                t.garmentTypeId.equals(typeId) &
                t.materialId.equals(materialId) &
                t.sizeId.equals(sizeId)))
          .get();

  Future<Product?> getProduct(int id) =>
      (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Product?> findProductBySku(String sku) =>
      (select(products)..where((t) => t.sku.equals(sku) & t.isActive.equals(1))).getSingleOrNull();

  Future<int> insertProduct(ProductsCompanion entry) =>
      into(products).insert(entry);

  Future<void> updateStock(int productId, int newQty) =>
      (update(products)..where((t) => t.id.equals(productId)))
          .write(ProductsCompanion(stockQty: Value(newQty)));

  Future<void> insertStockAdjustment(StockAdjustmentsCompanion entry) =>
      into(stockAdjustments).insert(entry);

  Future<List<Product>> getLowStockProducts(int threshold) =>
      (select(products)
            ..where((t) =>
                t.isActive.equals(1) & t.stockQty.isSmallerOrEqualValue(threshold)))
          .get();

  Stream<List<Product>> watchLowStockProducts(int threshold) =>
      (select(products)
            ..where((t) =>
                t.isActive.equals(1) & t.stockQty.isSmallerOrEqualValue(threshold)))
          .watch();

  Future<int> getNextSkuSeq(String prefix) async {
    final count = await customSelect(
      'SELECT COUNT(*) as c FROM products WHERE sku LIKE ?',
      variables: [Variable.withString('$prefix%')],
    ).getSingle();
    return count.data['c'] as int;
  }
}

@DriftAccessor(tables: [Sales, SaleItems, SaleReturns, Products, LedgerTransactions])
class SalesDao extends DatabaseAccessor<AppDatabase>
    with _$SalesDaoMixin {
  SalesDao(super.db);

  Future<List<Sale>> getSalesForDate(int dayStart, int dayEnd) =>
      (select(sales)
            ..where((t) =>
                t.saleDate.isBiggerOrEqualValue(dayStart) &
                t.saleDate.isSmallerOrEqualValue(dayEnd))
            ..orderBy([(t) => OrderingTerm.desc(t.saleDate)]))
          .get();

  Stream<List<Sale>> watchSalesForDate(int dayStart, int dayEnd) =>
      (select(sales)
            ..where((t) =>
                t.saleDate.isBiggerOrEqualValue(dayStart) &
                t.saleDate.isSmallerOrEqualValue(dayEnd))
            ..orderBy([(t) => OrderingTerm.desc(t.saleDate)]))
          .watch();

  Future<List<Sale>> getAllSales() =>
      (select(sales)..orderBy([(t) => OrderingTerm.desc(t.saleDate)])).get();

  Future<Sale?> getSale(int id) =>
      (select(sales)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<SaleItem>> getSaleItems(int saleId) =>
      (select(saleItems)..where((t) => t.saleId.equals(saleId))).get();

  Future<int> insertSale(SalesCompanion entry) => into(sales).insert(entry);

  Future<int> insertSaleItem(SaleItemsCompanion entry) =>
      into(saleItems).insert(entry);

  Future<void> insertSaleReturn(SaleReturnsCompanion entry) =>
      into(saleReturns).insert(entry);

  Future<List<SaleReturn>> getReturnsForSaleItem(int saleItemId) =>
      (select(saleReturns)..where((t) => t.saleItemId.equals(saleItemId))).get();

  Future<void> updateSaleStatus(int saleId, String status) =>
      (update(sales)..where((t) => t.id.equals(saleId)))
          .write(SalesCompanion(status: Value(status)));

  Future<int> getNextSaleSeq(String datePrefix) async {
    final count = await customSelect(
      'SELECT COUNT(*) as c FROM sales WHERE transaction_id LIKE ?',
      variables: [Variable.withString('S$datePrefix%')],
    ).getSingle();
    return count.data['c'] as int;
  }

  Future<int> getTotalSalesForDate(int dayStart, int dayEnd) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(total_amount), 0) as total FROM sales WHERE sale_date >= ? AND sale_date <= ?',
      variables: [Variable.withInt(dayStart), Variable.withInt(dayEnd)],
    ).getSingle();
    return result.data['total'] as int;
  }

  Future<int> getCashSalesForDate(int dayStart, int dayEnd) async {
    final result = await customSelect(
      "SELECT COALESCE(SUM(total_amount), 0) as total FROM sales WHERE sale_date >= ? AND sale_date <= ? AND payment_method = 'cash'",
      variables: [Variable.withInt(dayStart), Variable.withInt(dayEnd)],
    ).getSingle();
    return result.data['total'] as int;
  }

  Future<int> getBankSalesForDate(int dayStart, int dayEnd) async {
    final result = await customSelect(
      "SELECT COALESCE(SUM(total_amount), 0) as total FROM sales WHERE sale_date >= ? AND sale_date <= ? AND payment_method != 'cash'",
      variables: [Variable.withInt(dayStart), Variable.withInt(dayEnd)],
    ).getSingle();
    return result.data['total'] as int;
  }

  Future<int> getTotalItemsSoldForDate(int dayStart, int dayEnd) async {
    final result = await customSelect(
      '''SELECT COALESCE(SUM(si.quantity), 0) as total
         FROM sale_items si
         JOIN sales s ON si.sale_id = s.id
         WHERE s.sale_date >= ? AND s.sale_date <= ?''',
      variables: [Variable.withInt(dayStart), Variable.withInt(dayEnd)],
    ).getSingle();
    return result.data['total'] as int;
  }
}

@DriftAccessor(tables: [LedgerTransactions, DailyOpeningBalances])
class LedgerDao extends DatabaseAccessor<AppDatabase>
    with _$LedgerDaoMixin {
  LedgerDao(super.db);

  Future<void> insertLedgerEntry(LedgerTransactionsCompanion entry) =>
      into(ledgerTransactions).insert(entry);

  Future<int> getCashBalance() async {
    final todayStr = _dateStr(DateTime.now());
    final opening = await customSelect(
      'SELECT COALESCE(opening_cash, 0) as val FROM daily_opening_balances WHERE balance_date = ?',
      variables: [Variable.withString(todayStr)],
    ).getSingleOrNull();
    final openingAmount = (opening?.data['val'] as int?) ?? 0;

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0) as total FROM ledger_transactions WHERE account = ? AND occurred_at <= ?',
      variables: [Variable.withString('cash'), Variable.withInt(now)],
    ).getSingle();
    return openingAmount + (result.data['total'] as int);
  }

  Future<int> getBankBalance() async {
    final todayStr = _dateStr(DateTime.now());
    final opening = await customSelect(
      'SELECT COALESCE(opening_bank, 0) as val FROM daily_opening_balances WHERE balance_date = ?',
      variables: [Variable.withString(todayStr)],
    ).getSingleOrNull();
    final openingAmount = (opening?.data['val'] as int?) ?? 0;

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0) as total FROM ledger_transactions WHERE account = ? AND occurred_at <= ?',
      variables: [Variable.withString('bank'), Variable.withInt(now)],
    ).getSingle();
    return openingAmount + (result.data['total'] as int);
  }

  Stream<int> watchCashBalance() {
    return watchSingleValue(
        'SELECT COALESCE(SUM(amount), 0) as total FROM ledger_transactions WHERE account = \'cash\'');
  }

  Stream<int> watchBankBalance() {
    return watchSingleValue(
        'SELECT COALESCE(SUM(amount), 0) as total FROM ledger_transactions WHERE account = \'bank\'');
  }

  Stream<int> watchSingleValue(String sql) {
    return customSelect(sql).watch().map((rows) => rows.first.data['total'] as int);
  }

  Future<List<LedgerTransaction>> getLedgerForAccount(String account) =>
      (select(ledgerTransactions)
            ..where((t) => t.account.equals(account))
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .get();

  Stream<List<LedgerTransaction>> watchLedgerForAccount(String account) =>
      (select(ledgerTransactions)
            ..where((t) => t.account.equals(account))
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .watch();

  Future<List<LedgerTransaction>> getLedgerForDateRange(
      int start, int end) =>
      (select(ledgerTransactions)
            ..where((t) =>
                t.occurredAt.isBiggerOrEqualValue(start) &
                t.occurredAt.isSmallerOrEqualValue(end))
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .get();

  Stream<List<LedgerTransaction>> watchLedgerForDateRange(
      int start, int end) =>
      (select(ledgerTransactions)
            ..where((t) =>
                t.occurredAt.isBiggerOrEqualValue(start) &
                t.occurredAt.isSmallerOrEqualValue(end))
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .watch();

  Future<bool> hasOpeningBalance(String dateStr) async {
    final result = await customSelect(
      'SELECT COUNT(*) as c FROM daily_opening_balances WHERE balance_date = ?',
      variables: [Variable.withString(dateStr)],
    ).getSingle();
    return (result.data['c'] as int) > 0;
  }

  Future<void> createOpeningBalance(String dateStr, int cash, int bank) =>
      into(dailyOpeningBalances).insert(DailyOpeningBalancesCompanion(
        balanceDate: Value(dateStr),
        openingCash: Value(cash),
        openingBank: Value(bank),
      ));

  Future<DailyOpeningBalance?> getOpeningBalance(String dateStr) =>
      (select(dailyOpeningBalances)
            ..where((t) => t.balanceDate.equals(dateStr)))
          .getSingleOrNull();

  Future<List<DailyOpeningBalance>> getAllOpeningBalances() =>
      (select(dailyOpeningBalances)
            ..orderBy([(t) => OrderingTerm.desc(t.balanceDate)]))
          .get();

  Future<List<LedgerTransaction>> getRecentTransactions(int limit) =>
      (select(ledgerTransactions)
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
            ..limit(limit))
          .get();

  Stream<List<LedgerTransaction>> watchRecentTransactions(int limit) =>
      (select(ledgerTransactions)
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
            ..limit(limit))
          .watch();

  Future<List<LedgerTransaction>> getFilteredLedger({
    int? start,
    int? end,
    List<String>? types,
    String? account,
  }) async {
    final query = select(ledgerTransactions);
    
    query.where((t) {
      Expression<bool> combined = const Constant(true);
      
      if (start != null) {
        combined = combined & t.occurredAt.isBiggerOrEqualValue(start);
      }
      if (end != null) {
        combined = combined & t.occurredAt.isSmallerOrEqualValue(end);
      }
      if (types != null && types.isNotEmpty) {
        combined = combined & t.type.isIn(types);
      }
      if (account != null && account != 'all') {
        combined = combined & t.account.equals(account);
      }
      
      return combined;
    });
    
    query.orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);
    return query.get();
  }

  Future<int> getExpensesForDate(String category, int dayStart, int dayEnd) async {
    final result = await customSelect(
      "SELECT COALESCE(SUM(e.amount), 0) as total FROM expenses e WHERE e.category LIKE ? AND e.occurred_at >= ? AND e.occurred_at <= ?",
      variables: [
        Variable.withString('$category%'),
        Variable.withInt(dayStart),
        Variable.withInt(dayEnd),
      ],
    ).getSingle();
    return result.data['total'] as int;
  }

  Future<int> getWagesPaidForDate(int dayStart, int dayEnd) async {
    final result = await customSelect(
      "SELECT COALESCE(SUM(amount), 0) as total FROM wages WHERE payment_status = 'paid' AND paid_at >= ? AND paid_at <= ?",
      variables: [Variable.withInt(dayStart), Variable.withInt(dayEnd)],
    ).getSingle();
    return result.data['total'] as int;
  }

  Future<int> getIncomeForDate(String paymentType, int dayStart, int dayEnd) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0) as total FROM income WHERE payment_type = ? AND occurred_at >= ? AND occurred_at <= ?',
      variables: [
        Variable.withString(paymentType),
        Variable.withInt(dayStart),
        Variable.withInt(dayEnd),
      ],
    ).getSingle();
    return result.data['total'] as int;
  }

  Future<int> getTransfersForDate(
      String fromAccount, String toAccount, int dayStart, int dayEnd) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transfers WHERE from_account = ? AND to_account = ? AND occurred_at >= ? AND occurred_at <= ?',
      variables: [
        Variable.withString(fromAccount),
        Variable.withString(toAccount),
        Variable.withInt(dayStart),
        Variable.withInt(dayEnd),
      ],
    ).getSingle();
    return result.data['total'] as int;
  }

  String _dateStr(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

@DriftAccessor(tables: [Workers])
class WorkerDao extends DatabaseAccessor<AppDatabase>
    with _$WorkerDaoMixin {
  WorkerDao(super.db);

  Future<List<Worker>> getAllWorkers() =>
      (select(workers)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Stream<List<Worker>> watchAllWorkers() =>
      (select(workers)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<List<Worker>> getActiveWorkers() =>
      (select(workers)..where((t) => t.status.equals('active'))).get();

  Stream<List<Worker>> watchActiveWorkers() =>
      (select(workers)..where((t) => t.status.equals('active'))).watch();

  Future<int> insertWorker(WorkersCompanion entry) =>
      into(workers).insert(entry);

  Future<void> updateWorker(int id, WorkersCompanion companion) =>
      (update(workers)..where((t) => t.id.equals(id))).write(companion);

  Future<void> disableWorker(int id) =>
      (update(workers)..where((t) => t.id.equals(id)))
          .write(const WorkersCompanion(status: Value('inactive')));
}

@DriftAccessor(tables: [Wages, Workers])
class WageDao extends DatabaseAccessor<AppDatabase>
    with _$WageDaoMixin {
  WageDao(super.db);

  Future<List<Wage>> getWagesForDate(int dayStart, int dayEnd) =>
      (select(wages)
            ..where((t) =>
                t.wageDate.isBiggerOrEqualValue(dayStart) &
                t.wageDate.isSmallerOrEqualValue(dayEnd)))
          .get();

  Future<List<Wage>> getAllWages() =>
      (select(wages)..orderBy([(t) => OrderingTerm.desc(t.wageDate)])).get();

  Stream<List<Wage>> watchWagesForDate(int dayStart, int dayEnd) =>
      (select(wages)
            ..where((t) =>
                t.wageDate.isBiggerOrEqualValue(dayStart) &
                t.wageDate.isSmallerOrEqualValue(dayEnd)))
          .watch();

  Future<int> insertWage(WagesCompanion entry) => into(wages).insert(entry);

  Future<void> markWagePaid(
      int wageId, String method, int paidAt, String transactionId) =>
      (update(wages)..where((t) => t.id.equals(wageId)))
          .write(WagesCompanion(
        paymentStatus: const Value('paid'),
        paymentMethod: Value(method),
        paidAt: Value(paidAt),
        transactionId: Value(transactionId),
      ));

  Future<Wage?> getWageForWorkerToday(int workerId, int dayStart, int dayEnd) =>
      (select(wages)
            ..where((t) =>
                t.workerId.equals(workerId) &
                t.wageDate.isBiggerOrEqualValue(dayStart) &
                t.wageDate.isSmallerOrEqualValue(dayEnd)))
          .getSingleOrNull();

  Future<int> getPendingWagesCount(int dayStart, int dayEnd) async {
    final result = await customSelect(
      "SELECT COUNT(*) as c FROM wages WHERE payment_status = 'pending' AND wage_date >= ? AND wage_date <= ?",
      variables: [Variable.withInt(dayStart), Variable.withInt(dayEnd)],
    ).getSingle();
    return result.data['c'] as int;
  }
}

@DriftAccessor(tables: [Income])
class IncomeDao extends DatabaseAccessor<AppDatabase>
    with _$IncomeDaoMixin {
  IncomeDao(super.db);

  Future<int> insertIncome(IncomeCompanion entry) =>
      into(income).insert(entry);

  Future<List<IncomeData>> getIncomeForDate(int dayStart, int dayEnd) =>
      (select(income)
            ..where((t) =>
                t.occurredAt.isBiggerOrEqualValue(dayStart) &
                t.occurredAt.isSmallerOrEqualValue(dayEnd))
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .get();

  Future<List<IncomeData>> getAllIncome() =>
      (select(income)..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])).get();

  Stream<List<IncomeData>> watchIncomeForDate(int dayStart, int dayEnd) =>
      (select(income)
            ..where((t) =>
                t.occurredAt.isBiggerOrEqualValue(dayStart) &
                t.occurredAt.isSmallerOrEqualValue(dayEnd))
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .watch();

  Future<int> getNextIncomeSeq(String datePrefix) async {
    final count = await customSelect(
      'SELECT COUNT(*) as c FROM income WHERE transaction_id LIKE ?',
      variables: [Variable.withString('I$datePrefix%')],
    ).getSingle();
    return count.data['c'] as int;
  }
}

@DriftAccessor(tables: [Expenses])
class ExpenseDao extends DatabaseAccessor<AppDatabase>
    with _$ExpenseDaoMixin {
  ExpenseDao(super.db);

  Future<int> insertExpense(ExpensesCompanion entry) =>
      into(expenses).insert(entry);

  Future<List<Expense>> getExpensesForDate(int dayStart, int dayEnd) =>
      (select(expenses)
            ..where((t) =>
                t.occurredAt.isBiggerOrEqualValue(dayStart) &
                t.occurredAt.isSmallerOrEqualValue(dayEnd))
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .get();

  Future<List<Expense>> getAllExpenses() =>
      (select(expenses)..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])).get();

  Stream<List<Expense>> watchExpensesForDate(int dayStart, int dayEnd) =>
      (select(expenses)
            ..where((t) =>
                t.occurredAt.isBiggerOrEqualValue(dayStart) &
                t.occurredAt.isSmallerOrEqualValue(dayEnd))
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .watch();

  Future<int> getNextExpenseSeq(String datePrefix) async {
    final count = await customSelect(
      'SELECT COUNT(*) as c FROM expenses WHERE transaction_id LIKE ?',
      variables: [Variable.withString('E$datePrefix%')],
    ).getSingle();
    return count.data['c'] as int;
  }
}

@DriftAccessor(tables: [Transfers])
class TransferDao extends DatabaseAccessor<AppDatabase>
    with _$TransferDaoMixin {
  TransferDao(super.db);

  Future<int> insertTransfer(TransfersCompanion entry) =>
      into(transfers).insert(entry);

  Future<List<Transfer>> getAllTransfers() =>
      (select(transfers)..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])).get();

  Stream<List<Transfer>> watchAllTransfers() =>
      (select(transfers)..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])).watch();

  Future<int> getNextTransferSeq(String datePrefix) async {
    final count = await customSelect(
      'SELECT COUNT(*) as c FROM transfers WHERE transfer_id LIKE ?',
      variables: [Variable.withString('T$datePrefix%')],
    ).getSingle();
    return count.data['c'] as int;
  }
}

@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase>
    with _$AccountDaoMixin {
  AccountDao(super.db);

  Future<List<Account>> getAllActiveAccounts() =>
      (select(accounts)..where((t) => t.isActive.equals(1))
        ..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Stream<List<Account>> watchAllActiveAccounts() =>
      (select(accounts)..where((t) => t.isActive.equals(1))
        ..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<List<Account>> getAccountsByType(String type) =>
      (select(accounts)..where((t) => t.accountType.equals(type) & t.isActive.equals(1))
        ..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<int> insertAccount(AccountsCompanion entry) =>
      into(accounts).insert(entry);

  Future<void> updateAccount(int id, AccountsCompanion companion) =>
      (update(accounts)..where((t) => t.id.equals(id))).write(companion);

  Future<void> deactivateAccount(int id) =>
      (update(accounts)..where((t) => t.id.equals(id)))
          .write(const AccountsCompanion(isActive: Value(0)));

  Future<bool> hasAnyAccount() async {
    final count = await customSelect('SELECT COUNT(*) as c FROM accounts').getSingle();
    return (count.data['c'] as int) > 0;
  }

  Future<void> seedDefaultAccounts(int now) async {
    final defaults = [
      ('My Cash', 'cash'),
      ('My Bank', 'bank'),
    ];
    for (final (name, type) in defaults) {
      await into(accounts).insert(AccountsCompanion.insert(
        name: name,
        accountType: type,
        createdAt: now,
      ));
    }
  }
}
