import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../data/database.dart';
import '../core/currency.dart';

class PdfRepository {
  final AppDatabase _db;

  PdfRepository(this._db);

  Future<pw.Document> generateDailyStatement(DateTime date) async {
    final pdf = pw.Document();
    final dayStart = DateTime(date.year, date.month, date.day).toUtc().millisecondsSinceEpoch;
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59, 999).toUtc().millisecondsSinceEpoch;
    final dateStr = DateFormatter.dateKey(date);

    final sales = await _db.salesDao.getSalesForDate(dayStart, dayEnd);
    final expenses = await _db.expenseDao.getExpensesForDate(dayStart, dayEnd);
    final incomes = await _db.incomeDao.getIncomeForDate(dayStart, dayEnd);
    final wages = await _db.wageDao.getWagesForDate(dayStart, dayEnd);
    final transfers = await _db.transferDao.getAllTransfers();
    final dayTransfers = transfers.where((t) =>
        t.occurredAt >= dayStart && t.occurredAt <= dayEnd).toList();

    final opening = await _db.ledgerDao.getOpeningBalance(dateStr);

    final allGarmentTypes = await _db.garmentDao.getAllGarmentTypes();
    final typeNameMap = <int, String>{};
    for (final gt in allGarmentTypes) {
      typeNameMap[gt.id] = gt.name;
    }

    int totalSales = 0;
    int cashSales = 0;
    int bankSales = 0;
    Map<String, int> salesByType = {};
    for (final sale in sales) {
      totalSales += sale.totalAmount;
      if (sale.paymentMethod == 'cash') {
        cashSales += sale.totalAmount;
      } else {
        bankSales += sale.totalAmount;
      }
      final items = await _db.salesDao.getSaleItems(sale.id);
      for (final item in items) {
        final product = await _db.productDao.getProduct(item.productId);
        final typeName = product != null ? (typeNameMap[product.garmentTypeId] ?? 'Type ${product.garmentTypeId}') : 'Other';
        salesByType[typeName] = (salesByType[typeName] ?? 0) + item.lineTotal;
      }
    }

    int totalMaintenance = 0;
    int totalOtherExpenses = 0;
    for (final exp in expenses) {
      if (exp.category.startsWith('maintenance:')) {
        totalMaintenance += exp.amount;
      } else {
        totalOtherExpenses += exp.amount;
      }
    }

    int totalWages = 0;
    for (final w in wages) {
      if (w.paymentStatus == 'paid') totalWages += w.amount;
    }

    int cashIncome = 0;
    int bankIncome = 0;
    for (final inc in incomes) {
      if (inc.paymentType == 'cash') {
        cashIncome += inc.amount;
      } else {
        bankIncome += inc.amount;
      }
    }

    int bankToCash = 0;
    int cashToBank = 0;
    for (final t in dayTransfers) {
      if (t.fromAccount == 'bank' && t.toAccount == 'cash') {
        bankToCash += t.amount;
      } else if (t.fromAccount == 'cash' && t.toAccount == 'bank') {
        cashToBank += t.amount;
      }
    }

    final openingCash = opening?.openingCash ?? 0;
    final openingBank = opening?.openingBank ?? 0;
    final closingCash = openingCash + cashSales + cashIncome + bankToCash - totalMaintenance - totalWages - totalOtherExpenses - cashToBank;
    final closingBank = openingBank + bankSales + bankIncome + cashToBank - bankToCash;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text('ClothMate', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Header(level: 1, child: pw.Text('Daily Financial Statement')),
        pw.Text(DateFormatter.fullDate(date), style: const pw.TextStyle(fontSize: 12)),
        pw.Text('Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 20),
        _sectionHeader('SALES'),
        for (final entry in salesByType.entries)
          _lineItem(entry.key, CurrencyFormatter.formatPaisePdf(entry.value)),
        _lineItem('Total Sales', CurrencyFormatter.formatPaisePdf(totalSales), bold: true),
        pw.SizedBox(height: 10),
        _sectionHeader('PAYMENT COLLECTION'),
        _lineItem('Cash', CurrencyFormatter.formatPaisePdf(cashSales)),
        _lineItem('Bank/UPI', CurrencyFormatter.formatPaisePdf(bankSales)),
        pw.SizedBox(height: 10),
        _sectionHeader('OTHER INCOME'),
        _lineItem('Cash Income', CurrencyFormatter.formatPaisePdf(cashIncome)),
        _lineItem('Bank Income', CurrencyFormatter.formatPaisePdf(bankIncome)),
        pw.SizedBox(height: 10),
        _sectionHeader('EXPENSES'),
        _lineItem('Maintenance', CurrencyFormatter.formatPaisePdf(totalMaintenance)),
        _lineItem('Workers Wages', CurrencyFormatter.formatPaisePdf(totalWages)),
        _lineItem('Other Expenses', CurrencyFormatter.formatPaisePdf(totalOtherExpenses)),
        pw.SizedBox(height: 10),
        if (dayTransfers.isNotEmpty) ...[
          _sectionHeader('TRANSFERS'),
          for (final t in dayTransfers)
            _lineItem('${t.fromAccount.toUpperCase()} -> ${t.toAccount.toUpperCase()}', CurrencyFormatter.formatPaisePdf(t.amount)),
          pw.SizedBox(height: 10),
        ],
        _sectionHeader('CASH SUMMARY'),
        _lineItem('Opening', CurrencyFormatter.formatPaisePdf(openingCash)),
        _lineItem('+ Cash Sales', CurrencyFormatter.formatPaisePdf(cashSales)),
        _lineItem('+ Cash Income', CurrencyFormatter.formatPaisePdf(cashIncome)),
        if (bankToCash > 0) _lineItem('+ Bank -> Cash', CurrencyFormatter.formatPaisePdf(bankToCash)),
        _lineItem('- Expenses/Wages', CurrencyFormatter.formatPaisePdf(totalMaintenance + totalWages + totalOtherExpenses)),
        if (cashToBank > 0) _lineItem('- Cash -> Bank', CurrencyFormatter.formatPaisePdf(cashToBank)),
        _lineItem('Closing', CurrencyFormatter.formatPaisePdf(closingCash), bold: true),
        pw.SizedBox(height: 10),
        _sectionHeader('BANK SUMMARY'),
        _lineItem('Opening', CurrencyFormatter.formatPaisePdf(openingBank)),
        _lineItem('+ Bank Sales', CurrencyFormatter.formatPaisePdf(bankSales)),
        _lineItem('+ Bank Income', CurrencyFormatter.formatPaisePdf(bankIncome)),
        if (cashToBank > 0) _lineItem('+ Cash -> Bank', CurrencyFormatter.formatPaisePdf(cashToBank)),
        if (bankToCash > 0) _lineItem('- Bank -> Cash', CurrencyFormatter.formatPaisePdf(bankToCash)),
        _lineItem('Closing', CurrencyFormatter.formatPaisePdf(closingBank), bold: true),
        pw.SizedBox(height: 15),
        _sectionHeader('BALANCE'),
        _lineItem('Cash Balance', CurrencyFormatter.formatPaisePdf(closingCash), bold: true),
        _lineItem('Bank Balance', CurrencyFormatter.formatPaisePdf(closingBank), bold: true),
      ],
    ));

    return pdf;
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
      ),
    );
  }

  pw.Widget _lineItem(String label, String value, {bool bold = false}) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          )),
          pw.Text(value, style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          )),
        ],
      ),
    );
  }
}
