class TransactionIdGenerator {
  static String _yyMMDD(DateTime dt) {
    final y = dt.year.toString().substring(2);
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  static String sale(DateTime dt, int seq) {
    return 'S${_yyMMDD(dt)}${seq.toString().padLeft(4, '0')}';
  }

  static String income(DateTime dt, int seq) {
    return 'I${_yyMMDD(dt)}${seq.toString().padLeft(4, '0')}';
  }

  static String expense(DateTime dt, int seq) {
    return 'E${_yyMMDD(dt)}${seq.toString().padLeft(4, '0')}';
  }

  static String transfer(DateTime dt, int seq) {
    return 'T${_yyMMDD(dt)}${seq.toString().padLeft(4, '0')}';
  }

  static String wage(String workerInitials, DateTime dt, int seq) {
    return '${workerInitials.toUpperCase()}${_yyMMDD(dt)}${seq.toString().padLeft(3, '0')}';
  }

  static String sku(String typeInitial, String materialInitial, String size, DateTime dt, int seq) {
    final ym = '${dt.year.toString().substring(2)}${dt.month.toString().padLeft(2, '0')}';
    return '${typeInitial.toUpperCase()}${materialInitial.toUpperCase()}$size$ym${seq.toString().padLeft(2, '0')}';
  }

  static String getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'X';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
