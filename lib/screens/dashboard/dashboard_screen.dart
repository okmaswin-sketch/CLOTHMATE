import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/theme.dart';
import '../../core/currency.dart';
import '../../repositories/balance_repository.dart';
import '../../repositories/pdf_repository.dart';
import '../../repositories/export_repository.dart';
import '../../data/database.dart';
import '../../providers.dart';

final cashBalanceProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(balanceRepoProvider);
  return repo.getCashBalance();
});

final bankBalanceProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(balanceRepoProvider);
  return repo.getBankBalance();
});

final dashboardSalesProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day).toUtc().millisecondsSinceEpoch;
  final dayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toUtc().millisecondsSinceEpoch;

  final totalSales = await db.salesDao.getTotalSalesForDate(dayStart, dayEnd);
  final itemsSold = await db.salesDao.getTotalItemsSoldForDate(dayStart, dayEnd);
  return {'totalSales': totalSales, 'itemsSold': itemsSold};
});

final dashboardExpensesProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day).toUtc().millisecondsSinceEpoch;
  final dayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toUtc().millisecondsSinceEpoch;

  final maintenance = await db.ledgerDao.getExpensesForDate('maintenance:', dayStart, dayEnd);
  final wages = await db.ledgerDao.getWagesPaidForDate(dayStart, dayEnd);
  final other = await db.ledgerDao.getExpensesForDate('general', dayStart, dayEnd);
  return {'maintenance': maintenance, 'wages': wages, 'other': other};
});

final lowStockProvider = FutureProvider<List<Product>>((ref) async {
  final db = ref.watch(databaseProvider);
  final settings = await db.settingsDao.getSettings();
  return db.productDao.getLowStockProducts(settings.lowStockThreshold);
});

final dashboardProfitProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day).toUtc().millisecondsSinceEpoch;
  final dayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toUtc().millisecondsSinceEpoch;

  final totalSales = await db.salesDao.getTotalSalesForDate(dayStart, dayEnd);

  int cogs = 0;
  final sales = await db.salesDao.getSalesForDate(dayStart, dayEnd);
  for (final sale in sales) {
    final items = await db.salesDao.getSaleItems(sale.id);
    for (final item in items) {
      final product = await db.productDao.getProduct(item.productId);
      if (product != null && product.costPrice != null) {
        cogs += item.quantity * product.costPrice!;
      }
    }
  }

  final maintenance = await db.ledgerDao.getExpensesForDate('maintenance:', dayStart, dayEnd);
  final wages = await db.ledgerDao.getWagesPaidForDate(dayStart, dayEnd);
  final other = await db.ledgerDao.getExpensesForDate('general', dayStart, dayEnd);

  return totalSales - cogs - maintenance - wages - other;
});

