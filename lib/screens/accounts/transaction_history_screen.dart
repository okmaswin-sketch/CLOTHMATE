import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/currency.dart';
import '../../data/database.dart';
import '../../providers.dart';

final transactionTypeFilterProvider = StateProvider<List<String>>((ref) => []);
final transactionAccountFilterProvider = StateProvider<String>((ref) => 'all');
final transactionDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final filteredLedgerProvider = FutureProvider<List<LedgerTransaction>>((ref) async {
  final db = ref.watch(databaseProvider);
  final types = ref.watch(transactionTypeFilterProvider);
  final account = ref.watch(transactionAccountFilterProvider);
  final dateRange = ref.watch(transactionDateRangeProvider);

  int? start, end;
  if (dateRange != null) {
    start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day).toUtc().millisecondsSinceEpoch;
    end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59, 999).toUtc().millisecondsSinceEpoch;
  }

  final effectiveTypes = types.isEmpty ? null : types;
  return db.ledgerDao.getFilteredLedger(
    start: start,
    end: end,
    types: effectiveTypes,
    account: account,
  );
});

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  static const _typeChipLabels = <String, String>{
    'Sale': 'sale',
    'Wage': 'wage',
    'Expense': 'expense',
    'Income': 'income',
    'Transfer': 'transfer',
    'Opening Balance': 'opening_balance',
  };

  static const _dbTypesForChip = <String, List<String>>{
    'sale': ['sale'],
    'wage': ['wage'],
    'expense': ['expense'],
    'income': ['income'],
    'transfer': ['transfer_in', 'transfer_out'],
    'opening_balance': ['opening_balance'],
  };

  String _formatDate(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final day = dt.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$day ${months[dt.month - 1]} $time';
  }

  String _formatRangeDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '$day ${months[dt.month - 1]}';
  }

  void _toggleType(String dbValue) {
    final dbValues = _dbTypesForChip[dbValue]!;
    final current = ref.read(transactionTypeFilterProvider);
    final isActive = current.contains(dbValues.first);
    List<String> updated;
    if (isActive) {
      updated = current.where((v) => !dbValues.contains(v)).toList();
    } else {
      updated = [...current, ...dbValues];
    }
    ref.read(transactionTypeFilterProvider.notifier).state = updated;
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'sale':
        return Icons.shopping_cart;
      case 'wage':
        return Icons.people;
      case 'expense':
        return Icons.money_off;
      case 'income':
        return Icons.attach_money;
      case 'transfer_in':
        return Icons.arrow_downward;
      case 'transfer_out':
        return Icons.arrow_upward;
      case 'opening_balance':
        return Icons.account_balance;
      default:
        return Icons.receipt_long;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'sale':
        return Colors.green;
      case 'wage':
        return Colors.orange;
      case 'expense':
        return Colors.red;
      case 'income':
        return Colors.green;
      case 'transfer_in':
      case 'transfer_out':
        return Colors.blue;
      case 'opening_balance':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _typeDisplayName(String dbType) {
    switch (dbType) {
      case 'sale':
        return 'Sale';
      case 'wage':
        return 'Wage';
      case 'expense':
        return 'Expense';
      case 'income':
        return 'Income';
      case 'transfer_in':
        return 'Transfer In';
      case 'transfer_out':
        return 'Transfer Out';
      case 'opening_balance':
        return 'Opening Balance';
      default:
        return dbType;
    }
  }

  void _showDetailSheet(LedgerTransaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final amountColor = tx.amount >= 0 ? Colors.green : Colors.red;
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.formatPaise(tx.amount),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _detailRow('Type', _typeDisplayName(tx.type)),
                const SizedBox(height: 12),
                _detailRow('Account', tx.account.toUpperCase()),
                const SizedBox(height: 12),
                _detailRow('Transaction ID', '#${tx.transactionId}'),
                const SizedBox(height: 12),
                if (tx.description != null && tx.description!.isNotEmpty)
                  _detailRow('Description', tx.description!),
                if (tx.description != null && tx.description!.isNotEmpty)
                  const SizedBox(height: 12),
                if (tx.referenceTable != null && tx.referenceTable!.isNotEmpty)
                  _detailRow('Reference', '${tx.referenceTable} #${tx.referenceId ?? '-'}'),
                if (tx.referenceTable != null && tx.referenceTable!.isNotEmpty)
                  const SizedBox(height: 12),
                _detailRow('Occurred At', _formatDate(tx.occurredAt)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ledgerAsync = ref.watch(filteredLedgerProvider);
    final selectedTypes = ref.watch(transactionTypeFilterProvider);
    final selectedAccount = ref.watch(transactionAccountFilterProvider);
    final dateRange = ref.watch(transactionDateRangeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: Column(
        children: [
          Container(
            color: cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account filter
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final labels = ['All', 'Cash', 'Bank'];
                        final values = ['all', 'cash', 'bank'];
                        final isSelected = selectedAccount == values[index];
                        return FilterChip(
                          label: Text(labels[index]),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(transactionAccountFilterProvider.notifier).state = values[index];
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Type filter
                  Wrap(
                    spacing: 6,
                    runSpacing: 0,
                    children: _typeChipLabels.entries.map((entry) {
                      final isActive = selectedTypes.contains(entry.value);
                      return FilterChip(
                        label: Text(entry.key, style: const TextStyle(fontSize: 12)),
                        selected: isActive,
                        onSelected: (_) => _toggleType(entry.value),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  // Date range
                  Row(
                    children: [
                      Flexible(
                        child: TextButton.icon(
                          icon: const Icon(Icons.date_range, size: 18),
                          label: Text(
                            dateRange != null
                                ? '${_formatRangeDate(dateRange.start)} - ${_formatRangeDate(dateRange.end)}'
                                : 'Select Date Range',
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: now,
                              initialDateRange: dateRange,
                            );
                            if (picked != null) {
                              ref.read(transactionDateRangeProvider.notifier).state = picked;
                            }
                          },
                        ),
                      ),
                      if (dateRange != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            ref.read(transactionDateRangeProvider.notifier).state = null;
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ledgerAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (ledger) {
                if (ledger.isEmpty) {
                  return const Center(child: Text('No transactions found'));
                }
                return ListView.builder(
                  itemCount: ledger.length,
                  itemBuilder: (context, index) {
                    final tx = ledger[index];
                    final amountColor = tx.amount >= 0 ? Colors.green : Colors.red;
                    final title = (tx.description != null && tx.description!.isNotEmpty)
                        ? tx.description!
                        : 'TX #${tx.transactionId}';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _colorForType(tx.type).withOpacity(0.12),
                        child: Icon(_iconForType(tx.type), color: _colorForType(tx.type), size: 20),
                      ),
                      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(_formatDate(tx.occurredAt), style: const TextStyle(fontSize: 12)),
                      trailing: Text(
                        CurrencyFormatter.formatPaise(tx.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: amountColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _showDetailSheet(tx),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
