import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import '../../app/theme.dart';
import '../../core/currency.dart';
import '../../data/database.dart';
import '../../providers.dart';
import '../../repositories/worker_repository.dart';
import '../dashboard/dashboard_screen.dart';

final workersProvider = StreamProvider<List<Worker>>((ref) {
  return ref.watch(databaseProvider).workerDao.watchAllWorkers();
});

final _todayWagesProvider = StreamProvider<List<Wage>>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day).toUtc().millisecondsSinceEpoch;
  final dayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toUtc().millisecondsSinceEpoch;
  return db.wageDao.watchWagesForDate(dayStart, dayEnd);
});

class WorkersScreen extends ConsumerStatefulWidget {
  const WorkersScreen({super.key});

  @override
  ConsumerState<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends ConsumerState<WorkersScreen> {
  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workersProvider);
    final wagesAsync = ref.watch(_todayWagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.payments),
            tooltip: 'Daily Wages',
            onPressed: () => context.push('/daily-wages'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddWorkerDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: workersAsync.when(
        data: (workers) {
          if (workers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text('No workers yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Tap + to add a worker', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          }

          final wages = wagesAsync.valueOrNull ?? [];
          final paidWorkerIds = wages
              .where((w) => w.paymentStatus == 'paid')
              .map((w) => w.workerId)
              .toSet();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(workersProvider);
              ref.invalidate(_todayWagesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: workers.length,
              itemBuilder: (context, i) {
                final w = workers[i];
                final isPaidToday = paidWorkerIds.contains(w.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPaidToday
                          ? Colors.green.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      child: isPaidToday
                          ? const Icon(Icons.check, color: Colors.green, size: 20)
                          : Text(w.name.isNotEmpty ? w.name[0] : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Row(
                      children: [
                        Flexible(
                          child: Text(CurrencyFormatter.formatPaise(w.dailyWage),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (w.status == 'active' ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(w.status, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                              fontSize: 11,
                              color: w.status == 'active' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            )),
                          ),
                        ),
                      ],
                    ),
                    trailing: w.status != 'active'
                        ? const Icon(Icons.block, color: Colors.red, size: 20)
                        : isPaidToday
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('PAID', style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                )),
                              )
                            : ElevatedButton(
                                onPressed: () => _confirmPay(context, ref, w),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.income,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                child: const Text('PAY', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e', textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
        )),
      ),
    );
  }

  void _confirmPay(BuildContext context, WidgetRef ref, Worker worker) {
    String method = 'cash';
    bool confirming = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Pay ${worker.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Amount Due', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(CurrencyFormatter.formatPaise(worker.dailyWage),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Pay from:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => method = 'cash'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: method == 'cash' ? AppColors.cash : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: method == 'cash' ? AppColors.cash : AppColors.divider),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payments, size: 18, color: method == 'cash' ? Colors.white : AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text('Cash', style: TextStyle(
                                color: method == 'cash' ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => method = 'bank'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: method == 'bank' ? AppColors.bank : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: method == 'bank' ? AppColors.bank : AppColors.divider),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance, size: 18, color: method == 'bank' ? Colors.white : AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text('Bank', style: TextStyle(
                                color: method == 'bank' ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: confirming ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: confirming ? null : () async {
                setDialogState(() => confirming = true);
                try {
                  final workerRepo = WorkerRepository(ref.read(databaseProvider));
                  await workerRepo.payWage(
                    workerId: worker.id,
                    paymentMethod: method,
                  );
                  ref.invalidate(cashBalanceProvider);
                  ref.invalidate(bankBalanceProvider);
                  ref.invalidate(workersProvider);
                  ref.invalidate(_todayWagesProvider);
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.income,
                foregroundColor: Colors.white,
              ),
              child: confirming
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('CONFIRM PAY'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWorkerDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final wageCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Worker'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: wageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Daily Wage (₹)', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', isDense: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && wageCtrl.text.isNotEmpty) {
                final db = ref.read(databaseProvider);
                final wagePaise = (double.parse(wageCtrl.text) * 100).round();
                await db.workerDao.insertWorker(WorkersCompanion.insert(
                  name: nameCtrl.text.trim(),
                  dailyWage: wagePaise,
                  notes: Value(notesCtrl.text.isEmpty ? null : notesCtrl.text),
                  createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
                ));
                ref.invalidate(workersProvider);
                ref.invalidate(_todayWagesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }
}
