import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/database.dart';
import '../core/currency.dart';

class ExportRepository {
  final AppDatabase _db;

  ExportRepository(this._db);

  Future<void> exportAndShare() async {
    final zipBytes = await generateZipBytes();
    final dir = await getTemporaryDirectory();
    final dateStr = DateFormatter.dateKey(DateTime.now());
    final file = File('${dir.path}/clothmate_export_$dateStr.zip');
    await file.writeAsBytes(zipBytes);
    await Share.shareXFiles([XFile(file.path, mimeType: 'application/zip')]);
  }

  Future<List<int>> generateZipBytes() async {
    final archive = Archive();

    // Products
    final products = await _db.productDao.getAllActiveProducts();
    final garmentTypes = await _db.garmentDao.getAllGarmentTypes();
    final allMaterials = await _db.garmentDao.getAllMaterials();
    final sizes = await _db.garmentDao.getAllSizes();
    final typeMap = {for (final t in garmentTypes) t.id: t.name};
    final matMap = {for (final m in allMaterials) m.id: m.name};
    final sizeMap = {for (final s in sizes) s.id: s.name};

    final productCsv = StringBuffer();
    productCsv.writeln('SKU,Type,Material,Size,Selling Price,Cost Price,Stock');
    for (final p in products) {
      final sp = CurrencyFormatter.formatPaise(p.sellingPrice);
      final cp = p.costPrice != null ? CurrencyFormatter.formatPaise(p.costPrice!) : '';
      productCsv.writeln('${_csv(p.sku)},${_csv(typeMap[p.garmentTypeId] ?? '')},${_csv(matMap[p.materialId] ?? '')},${_csv(sizeMap[p.sizeId] ?? '')},$sp,$cp,${p.stockQty}');
    }
    archive.addFile(ArchiveFile.bytes('products.csv', _toBytes(productCsv.toString())));

    // Sales
    final sales = await _db.salesDao.getAllSales();
    final salesCsv = StringBuffer();
    salesCsv.writeln('Transaction ID,Date,Payment Method,Total Amount,Status');
    for (final s in sales) {
      final dt = DateTime.fromMillisecondsSinceEpoch(s.saleDate);
      salesCsv.writeln('${_csv(s.transactionId)},${_csv(dt.toIso8601String())},${_csv(s.paymentMethod)},${CurrencyFormatter.formatPaise(s.totalAmount)},${_csv(s.status)}');
    }
    archive.addFile(ArchiveFile.bytes('sales.csv', _toBytes(salesCsv.toString())));

    // Workers
    final workers = await _db.workerDao.getAllWorkers();
    final workersCsv = StringBuffer();
    workersCsv.writeln('Name,Daily Wage,Status');
    for (final w in workers) {
      workersCsv.writeln('${_csv(w.name)},${CurrencyFormatter.formatPaise(w.dailyWage)},${_csv(w.status)}');
    }
    archive.addFile(ArchiveFile.bytes('workers.csv', _toBytes(workersCsv.toString())));

    // Wages
    final wages = await _db.wageDao.getAllWages();
    final wagesCsv = StringBuffer();
    wagesCsv.writeln('Worker ID,Date,Amount,Payment Status,Payment Method');
    for (final w in wages) {
      final dt = DateTime.fromMillisecondsSinceEpoch(w.wageDate);
      wagesCsv.writeln('${w.workerId},${_csv(dt.toIso8601String())},${CurrencyFormatter.formatPaise(w.amount)},${_csv(w.paymentStatus)},${_csv(w.paymentMethod ?? '')}');
    }
    archive.addFile(ArchiveFile.bytes('wages.csv', _toBytes(wagesCsv.toString())));

    // Income
    final incomes = await _db.incomeDao.getAllIncome();
    final incomeCsv = StringBuffer();
    incomeCsv.writeln('Transaction ID,Date,Amount,Payment Type,Description');
    for (final i in incomes) {
      final dt = DateTime.fromMillisecondsSinceEpoch(i.occurredAt);
      incomeCsv.writeln('${_csv(i.transactionId)},${_csv(dt.toIso8601String())},${CurrencyFormatter.formatPaise(i.amount)},${_csv(i.paymentType)},${_csv(i.description ?? '')}');
    }
    archive.addFile(ArchiveFile.bytes('income.csv', _toBytes(incomeCsv.toString())));

    // Expenses
    final expenses = await _db.expenseDao.getAllExpenses();
    final expensesCsv = StringBuffer();
    expensesCsv.writeln('Transaction ID,Date,Amount,Category,Description');
    for (final e in expenses) {
      final dt = DateTime.fromMillisecondsSinceEpoch(e.occurredAt);
      expensesCsv.writeln('${_csv(e.transactionId)},${_csv(dt.toIso8601String())},${CurrencyFormatter.formatPaise(e.amount)},${_csv(e.category)},${_csv(e.description ?? '')}');
    }
    archive.addFile(ArchiveFile.bytes('expenses.csv', _toBytes(expensesCsv.toString())));

    // Transfers
    final transfers = await _db.transferDao.getAllTransfers();
    final transfersCsv = StringBuffer();
    transfersCsv.writeln('Transfer ID,Date,From Account,To Account,Amount');
    for (final t in transfers) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.occurredAt);
      transfersCsv.writeln('${_csv(t.transferId)},${_csv(dt.toIso8601String())},${_csv(t.fromAccount)},${_csv(t.toAccount)},${CurrencyFormatter.formatPaise(t.amount)}');
    }
    archive.addFile(ArchiveFile.bytes('transfers.csv', _toBytes(transfersCsv.toString())));

    return ZipEncoder().encode(archive);
  }

  static String _csv(String? value) {
    final v = value ?? '';
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  static List<int> _toBytes(String s) => s.codeUnits;
}
