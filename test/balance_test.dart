import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:clothmate/data/database.dart';

AppDatabase createTestDb() {
  return AppDatabase.test(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('Balance computation', () {
    test('Empty ledger returns zero balance', () async {
      final cash = await db.ledgerDao.getCashBalance();
      final bank = await db.ledgerDao.getBankBalance();
      expect(cash, 0);
      expect(bank, 0);
    });

    test('Sale increases cash balance', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_TEST_001',
        type: 'sale',
        account: 'cash',
        amount: 50000,
        occurredAt: now,
      ));
      final cash = await db.ledgerDao.getCashBalance();
      expect(cash, 50000);
    });

    test('Sale increases bank balance', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_TEST_002',
        type: 'sale',
        account: 'bank',
        amount: 75000,
        occurredAt: now,
      ));
      final bank = await db.ledgerDao.getBankBalance();
      expect(bank, 75000);
    });

    test('Expense decreases cash balance', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      // Add income first
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'I_TEST_001',
        type: 'income',
        account: 'cash',
        amount: 100000,
        occurredAt: now,
      ));
      // Then expense
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'E_TEST_001',
        type: 'expense',
        account: 'cash',
        amount: -25000,
        occurredAt: now,
      ));
      final cash = await db.ledgerDao.getCashBalance();
      expect(cash, 75000);
    });

    test('Wage payment decreases cash balance', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_TEST_003',
        type: 'sale',
        account: 'cash',
        amount: 100000,
        occurredAt: now,
      ));
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'W_TEST_001',
        type: 'wage',
        account: 'cash',
        amount: -5000,
        occurredAt: now,
      ));
      final cash = await db.ledgerDao.getCashBalance();
      expect(cash, 95000);
    });

    test('Transfer: cash decreases, bank increases, total unchanged', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      
      // Seed cash with some money
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_TEST_004',
        type: 'sale',
        account: 'cash',
        amount: 100000,
        occurredAt: now,
      ));
      
      // Seed bank with some money
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_TEST_005',
        type: 'sale',
        account: 'bank',
        amount: 200000,
        occurredAt: now,
      ));
      
      // Cash→Bank transfer of 30000
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'T_TEST_001_OUT',
        type: 'transfer_out',
        account: 'cash',
        amount: -30000,
        occurredAt: now,
      ));
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'T_TEST_001_IN',
        type: 'transfer_in',
        account: 'bank',
        amount: 30000,
        occurredAt: now,
      ));
      
      final cash = await db.ledgerDao.getCashBalance();
      final bank = await db.ledgerDao.getBankBalance();
      
      expect(cash, 70000);   // 100000 - 30000
      expect(bank, 230000);  // 200000 + 30000
      expect(cash + bank, 300000); // Total unchanged
    });

    test('Sale return decreases cash balance', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_TEST_006',
        type: 'sale',
        account: 'cash',
        amount: 50000,
        occurredAt: now,
      ));
      // Return with refund
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_TEST_006R',
        type: 'sale',
        account: 'cash',
        amount: -20000,
        occurredAt: now,
      ));
      final cash = await db.ledgerDao.getCashBalance();
      expect(cash, 30000);
    });

    test('Mixed transactions across accounts', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      
      // Cash sale
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_MIX_001', type: 'sale', account: 'cash',
        amount: 80000, occurredAt: now,
      ));
      // Bank sale
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_MIX_002', type: 'sale', account: 'bank',
        amount: 120000, occurredAt: now,
      ));
      // Cash expense
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'E_MIX_001', type: 'expense', account: 'cash',
        amount: -10000, occurredAt: now,
      ));
      // Bank income
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'I_MIX_001', type: 'income', account: 'bank',
        amount: 5000, occurredAt: now,
      ));
      
      final cash = await db.ledgerDao.getCashBalance();
      final bank = await db.ledgerDao.getBankBalance();
      
      expect(cash, 70000);   // 80000 - 10000
      expect(bank, 125000);  // 120000 + 5000
    });
  });

  group('Opening balance', () {
    test('Opening balance contributes to computed balance', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final today = DateTime.now();
      final dateStr = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // Set opening balance for today
      await db.ledgerDao.createOpeningBalance(dateStr, 50000, 100000);
      
      // Add some transactions
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_OB_001', type: 'sale', account: 'cash',
        amount: 25000, occurredAt: now,
      ));
      
      final cash = await db.ledgerDao.getCashBalance();
      expect(cash, 75000); // 50000 opening + 25000 sale
    });
  });

  group('Filtered ledger', () {
    test('Filter by account', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_FLT_001', type: 'sale', account: 'cash',
        amount: 50000, occurredAt: now,
      ));
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_FLT_002', type: 'sale', account: 'bank',
        amount: 75000, occurredAt: now,
      ));
      
      final cashOnly = await db.ledgerDao.getFilteredLedger(account: 'cash');
      expect(cashOnly.length, 1);
      expect(cashOnly.first.amount, 50000);
      
      final bankOnly = await db.ledgerDao.getFilteredLedger(account: 'bank');
      expect(bankOnly.length, 1);
      expect(bankOnly.first.amount, 75000);
      
      final all = await db.ledgerDao.getFilteredLedger(account: 'all');
      expect(all.length, 2);
    });

    test('Filter by type', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_FLT_003', type: 'sale', account: 'cash',
        amount: 50000, occurredAt: now,
      ));
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'E_FLT_001', type: 'expense', account: 'cash',
        amount: -5000, occurredAt: now,
      ));
      
      final salesOnly = await db.ledgerDao.getFilteredLedger(types: ['sale']);
      expect(salesOnly.length, 1);
      expect(salesOnly.first.type, 'sale');
    });

    test('Filter by date range', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final yesterday = now - 86400000;
      
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_FLT_004', type: 'sale', account: 'cash',
        amount: 50000, occurredAt: yesterday,
      ));
      await db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: 'S_FLT_005', type: 'sale', account: 'cash',
        amount: 75000, occurredAt: now,
      ));
      
      final todayOnly = await db.ledgerDao.getFilteredLedger(start: now - 1000, end: now + 1000);
      expect(todayOnly.length, 1);
    });
  });
}
