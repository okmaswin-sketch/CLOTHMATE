import 'package:drift/drift.dart';
import '../data/database.dart';
import '../core/currency.dart';

class BalanceRepository {
  final AppDatabase _db;

  BalanceRepository(this._db);

  Future<int> getCashBalance() async {
    final today = DateTime.now();
    final todayStr = DateFormatter.dateKey(today);
    final opening = await _db.ledgerDao.getOpeningBalance(todayStr);
    final openingAmount = opening?.openingCash ?? 0;

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final result = await _db.customSelect(
      'SELECT COALESCE(SUM(amount), 0) as total FROM ledger_transactions WHERE account = ? AND occurred_at <= ?',
      variables: [Variable.withString('cash'), Variable.withInt(now)],
    ).getSingle();
    return openingAmount + (result.data['total'] as int);
  }

  Future<int> getBankBalance() async {
    final today = DateTime.now();
    final todayStr = DateFormatter.dateKey(today);
    final opening = await _db.ledgerDao.getOpeningBalance(todayStr);
    final openingAmount = opening?.openingBank ?? 0;

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final result = await _db.customSelect(
      'SELECT COALESCE(SUM(amount), 0) as total FROM ledger_transactions WHERE account = ? AND occurred_at <= ?',
      variables: [Variable.withString('bank'), Variable.withInt(now)],
    ).getSingle();
    return openingAmount + (result.data['total'] as int);
  }

  Stream<int> watchCashBalance() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      yield await getCashBalance();
    }
  }

  Stream<int> watchBankBalance() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      yield await getBankBalance();
    }
  }

  Future<void> ensureTodayOpeningBalance() async {
    final today = DateTime.now();
    final todayStr = DateFormatter.dateKey(today);
    final exists = await _db.ledgerDao.hasOpeningBalance(todayStr);
    if (!exists) {
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr = DateFormatter.dateKey(yesterday);
      final yesterdayOpening = await _db.ledgerDao.getOpeningBalance(yesterdayStr);
      int cash = 0;
      int bank = 0;
      if (yesterdayOpening != null) {
        final endOfDay = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999).toUtc().millisecondsSinceEpoch;
        final cashResult = await _db.customSelect(
          'SELECT COALESCE(SUM(amount), 0) as total FROM ledger_transactions WHERE account = ? AND occurred_at <= ?',
          variables: [Variable.withString('cash'), Variable.withInt(endOfDay)],
        ).getSingle();
        final bankResult = await _db.customSelect(
          'SELECT COALESCE(SUM(amount), 0) as total FROM ledger_transactions WHERE account = ? AND occurred_at <= ?',
          variables: [Variable.withString('bank'), Variable.withInt(endOfDay)],
        ).getSingle();
        cash = yesterdayOpening.openingCash + (cashResult.data['total'] as int);
        bank = yesterdayOpening.openingBank + (bankResult.data['total'] as int);
      }
      await _db.ledgerDao.createOpeningBalance(todayStr, cash, bank);
    }
  }

  Future<void> setFirstTimeOpeningBalance(int cash, int bank) async {
    final today = DateTime.now();
    final todayStr = DateFormatter.dateKey(today);
    await _db.ledgerDao.createOpeningBalance(todayStr, cash, bank);
  }

  Future<bool> hasAnyOpeningBalance() async {
    final result = await _db.customSelect(
      'SELECT COUNT(*) as c FROM daily_opening_balances',
    ).getSingle();
    return (result.data['c'] as int) > 0;
  }
}
