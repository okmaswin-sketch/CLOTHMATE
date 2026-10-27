import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../core/currency.dart';
import '../../data/database.dart';
import '../../providers.dart';

final salesListProvider = FutureProvider<List<Sale>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.salesDao.getAllSales();
});

final _saleItemsProvider = FutureProvider.family<List<SaleItem>, int>((ref, saleId) async {
  final db = ref.watch(databaseProvider);
  return db.salesDao.getSaleItems(saleId);
});

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/create-sale'),
        child: const Icon(Icons.add),
      ),
      body: salesAsync.when(
        data: (sales) {
          if (sales.isEmpty) {
            return const Center(child: Text('No sales yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, i) {
              final sale = sales[i];
              final dt = DateTime.fromMillisecondsSinceEpoch(sale.saleDate);
              final paymentLabel = AppConstants.paymentMethodLabels[sale.paymentMethod] ?? sale.paymentMethod;
              final isReturned = sale.status == 'returned';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => _showSaleDetail(context, ref, sale),
                  leading: CircleAvatar(
                    backgroundColor: (isReturned ? AppColors.expense : AppColors.income).withOpacity(0.1),
                    child: Icon(
                      isReturned ? Icons.replay : Icons.shopping_cart,
                      color: isReturned ? AppColors.expense : AppColors.income,
                      size: 20,
                    ),
                  ),
                  title: Text(sale.transactionId, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.dateTime(dt),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              paymentLabel,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(child: _statusBadge(sale.status)),
                        ],
                      ),
                    ],
                  ),
                  trailing: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.formatPaise(sale.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.income),
                        ),
                        if (sale.discount > 0)
                          Text(
                            '-${CurrencyFormatter.formatPaise(sale.discount)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.expense),
                          ),
                      ],
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
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

  Widget _statusBadge(String status) {
    final isReturned = status == 'returned';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isReturned ? AppColors.expense : AppColors.income).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isReturned ? 'Returned' : 'Completed',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isReturned ? AppColors.expense : AppColors.income,
        ),
      ),
    );
  }

  void _showSaleDetail(BuildContext context, WidgetRef ref, Sale sale) {
    final dt = DateTime.fromMillisecondsSinceEpoch(sale.saleDate);
    final paymentLabel = AppConstants.paymentMethodLabels[sale.paymentMethod] ?? sale.paymentMethod;
    final itemsAsync = ref.read(_saleItemsProvider(sale.id));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sale.transactionId,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  Flexible(child: _statusBadge(sale.status)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _detailRow('Date & Time', DateFormatter.dateTime(dt)),
                  const SizedBox(height: 8),
                  _detailRow('Payment', paymentLabel),
                  const SizedBox(height: 8),
                  _detailRow('Status', sale.status[0].toUpperCase() + sale.status.substring(1)),
                  if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _detailRow('Notes', sale.notes!),
                  ],
                  const Divider(height: 24),
                  const Text('Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  itemsAsync.when(
                    data: (items) {
                      if (items.isEmpty) return const Text('No items found');
                      return _SaleItemsList(items: items);
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const Divider(height: 24),
                  _summaryRow('Subtotal', CurrencyFormatter.formatPaise(sale.subtotal)),
                  if (sale.discount > 0) ...[
                    const SizedBox(height: 6),
                    _summaryRow('Discount', '-${CurrencyFormatter.formatPaise(sale.discount)}'),
                  ],
                  if (sale.taxAmount > 0) ...[
                    const SizedBox(height: 6),
                    _summaryRow('Tax', CurrencyFormatter.formatPaise(sale.taxAmount)),
                  ],
                  const SizedBox(height: 8),
                  _summaryRow(
                    'Total',
                    CurrencyFormatter.formatPaise(sale.totalAmount),
                    isBold: true,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.primary : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppColors.income : AppColors.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _SaleItemsList extends StatelessWidget {
  final List<SaleItem> items;
  const _SaleItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final item = items[i];
        return _SaleItemTile(item: item);
      },
    );
  }
}

class _SaleItemTile extends ConsumerWidget {
  final SaleItem item;
  const _SaleItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    return FutureBuilder<Product?>(
      future: db.productDao.getProduct(item.productId),
      builder: (ctx, snap) {
        final sku = snap.data?.sku ?? 'SKU #${item.productId}';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sku,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatter.formatPaise(item.unitPrice)} × ${item.quantity}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    CurrencyFormatter.formatPaise(item.lineTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.income),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
