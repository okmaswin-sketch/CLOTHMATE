import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/database.dart';
import 'repositories/balance_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final balanceRepoProvider = Provider<BalanceRepository>((ref) {
  return BalanceRepository(ref.watch(databaseProvider));
});
