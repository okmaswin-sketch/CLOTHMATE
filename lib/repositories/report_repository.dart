import 'package:drift/drift.dart';
import '../data/database.dart';
import '../core/currency.dart';
import '../core/transaction_id.dart';

class IncomeRepository {
  final AppDatabase _db;

  IncomeRepository(this._db);

  Future<void> addIncome({
    required String source,
    required int amount,
    required String paymentType,
    String? description,
  }) async {
    final now = DateTime.now();
    final nowMillis = now.toUtc().millisecondsSinceEpoch;

    final seq = await _db.incomeDao.getNextIncomeSeq(DateFormatter.dateKeyCompact(now));
    final txnId = TransactionIdGenerator.income(now, seq + 1);

    await _db.transaction(() async {
      await _db.incomeDao.insertIncome(IncomeCompanion.insert(
        source: source,
        amount: amount,
        paymentType: paymentType,
        description: Value(description),
        occurredAt: nowMillis,
        transactionId: Value(txnId),
      ));

      final account = paymentType == 'cash' ? 'cash' : 'bank';
      await _db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: txnId,
        type: 'income',
        account: account,
        amount: amount,
        referenceTable: Value('income'),
        referenceId: Value(seq + 1),
        occurredAt: nowMillis,
        description: Value('Income: $source'),
      ));
    });
  }
}

class ExpenseRepository {
  final AppDatabase _db;

  ExpenseRepository(this._db);

  Future<void> addExpense({
    required String category,
    required int amount,
    required String paymentType,
    String? description,
    String? notes,
  }) async {
    final now = DateTime.now();
    final nowMillis = now.toUtc().millisecondsSinceEpoch;

    final seq =
        await _db.expenseDao.getNextExpenseSeq(DateFormatter.dateKeyCompact(now));
    final txnId = TransactionIdGenerator.expense(now, seq + 1);

    await _db.transaction(() async {
      await _db.expenseDao.insertExpense(ExpensesCompanion.insert(
        category: category,
        amount: amount,
        paymentType: paymentType,
        occurredAt: nowMillis,
        description: Value(description),
        notes: Value(notes),
        transactionId: Value(txnId),
      ));

      final account = paymentType == 'cash' ? 'cash' : 'bank';
      await _db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: txnId,
        type: 'expense',
        account: account,
        amount: -amount,
        referenceTable: Value('expenses'),
        referenceId: Value(seq + 1),
        occurredAt: nowMillis,
        description: Value('Expense: $category'),
      ));
    });
  }
}

class TransferRepository {
  final AppDatabase _db;

  TransferRepository(this._db);

  Future<void> transfer({
    required String fromAccount,
    required String toAccount,
    required int amount,
    String? reason,
    String? notes,
    int? fromAccountId,
    int? toAccountId,
    String? fromAccountType,
    String? toAccountType,
  }) async {
    if (fromAccountId != null && toAccountId != null && fromAccountId == toAccountId) {
      throw Exception('Cannot transfer to the same account');
    }

    final now = DateTime.now();
    final nowMillis = now.toUtc().millisecondsSinceEpoch;

    final seq =
        await _db.transferDao.getNextTransferSeq(DateFormatter.dateKeyCompact(now));
    final txnId = TransactionIdGenerator.transfer(now, seq + 1);

    await _db.transaction(() async {
      await _db.transferDao.insertTransfer(TransfersCompanion.insert(
        transferId: txnId,
        fromAccount: fromAccount,
        toAccount: toAccount,
        fromAccountId: Value(fromAccountId),
        toAccountId: Value(toAccountId),
        amount: amount,
        reason: Value(reason),
        notes: Value(notes),
        occurredAt: nowMillis,
      ));

      final transferRow = await _db.customSelect(
        'SELECT id FROM transfers WHERE transfer_id = ?',
        variables: [Variable.withString(txnId)],
      ).getSingle();
      final transferRowId = transferRow.data['id'] as int;

      final fromType = fromAccountType ?? fromAccount;
      final toType = toAccountType ?? toAccount;

      final txnIdOut = '${txnId}O';
      final txnIdIn = '${txnId}I';

      if (fromType == 'other' && toType != 'other') {
        await _db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
          transactionId: txnIdIn,
          type: 'transfer_in',
          account: toType,
          amount: amount,
          referenceTable: Value('transfers'),
          referenceId: Value(transferRowId),
          occurredAt: nowMillis,
          description: Value('Transfer from $fromAccount: ${reason ?? ""}'),
        ));
      } else if (toType == 'other' && fromType != 'other') {
        await _db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
          transactionId: txnIdOut,
          type: 'transfer_out',
          account: fromType,
          amount: -amount,
          referenceTable: Value('transfers'),
          referenceId: Value(transferRowId),
          occurredAt: nowMillis,
          description: Value('Transfer to $toAccount: ${reason ?? ""}'),
        ));
      } else if (fromType == toType) {
        await _db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
          transactionId: txnIdOut,
          type: 'transfer_out',
          account: fromType,
          amount: -amount,
          referenceTable: Value('transfers'),
          referenceId: Value(transferRowId),
          occurredAt: nowMillis,
          description: Value('Transfer to $toAccount: ${reason ?? ""}'),
        ));
        await _db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
          transactionId: txnIdIn,
          type: 'transfer_in',
          account: toType,
          amount: amount,
          referenceTable: Value('transfers'),
          referenceId: Value(transferRowId),
          occurredAt: nowMillis,
          description: Value('Transfer from $fromAccount: ${reason ?? ""}'),
        ));
      } else {
        await _db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
          transactionId: txnIdOut,
          type: 'transfer_out',
          account: fromType,
          amount: -amount,
          referenceTable: Value('transfers'),
          referenceId: Value(transferRowId),
          occurredAt: nowMillis,
          description: Value('Transfer to $toAccount: ${reason ?? ""}'),
        ));
        await _db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
          transactionId: txnIdIn,
          type: 'transfer_in',
          account: toType,
          amount: amount,
          referenceTable: Value('transfers'),
          referenceId: Value(transferRowId),
          occurredAt: nowMillis,
          description: Value('Transfer from $fromAccount: ${reason ?? ""}'),
        ));
      }
    });
  }
}
