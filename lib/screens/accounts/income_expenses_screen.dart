import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../providers.dart';
import '../../core/currency.dart';
import '../../data/database.dart';
import '../../repositories/report_repository.dart';

class IncomeExpensesScreen extends ConsumerStatefulWidget {
  const IncomeExpensesScreen({super.key});

  @override
  ConsumerState<IncomeExpensesScreen> createState() => _IncomeExpensesScreenState();
}

class _IncomeExpensesScreenState extends ConsumerState<IncomeExpensesScreen> {
  bool _showIncome = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Income & Expenses')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Income')),
              ButtonSegment(value: false, label: Text('Expenses')),
            ],
            selected: {_showIncome},
            onSelectionChanged: (v) => setState(() => _showIncome = v.first),
          ),
          Expanded(
            child: _showIncome ? _incomeList() : _expenseList(),
          ),
        ],
      ),
    );
  }

  Widget _incomeList() {
    final now = DateTime.now();
    final dayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toUtc().millisecondsSinceEpoch;
    final db = ref.read(databaseProvider);

    return FutureBuilder<List<IncomeData>>(
      future: db.incomeDao.getIncomeForDate(0, dayEnd),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        if (items.isEmpty) return const Center(child: Text('No income recorded'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final inc = items[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.attach_money, color: AppColors.income),
                title: Text(inc.source, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${inc.description ?? ""} · ${AppConstants.paymentMethodLabels[inc.paymentType]}', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(CurrencyFormatter.formatPaise(inc.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.income),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            );
          },
        );
      },
    );
  }

  Widget _expenseList() {
    final db = ref.read(databaseProvider);

    return FutureBuilder<List<Expense>>(
      future: db.expenseDao.getExpensesForDate(0, DateTime.now().toUtc().millisecondsSinceEpoch),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        if (items.isEmpty) return const Center(child: Text('No expenses recorded'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final exp = items[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.money_off, color: AppColors.expense),
                title: Text(AppConstants.expenseCategoryLabels[exp.category] ?? exp.category, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${exp.description ?? ""} · ${AppConstants.paymentMethodLabels[exp.paymentType]}', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(CurrencyFormatter.formatPaise(exp.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.expense),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    if (_showIncome) {
      _showAddIncomeDialog(context);
    } else {
      _showAddExpenseDialog(context);
    }
  }

  void _showAddIncomeDialog(BuildContext context) {
    final sourceCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String paymentType = 'cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Income'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: sourceCtrl, decoration: const InputDecoration(labelText: 'Source', isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)', isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', isDense: true)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Cash'),
                        value: 'cash',
                        groupValue: paymentType,
                        onChanged: (v) => setDialogState(() => paymentType = v!),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Bank'),
                        value: 'bank',
                        groupValue: paymentType,
                        onChanged: (v) => setDialogState(() => paymentType = v!),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (sourceCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                  final amount = (double.parse(amountCtrl.text) * 100).round();
                  await IncomeRepository(ref.read(databaseProvider)).addIncome(
                    source: sourceCtrl.text.trim(),
                    amount: amount,
                    paymentType: paymentType,
                    description: descCtrl.text.isEmpty ? null : descCtrl.text,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {});
                }
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'general';
    String paymentType = 'cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Expense'),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: category,
                    isDense: true,
                    decoration: const InputDecoration(labelText: 'Category', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: AppConstants.expenseCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(AppConstants.expenseCategoryLabels[c] ?? c, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => category = v!),
                  ),
                  const SizedBox(height: 4),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
                  const SizedBox(height: 4),
                  TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
                  const SizedBox(height: 4),
                  TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Cash'),
                          value: 'cash',
                          groupValue: paymentType,
                          onChanged: (v) => setDialogState(() => paymentType = v!),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Bank'),
                          value: 'bank',
                          groupValue: paymentType,
                          onChanged: (v) => setDialogState(() => paymentType = v!),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (amountCtrl.text.isNotEmpty) {
                  final amount = (double.parse(amountCtrl.text) * 100).round();
                  await ExpenseRepository(ref.read(databaseProvider)).addExpense(
                    category: category,
                    amount: amount,
                    paymentType: paymentType,
                    description: descCtrl.text.isEmpty ? null : descCtrl.text,
                    notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {});
                }
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }
}
