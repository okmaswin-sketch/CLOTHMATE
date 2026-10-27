import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/currency.dart';
import '../../data/database.dart';
import '../../providers.dart';
import '../../repositories/worker_repository.dart';
import '../dashboard/dashboard_screen.dart';

final _activeWorkersStreamProvider = StreamProvider<List<Worker>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.workerDao.watchActiveWorkers();
});

final _todayWagesStreamProvider = StreamProvider<List<Wage>>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day).toUtc().millisecondsSinceEpoch;
  final dayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toUtc().millisecondsSinceEpoch;
  return db.wageDao.watchWagesForDate(dayStart, dayEnd);
});

class DailyWagesScreen extends ConsumerStatefulWidget {
  const DailyWagesScreen({super.key});

  @override
  ConsumerState<DailyWagesScreen> createState() => _DailyWagesScreenState();
}

class _DailyWagesScreenState extends ConsumerState<DailyWagesScreen> {
  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(_activeWorkersStreamProvider);
    final wagesAsync = ref.watch(_todayWagesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Wages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Manage Workers',
            onPressed: () => context.push('/workers'),
          ),
        ],
      ),
      body: workersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (workers) {
          final wages = wagesAsync.valueOrNull ?? [];
          final totalFromWorkers = workers.fold(0, (s, w) => s + w.dailyWage);
          final paid = wages.where((w) => w.paymentStatus == 'paid').fold(0, (s, w) => s + w.amount);
          final pending = totalFromWorkers - paid;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.primary.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Expanded(child: _summaryItem('Total', CurrencyFormatter.formatPaise(totalFromWorkers))),
                    Expanded(child: _summaryItem('Paid', CurrencyFormatter.formatPaise(paid))),
                    Expanded(child: _summaryItem('Pending', CurrencyFormatter.formatPaise(pending > 0 ? pending : 0))),
                  ],
                ),
              ),
              if (workers.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text('No active workers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Add workers from the Workers screen', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: workers.length,
                    itemBuilder: (context, i) {
                      final w = workers[i];
                      final todayWage = wages.where((wg) => wg.workerId == w.id).firstOrNull;
                      final isPaid = todayWage?.paymentStatus == 'paid';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 20, color: Colors.black),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              CurrencyFormatter.formatPaise(w.dailyWage),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18, color: Colors.black),
                            ),
                            const SizedBox(height: 10),
                            isPaid
                                ? const Text(
                                    'PAID',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _payWage(context, ref, w),
                                      child: const Text('PAY'),
                                    ),
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _payWage(BuildContext context, WidgetRef ref, Worker worker) {
    String method = 'cash';
    bool confirming = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Pay ${worker.name}', maxLines: 1, overflow: TextOverflow.ellipsis),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Amount: ${CurrencyFormatter.formatPaise(worker.dailyWage)}'),
                const SizedBox(height: 12),
                const Text('Payment Method:'),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Cash'),
                        value: 'cash',
                        groupValue: method,
                        onChanged: (v) => setDialogState(() => method = v!),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Bank'),
                        value: 'bank',
                        groupValue: method,
                        onChanged: (v) => setDialogState(() => method = v!),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: confirming ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: confirming ? null : () async {
                setDialogState(() => confirming = true);
                try {
                  final workerRepo = WorkerRepository(ref.read(databaseProvider));
                  await workerRepo.payWage(workerId: worker.id, paymentMethod: method);
                  ref.invalidate(cashBalanceProvider);
                  ref.invalidate(bankBalanceProvider);
                  ref.invalidate(_activeWorkersStreamProvider);
                  ref.invalidate(_todayWagesStreamProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Paid ${worker.name}: ${CurrencyFormatter.formatPaise(worker.dailyWage)}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                    );
                    setDialogState(() => confirming = false);
                  }
                }
              },
              child: const Text('CONFIRM PAY'),
            ),
          ],
        ),
      ),
    );
  }
}
