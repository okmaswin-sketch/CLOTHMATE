import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _indianFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _indianFormatDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String formatPaise(int paise) {
    if (paise < 0) {
      return '-${_indianFormat.format(paise.abs() / 100)}';
    }
    return _indianFormat.format(paise / 100);
  }

  static String formatPaiseWithDecimals(int paise) {
    if (paise < 0) {
      return '-${_indianFormatDecimal.format(paise.abs() / 100)}';
    }
    return _indianFormatDecimal.format(paise / 100);
  }

  static String formatCompact(int paise) {
    final amount = paise / 100;
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return _indianFormat.format(amount);
  }

  static String formatPaisePdf(int paise) {
    return formatPaise(paise).replaceAll('₹', 'Rs.');
  }

  static int rupeesToPaise(double rupees) {
    return (rupees * 100).round();
  }

  static double paiseToRupees(int paise) {
    return paise / 100.0;
  }
}

class DateFormatter {
  static String fullDate(DateTime dt) {
    return DateFormat('dd MMMM yyyy').format(dt);
  }

  static String shortDate(DateTime dt) {
    return DateFormat('dd MMM').format(dt);
  }

  static String time12h(DateTime dt) {
    return DateFormat('hh:mm a').format(dt);
  }

  static String dateTime(DateTime dt) {
    return '${fullDate(dt)} · ${time12h(dt)}';
  }

  static String dateFile(DateTime dt) {
    return DateFormat('yyyyMMdd_HHmm').format(dt);
  }

  static String dateKey(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static String dateKeyCompact(DateTime dt) {
    final y = dt.year.toString().substring(2);
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  static String yearMonth(DateTime dt) {
    return DateFormat('yyyy-MM').format(dt);
  }

  static int dayStartMillis(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return d.toUtc().millisecondsSinceEpoch;
  }

  static int dayEndMillis(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);
    return d.toUtc().millisecondsSinceEpoch;
  }
}
