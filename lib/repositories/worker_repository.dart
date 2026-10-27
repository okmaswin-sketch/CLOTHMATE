import 'package:drift/drift.dart';
import '../data/database.dart';
import '../core/transaction_id.dart';
import '../core/currency.dart';

class WorkerRepository {
  final AppDatabase _db;

  WorkerRepository(this._db);

  Future<void> payWage({
    required int workerId,
    required String paymentMethod,
  }) async {
    final now = DateTime.now();
    final nowMillis = now.toUtc().millisecondsSinceEpoch;
    final dayStart = DateFormatter.dayStartMillis(now);
    final dayEnd = DateFormatter.dayEndMillis(now);

    final worker = await _db.customSelect(
      'SELECT * FROM workers WHERE id = ?',
      variables: [Variable.withInt(workerId)],
    ).getSingleOrNull();
    if (worker == null) throw Exception('Worker not found');

    final name = worker.data['name'] as String;
    final dailyWage = worker.data['daily_wage'] as int;
    final existing = await _db.wageDao.getWageForWorkerToday(
        workerId, dayStart, dayEnd);
    if (existing != null && existing.paymentStatus == 'paid') {
      throw Exception('Already paid today');
    }

    final seq = await _db.customSelect(
      "SELECT COUNT(*) as c FROM wages WHERE wage_date >= ? AND wage_date <= ? AND payment_status = 'paid'",
      variables: [Variable.withInt(dayStart), Variable.withInt(dayEnd)],
    ).getSingle();
    final seqNum = (seq.data['c'] as int) + 1;
    final txnId = TransactionIdGenerator.wage(name, now, seqNum);

    await _db.transaction(() async {
      if (existing != null) {
        await _db.wageDao.markWagePaid(
            existing.id, paymentMethod, nowMillis, txnId);
      } else {
        await _db.wageDao.insertWage(WagesCompanion.insert(
          workerId: workerId,
          amount: dailyWage,
          wageDate: dayStart,
          paymentStatus: 'paid',
          paymentMethod: Value(paymentMethod),
          paidAt: Value(nowMillis),
          transactionId: Value(txnId),
        ));
      }

      final account = paymentMethod == 'cash' ? 'cash' : 'bank';
      await _db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: txnId,
        type: 'wage',
        account: account,
        amount: -dailyWage,
        referenceTable: Value('wages'),
        referenceId: Value(workerId),
        occurredAt: nowMillis,
        description: Value('Wage: $name'),
      ));
    });
  }
}