final recentTransactionsProvider = StreamProvider<List<LedgerTransaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.ledgerDao.watchRecentTransactions(10);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashAsync = ref.watch(cashBalanceProvider);
    final bankAsync = ref.watch(bankBalanceProvider);
    final salesAsync = ref.watch(dashboardSalesProvider);
    final profitAsync = ref.watch(dashboardProfitProvider);
    final recentTxns = ref.watch(recentTransactionsProvider);
    final lowStock = ref.watch(lowStockProvider);

    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    final dayName = dayNames[now.weekday - 1];
    final dateDisplay = '${now.day} ${monthNames[now.month - 1]} ${now.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClothMate', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'print', child: Text('Print Daily Statement')),
              const PopupMenuItem(value: 'export', child: Text('Export Data')),
              const PopupMenuItem(value: 'backup', child: Text('Backup & Restore')),
              const PopupMenuItem(value: 'reports', child: Text('Reports')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'about', child: Text('About')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(cashBalanceProvider);
            ref.invalidate(bankBalanceProvider);
            ref.invalidate(dashboardSalesProvider);
            ref.invalidate(dashboardProfitProvider);
            ref.invalidate(lowStockProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      dayName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateDisplay,
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 400) {
                    return Row(
                      children: [
                        Expanded(child: _balanceCard(context, 'Cash Balance', cashAsync, AppColors.cash)),
                        const SizedBox(width: 12),
                        Expanded(child: _balanceCard(context, 'Bank Balance', bankAsync, AppColors.bank)),
                      ],
                    );
                  }
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _balanceCard(context, 'Cash Balance', cashAsync, AppColors.cash),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _balanceCard(context, 'Bank Balance', bankAsync, AppColors.bank),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 400) {
                    return Row(
                      children: [
                        Expanded(child: _statCard(context, "Today's Sales",
                            salesAsync.whenData((d) => d['totalSales']!).valueOrNull ?? 0, AppColors.income)),
                        const SizedBox(width: 8),
                        Expanded(child: _statCard(context, "Profit",
                            profitAsync.valueOrNull ?? 0, AppColors.secondary)),
                        const SizedBox(width: 8),
                        Expanded(child: _statCard(context, 'Items',
                            salesAsync.whenData((d) => d['itemsSold']!).valueOrNull ?? 0, AppColors.secondary)),
                      ],
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - 16) / 3,
                        child: _statCard(context, "Sales",
                            salesAsync.whenData((d) => d['totalSales']!).valueOrNull ?? 0, AppColors.income),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 16) / 3,
                        child: _statCard(context, "Profit",
                            profitAsync.valueOrNull ?? 0, AppColors.secondary),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 16) / 3,
                        child: _statCard(context, 'Items',
                            salesAsync.whenData((d) => d['itemsSold']!).valueOrNull ?? 0, AppColors.secondary),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              _sectionTitle('Quick Actions'),
              const SizedBox(height: 8),
              _quickActions(context),
              const SizedBox(height: 20),
              recentTxns.when(
                data: (txns) {
                  if (txns.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Recent Transactions'),
                      const SizedBox(height: 8),
                      Card(
                        color: AppColors.primary,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: txns.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white12),
                          itemBuilder: (context, i) => _recentTransactionTile(txns[i]),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),
              lowStock.when(
                data: (products) {
                  if (products.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Low Stock Alerts'),
                      const SizedBox(height: 8),
                      ...products.take(5).map((p) => Column(
                        children: [
                          _lowStockTile(p),
                          const SizedBox(height: 8),
                        ],
                      )),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceCard(BuildContext context, String label, AsyncValue<int> value, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.when(
                  data: (v) => CurrencyFormatter.formatPaise(v),
                  loading: () => '₹0',
                  error: (_, __) => 'Error',
                ),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, int value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label == 'Items' ? '$value' : CurrencyFormatter.formatPaise(value),
                style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  Widget _quickActions(BuildContext context) {
    final actions = [
      ('Sales', Icons.shopping_cart_rounded, '/sales'),
      ('Garments', Icons.checkroom_rounded, '/garments'),
      ('Workers', Icons.people_rounded, '/daily-wages'),
      ('Maintenance', Icons.build_rounded, '/income-expenses'),
      ('Income', Icons.attach_money_rounded, '/income-expenses'),
      ('Transfer', Icons.swap_horiz_rounded, '/transfers'),
      ('Reports', Icons.bar_chart_rounded, '/reports'),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: actions.map((action) {
        final (label, icon, route) = action;
        return GestureDetector(
          onTap: () => context.push(route),
          child: SizedBox(
            width: 72,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _lowStockTile(Product p) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning_amber, color: AppColors.warning),
        title: Text('SKU: ${p.sku}', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('Stock: ${p.stockQty}'),
        dense: true,
      ),
    );
  }

  Widget _recentTransactionTile(LedgerTransaction txn) {
    IconData icon;
    Color iconColor;
    switch (txn.type) {
      case 'sale':
        icon = Icons.shopping_cart;
        iconColor = AppColors.income;
        break;
      case 'wage':
        icon = Icons.people;
        iconColor = Colors.orange;
        break;
      case 'expense':
        icon = Icons.money_off;
        iconColor = AppColors.expense;
        break;
      case 'income':
        icon = Icons.attach_money;
        iconColor = AppColors.income;
        break;
      case 'transfer_in':
        icon = Icons.arrow_downward;
        iconColor = AppColors.bank;
        break;
      case 'transfer_out':
        icon = Icons.arrow_upward;
        iconColor = AppColors.cash;
        break;
      default:
        icon = Icons.account_balance;
        iconColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.15),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        txn.description ?? txn.transactionId,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatTimestamp(txn.occurredAt),
        style: const TextStyle(color: Colors.white54, fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${txn.amount >= 0 ? '+' : ''}${CurrencyFormatter.formatPaise(txn.amount)}',
        style: TextStyle(
          color: txn.amount >= 0 ? AppColors.income : AppColors.expense,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      dense: true,
    );
  }

  String _formatTimestamp(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${dt.day.toString().padLeft(2, '0')} ${_monthName(dt.month)} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String value) async {
    final db = ref.read(databaseProvider);
    switch (value) {
      case 'print':
        _printDailyStatement(context, db);
        break;
      case 'export':
        _exportData(context, db);
        break;
      case 'backup':
        context.push('/backup');
        break;
      case 'reports':
        context.push('/reports');
        break;
      case 'settings':
        context.push('/settings');
        break;
      case 'about':
        _showAboutDialog(context);
        break;
    }
  }

  void _printDailyStatement(BuildContext context, AppDatabase db) async {
    try {
      final pdfRepo = PdfRepository(db);
      final doc = await pdfRepo.generateDailyStatement(DateTime.now());
      final bytes = await doc.save();
      final dateStr = DateFormatter.dateKey(DateTime.now());
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/clothmate_daily_$dateStr.pdf');
      await file.writeAsBytes(bytes);
      if (context.mounted) {
        await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e', maxLines: 2, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _exportData(BuildContext context, AppDatabase db) async {
    try {
      final exportRepo = ExportRepository(db);
      await exportRepo.exportAndShare();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e', maxLines: 2, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'ClothMate',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.checkroom, color: AppColors.primary, size: 40),
      children: const [
        Text('Garment Business Management App'),
        SizedBox(height: 8),
        Text('Manage sales, inventory, workers, wages, income, expenses, and transfers.'),
      ],
    );
  }
}
