import 'package:drift/drift.dart';
import '../data/database.dart';
import '../core/currency.dart';
import '../core/transaction_id.dart';

class SalesRepository {
  final AppDatabase _db;

  SalesRepository(this._db);

  Future<int> completeSale({
    required List<SaleLineItem> items,
    required String paymentMethod,
    required int discount,
    required int taxAmount,
    String? notes,
  }) async {
    final now = DateTime.now();
    final nowMillis = now.toUtc().millisecondsSinceEpoch;

    int subtotal = 0;
    for (final item in items) {
      subtotal += item.unitPrice * item.quantity;
    }
    final totalAmount = subtotal - discount + taxAmount;

    final seq = await _db.salesDao.getNextSaleSeq(DateFormatter.dateKeyCompact(now));
    final txnId = TransactionIdGenerator.sale(now, seq + 1);

    final account = paymentMethod == 'cash' ? 'cash' : 'bank';

    return await _db.transaction(() async {
      final saleId = await _db.salesDao.insertSale(SalesCompanion.insert(
        transactionId: txnId,
        saleDate: nowMillis,
        paymentMethod: paymentMethod,
        subtotal: subtotal,
        discount: Value(discount),
        taxAmount: Value(taxAmount),
        totalAmount: totalAmount,
        notes: Value(notes),
      ));

      for (final item in items) {
        final product = await _db.productDao.getProduct(item.productId);
        if (product == null) throw Exception('Product not found');
        if (product.stockQty < item.quantity) {
          throw Exception('Insufficient stock for ${product.sku}');
        }

        await _db.salesDao.insertSaleItem(SaleItemsCompanion.insert(
          saleId: saleId,
          productId: item.productId,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          lineTotal: item.unitPrice * item.quantity,
        ));

        await _db.productDao.updateStock(
            item.productId, product.stockQty - item.quantity);
      }

      final description = items.length == 1
          ? 'Sale: ${items[0].productName}'
          : 'Sale: ${items.length} items';

      await _db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: txnId,
        type: 'sale',
        account: account,
        amount: totalAmount,
        referenceTable: Value('sales'),
        referenceId: Value(saleId),
        occurredAt: nowMillis,
        description: Value(description),
      ));

      return saleId;
    });
  }

  Future<void> returnItem({
    required int saleItemId,
    required int quantityReturned,
    required String refundMethod,
    String? reason,
  }) async {
    final now = DateTime.now();
    final nowMillis = now.toUtc().millisecondsSinceEpoch;

    final saleItem = await _db.customSelect(
      'SELECT * FROM sale_items WHERE id = ?',
      variables: [Variable.withInt(saleItemId)],
    ).getSingleOrNull();
    if (saleItem == null) throw Exception('Sale item not found');

    final productId = saleItem.data['product_id'] as int;
    final unitPrice = saleItem.data['unit_price'] as int;
    final refundAmount = unitPrice * quantityReturned;

    await _db.transaction(() async {
      await _db.salesDao.insertSaleReturn(SaleReturnsCompanion.insert(
        saleItemId: saleItemId,
        quantityReturned: quantityReturned,
        refundAmount: refundAmount,
        refundMethod: refundMethod,
        returnDate: nowMillis,
        reason: Value(reason),
      ));

      final product = await _db.productDao.getProduct(productId);
      if (product != null) {
        await _db.productDao.updateStock(
            productId, product.stockQty + quantityReturned);
        await _db.productDao.insertStockAdjustment(
            StockAdjustmentsCompanion.insert(
          productId: productId,
          changeQty: quantityReturned,
          reason: 'return',
          notes: Value(reason),
          createdAt: nowMillis,
        ));
      }

      final account = refundMethod == 'cash' ? 'cash' : 'bank';
      final seq = await _db.salesDao.getNextSaleSeq(DateFormatter.dateKeyCompact(now));
      final txnId = 'R${txnIdSuffix(now, seq + 1)}';

      await _db.ledgerDao.insertLedgerEntry(LedgerTransactionsCompanion.insert(
        transactionId: txnId,
        type: 'sale',
        account: account,
        amount: -refundAmount,
        referenceTable: Value('sale_returns'),
        referenceId: Value(saleItemId),
        occurredAt: nowMillis,
        description: Value('Return: ${reason ?? "No reason"}'),
      ));
    });
  }

  String txnIdSuffix(DateTime dt, int seq) {
    final y = dt.year.toString().substring(2);
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d${seq.toString().padLeft(4, '0')}';
  }
}

class SaleLineItem {
  final int productId;
  final String productName;
  final int unitPrice;
  final int quantity;

  SaleLineItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });
}
