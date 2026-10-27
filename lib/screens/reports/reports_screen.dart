import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/theme.dart';
import '../../core/currency.dart';
import '../../data/database.dart';
import '../../providers.dart';
import '../../repositories/pdf_repository.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedTab = 0;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePdf(context),
          ),
        ],
      ),
      body: Column(
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Daily')),
              ButtonSegment(value: 1, label: Text('Weekly')),
              ButtonSegment(value: 2, label: Text('Monthly')),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (v) => setState(() => _selectedTab = v.first),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    if (_selectedTab == 0) {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    } else if (_selectedTab == 1) {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                    } else {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                    }
                  }),
                ),
                Expanded(
                  child: Text(
                    _dateLabel(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    if (_selectedTab == 0) {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    } else if (_selectedTab == 1) {
                      _selectedDate = _selectedDate.add(const Duration(days: 7));
                    } else {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                    }
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _dailyReport()
                : _selectedTab == 1
                    ? _weeklyReport()
                    : _monthlyReport(),
          ),
        ],
      ),
    );
  }

  String _dateLabel() {
    if (_selectedTab == 0) return DateFormatter.fullDate(_selectedDate);
    if (_selectedTab == 1) {
      final start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return '${DateFormatter.shortDate(start)} - ${DateFormatter.shortDate(end)}';
    }
    return '${_selectedDate.month}/${_selectedDate.year}';
  }

  Widget _dateDisplay() {
    final dayName = DateFormat('EEEE').format(_selectedDate);
    final dateStr = DateFormat('d MMMM yyyy').format(_selectedDate);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text(
            dayName,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dateStr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyReport() {
    final db = ref.read(databaseProvider);
    final dayStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).toUtc().millisecondsSinceEpoch;
    final dayEnd = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59, 999).toUtc().millisecondsSinceEpoch;
    final dateStr = DateFormatter.dateKey(_selectedDate);

    return FutureBuilder<Map<String, dynamic>>(
      future: _getDailyData(db, dayStart, dayEnd, dateStr),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _dateDisplay(),
            _reportSection('SALES', [
              for (final entry in (data['salesByType'] as Map<String, int>).entries)
                _reportLine(entry.key, CurrencyFormatter.formatPaise(entry.value)),
              _reportLine('Total Sales', CurrencyFormatter.formatPaise(data['totalSales']!), bold: true),
            ]),
            _reportSection('PAYMENT COLLECTION', [
              _reportLine('Cash', CurrencyFormatter.formatPaise(data['cashSales']!)),
              _reportLine('Bank/UPI', CurrencyFormatter.formatPaise(data['bankSales']!)),
            ]),
            _reportSection('OTHER INCOME', [
              _reportLine('Cash Income', CurrencyFormatter.formatPaise(data['cashIncome']!)),
              _reportLine('Bank Income', CurrencyFormatter.formatPaise(data['bankIncome']!)),
            ]),
            _reportSection('EXPENSES', [
              _reportLine('Maintenance', CurrencyFormatter.formatPaise(data['maintenance']!)),
              _reportLine('Workers Wages', CurrencyFormatter.formatPaise(data['wages']!)),
              _reportLine('Other Expenses', CurrencyFormatter.formatPaise(data['otherExpenses']!)),
            ]),
            if (data['transfers'] != null && (data['transfers'] as List).isNotEmpty)
              _reportSection('TRANSFERS', [
                for (final t in data['transfers'] as List<Transfer>)
                  _reportLine('${t.fromAccount} → ${t.toAccount}', CurrencyFormatter.formatPaise(t.amount)),
              ]),
            _reportSection('CASH SUMMARY', [
              _reportLine('Opening', CurrencyFormatter.formatPaise(data['openingCash']!)),
              _reportLine('Closing', CurrencyFormatter.formatPaise(data['closingCash']!), bold: true),
            ]),
            _reportSection('BANK SUMMARY', [
              _reportLine('Opening', CurrencyFormatter.formatPaise(data['openingBank']!)),
              _reportLine('Closing', CurrencyFormatter.formatPaise(data['closingBank']!), bold: true),
            ]),
            const SizedBox(height: 16),
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('NET PROFIT / LOSS', style: TextStyle(color: Colors.white70)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormatter.formatPaise(data['netProfit']!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _confirmDeleteDay(context, dateStr),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Delete This Day\'s Records', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getDailyData(
      AppDatabase db, int dayStart, int dayEnd, String dateStr) async {
    final sales = await db.salesDao.getSalesForDate(dayStart, dayEnd);
    int totalSales = 0, cashSales = 0, bankSales = 0;
    Map<String, int> salesByType = {};
    for (final sale in sales) {
      totalSales += sale.totalAmount;
      if (sale.paymentMethod == 'cash') {
        cashSales += sale.totalAmount;
      } else {
        bankSales += sale.totalAmount;
      }
      final items = await db.salesDao.getSaleItems(sale.id);
      for (final item in items) {
        final product = await db.productDao.getProduct(item.productId);
        String typeName = 'Other';
        if (product != null) {
          final gt = await db.garmentDao.getGarmentType(product.garmentTypeId);
          typeName = gt?.name ?? 'Type ${product.garmentTypeId}';
        }
        salesByType[typeName] = (salesByType[typeName] ?? 0) + item.lineTotal;
      }
    }

    final expenses = await db.expenseDao.getExpensesForDate(dayStart, dayEnd);
    int maintenance = 0, otherExpenses = 0;
    for (final e in expenses) {
      if (e.category.startsWith('maintenance:')) {
        maintenance += e.amount;
      } else {
        otherExpenses += e.amount;
      }
    }

    final wages = await db.wageDao.getWagesForDate(dayStart, dayEnd);
    int totalWages = 0;
    for (final w in wages) {
      if (w.paymentStatus == 'paid') totalWages += w.amount;
    }

    final cashIncome = await db.ledgerDao.getIncomeForDate('cash', dayStart, dayEnd);
    final bankIncome = await db.ledgerDao.getIncomeForDate('bank', dayStart, dayEnd);

    final opening = await db.ledgerDao.getOpeningBalance(dateStr);
    final openingCash = opening?.openingCash ?? 0;
    final openingBank = opening?.openingBank ?? 0;

    final bankToCash = await db.ledgerDao.getTransfersForDate('bank', 'cash', dayStart, dayEnd);
    final cashToBank = await db.ledgerDao.getTransfersForDate('cash', 'bank', dayStart, dayEnd);

    final closingCash = openingCash + cashSales + cashIncome + bankToCash - maintenance - totalWages - otherExpenses - cashToBank;
    final closingBank = openingBank + bankSales + bankIncome + cashToBank - bankToCash;
    final netProfit = totalSales - maintenance - totalWages - otherExpenses;

    final transfers = await db.transferDao.getAllTransfers();
    final dayTransfers = transfers.where((t) =>
        t.occurredAt >= dayStart && t.occurredAt <= dayEnd).toList();

    return {
      'totalSales': totalSales,
      'cashSales': cashSales,
      'bankSales': bankSales,
      'salesByType': salesByType,
      'cashIncome': cashIncome,
      'bankIncome': bankIncome,
      'maintenance': maintenance,
      'wages': totalWages,
      'otherExpenses': otherExpenses,
      'openingCash': openingCash,
      'openingBank': openingBank,
      'closingCash': closingCash,
      'closingBank': closingBank,
      'netProfit': netProfit,
      'transfers': dayTransfers,
    };
  }

  void _confirmDeleteDay(BuildContext context, String dateStr) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Day\'s Records?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This will permanently delete all transactions recorded on this date. This action cannot be undone.'),
              const SizedBox(height: 12),
              const Text('Type DELETE to confirm:'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(isDense: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (controller.text == 'DELETE') {
                await _deleteDayData(dateStr);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                setState(() {});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Records deleted'), backgroundColor: Colors.orange),
                  );
                }
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDayData(String dateStr) async {
    final db = ref.read(databaseProvider);
    final day = DateTime.parse(dateStr);
    final dayStart = DateTime(day.year, day.month, day.day).toUtc().millisecondsSinceEpoch;
    final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59, 999).toUtc().millisecondsSinceEpoch;

    await db.customStatement('DELETE FROM sale_items WHERE sale_id IN (SELECT id FROM sales WHERE sale_date >= ? AND sale_date <= ?)', [dayStart, dayEnd]);
    await db.customStatement('DELETE FROM sales WHERE sale_date >= ? AND sale_date <= ?', [dayStart, dayEnd]);
    await db.customStatement('DELETE FROM expenses WHERE occurred_at >= ? AND occurred_at <= ?', [dayStart, dayEnd]);
    await db.customStatement('DELETE FROM income WHERE occurred_at >= ? AND occurred_at <= ?', [dayStart, dayEnd]);
    await db.customStatement('DELETE FROM wages WHERE wage_date >= ? AND wage_date <= ?', [dayStart, dayEnd]);
    await db.customStatement('DELETE FROM transfers WHERE occurred_at >= ? AND occurred_at <= ?', [dayStart, dayEnd]);
    await db.customStatement('DELETE FROM ledger_transactions WHERE occurred_at >= ? AND occurred_at <= ?', [dayStart, dayEnd]);
    await db.customStatement('DELETE FROM daily_opening_balances WHERE balance_date = ?', [dateStr]);
  }

  // --- Helper: data fetching ---

  Future<Map<String, int>> _getWeeklyData() async {
    final db = ref.read(databaseProvider);
    final now = _selectedDate;
    final monday = now.subtract(Duration(days: now.weekday - 1));

    Map<String, int> dailySales = {};
    int totalSales = 0, totalWages = 0, totalExpenses = 0, cashSales = 0, bankSales = 0;

    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day).toUtc().millisecondsSinceEpoch;
      final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59, 999).toUtc().millisecondsSinceEpoch;

      final sales = await db.salesDao.getTotalSalesForDate(dayStart, dayEnd);
      dailySales[_dayName(day.weekday)] = sales;
      totalSales += sales;

      cashSales += await db.salesDao.getCashSalesForDate(dayStart, dayEnd);
      bankSales += await db.salesDao.getBankSalesForDate(dayStart, dayEnd);

      final wages = await db.ledgerDao.getWagesPaidForDate(dayStart, dayEnd);
      totalWages += wages;

      final maintenance = await db.ledgerDao.getExpensesForDate('maintenance:', dayStart, dayEnd);
      final other = await db.ledgerDao.getExpensesForDate('general', dayStart, dayEnd);
      totalExpenses += maintenance + other;
    }

    return {
      'totalSales': totalSales,
      'totalWages': totalWages,
      'totalExpenses': totalExpenses,
      'cashSales': cashSales,
      'bankSales': bankSales,
      'netProfit': totalSales - totalWages - totalExpenses,
      ...dailySales.map((k, v) => MapEntry('day_$k', v)),
    };
  }

  Future<Map<String, int>> _getMonthlyData() async {
    final db = ref.read(databaseProvider);
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final monthStart = firstDay.toUtc().millisecondsSinceEpoch;
    final monthEnd = DateTime(year, month, lastDay.day, 23, 59, 59, 999).toUtc().millisecondsSinceEpoch;

    final totalSales = await db.salesDao.getTotalSalesForDate(monthStart, monthEnd);
    final totalWages = await db.ledgerDao.getWagesPaidForDate(monthStart, monthEnd);
    final maintenance = await db.ledgerDao.getExpensesForDate('maintenance:', monthStart, monthEnd);
    final other = await db.ledgerDao.getExpensesForDate('general', monthStart, monthEnd);
    final totalExpenses = maintenance + other;

    Map<int, int> dailySales = {};
    for (int d = 1; d <= lastDay.day; d++) {
      final day = DateTime(year, month, d);
      final dayStart = DateTime(day.year, day.month, day.day).toUtc().millisecondsSinceEpoch;
      final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59, 999).toUtc().millisecondsSinceEpoch;
      dailySales[d] = await db.salesDao.getTotalSalesForDate(dayStart, dayEnd);
    }

    return {
      'totalSales': totalSales,
      'totalWages': totalWages,
      'totalExpenses': totalExpenses,
      'netProfit': totalSales - totalWages - totalExpenses,
      ...dailySales.map((k, v) => MapEntry('day$k', v)),
    };
  }

  String _dayName(int weekday) {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday];
  }

  // --- Weekly report ---

  Widget _weeklyReport() {
    return FutureBuilder<Map<String, int>>(
      future: _getWeeklyData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }
        final data = snapshot.data!;

        final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final dayValues = dayLabels
            .map((d) => (data['day_$d'] ?? 0).toDouble())
            .toList();
        final maxVal = dayValues.reduce((a, b) => a > b ? a : b);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DAILY SALES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (maxVal == 0)
                      const SizedBox(
                        height: 180,
                        child: Center(
                          child: Text(
                            'No sales data for this week',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxVal * 1.2,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => AppColors.primary,
                                getTooltipItem: (group, groupIdx, rod, rodIdx) {
                                  return BarTooltipItem(
                                    CurrencyFormatter.formatCompact(rod.toY.toInt()),
                                    const TextStyle(color: Colors.white, fontSize: 12),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx >= 0 && idx < dayLabels.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          dayLabels[idx],
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                  reservedSize: 28,
                                ),
                              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      CurrencyFormatter.formatCompact(value.toInt()),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: AppColors.divider,
                                strokeWidth: 0.5,
                              ),
                            ),
                            barGroups: List.generate(7, (i) {
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: dayValues[i],
                                    color: AppColors.primary,
                                    width: 20,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _summaryCard('Total Sales', CurrencyFormatter.formatPaise(data['totalSales']!), AppColors.income),
            _summaryCard('Cash Sales', CurrencyFormatter.formatPaise(data['cashSales']!), AppColors.cash),
            _summaryCard('Bank Sales', CurrencyFormatter.formatPaise(data['bankSales']!), AppColors.bank),
            _summaryCard('Total Wages', CurrencyFormatter.formatPaise(data['totalWages']!), AppColors.expense),
            _summaryCard('Total Expenses', CurrencyFormatter.formatPaise(data['totalExpenses']!), AppColors.expense),
            const SizedBox(height: 8),
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('NET PROFIT / LOSS', style: TextStyle(color: Colors.white70)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormatter.formatPaise(data['netProfit']!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Monthly report ---

  Widget _monthlyReport() {
    return FutureBuilder<Map<String, int>>(
      future: _getMonthlyData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }
        final data = snapshot.data!;

        final year = _selectedDate.year;
        final month = _selectedDate.month;
        final lastDay = DateTime(year, month + 1, 0).day;

        final dayValues = <double>[];
        final dayXLabels = <int>[];
        for (int d = 1; d <= lastDay; d++) {
          dayValues.add((data['day$d'] ?? 0).toDouble());
          dayXLabels.add(d);
        }
        final maxVal = dayValues.isNotEmpty
            ? dayValues.reduce((a, b) => a > b ? a : b)
            : 0.0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DAILY SALES TREND',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (maxVal == 0)
                      const SizedBox(
                        height: 180,
                        child: Center(
                          child: Text(
                            'No sales data for this month',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: maxVal * 1.2,
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => AppColors.primary,
                                getTooltipItems: (spots) {
                                  return spots.map((s) {
                                    return LineTooltipItem(
                                      '${s.x.toInt()} - ${CurrencyFormatter.formatCompact(s.y.toInt())}',
                                      const TextStyle(color: Colors.white, fontSize: 12),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: lastDay > 15 ? 5 : (lastDay > 7 ? 2 : 1),
                                  getTitlesWidget: (value, meta) {
                                    final day = value.toInt();
                                    if (day >= 1 && day <= lastDay) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          '$day',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                  reservedSize: 24,
                                ),
                              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      CurrencyFormatter.formatCompact(value.toInt()),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: AppColors.divider,
                                strokeWidth: 0.5,
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(lastDay, (i) {
                                  return FlSpot((i + 1).toDouble(), dayValues[i]);
                                }),
                                isCurved: true,
                                color: AppColors.primary,
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 3,
                                      color: AppColors.primary,
                                      strokeColor: Colors.white,
                                      strokeWidth: 1.5,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.primary.withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _summaryCard('Total Sales', CurrencyFormatter.formatPaise(data['totalSales']!), AppColors.income),
            _summaryCard('Total Wages', CurrencyFormatter.formatPaise(data['totalWages']!), AppColors.expense),
            _summaryCard('Total Expenses', CurrencyFormatter.formatPaise(data['totalExpenses']!), AppColors.expense),
            const SizedBox(height: 8),
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('NET PROFIT / LOSS', style: TextStyle(color: Colors.white70)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormatter.formatPaise(data['netProfit']!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Shared widgets ---

  Widget _summaryCard(String label, String value, Color accent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _reportLine(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _generatePdf(BuildContext context) async {
    final db = ref.read(databaseProvider);
    
    try {
      final pdfRepo = PdfRepository(db);
      final doc = await pdfRepo.generateDailyStatement(_selectedDate);
      final bytes = await doc.save();
      final dateStr = DateFormatter.dateKey(_selectedDate);
      
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
}
