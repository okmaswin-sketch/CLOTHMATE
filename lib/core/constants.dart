class AppConstants {
  static const appName = 'ClothMate';
  static const defaultCurrency = '₹';
  static const defaultLowStockThreshold = 5;
  static const defaultAutoLockMinutes = 5;

  static const expenseCategories = [
    'maintenance:electricity',
    'maintenance:rent',
    'maintenance:repairs',
    'maintenance:transport',
    'maintenance:supplies',
    'maintenance:cleaning',
    'maintenance:other',
    'general',
  ];

  static const expenseCategoryLabels = {
    'maintenance:electricity': 'Electricity',
    'maintenance:rent': 'Rent',
    'maintenance:repairs': 'Repairs',
    'maintenance:transport': 'Transport',
    'maintenance:supplies': 'Supplies',
    'maintenance:cleaning': 'Cleaning',
    'maintenance:other': 'Other Maintenance',
    'general': 'General Expense',
  };

  static const paymentMethods = ['cash', 'upi', 'bank', 'other'];

  static const paymentMethodLabels = {
    'cash': 'Cash',
    'upi': 'GPay / UPI',
    'bank': 'Bank',
    'other': 'Other',
  };

  static const ledgerTypes = [
    'sale', 'wage', 'expense', 'income',
    'transfer_in', 'transfer_out',
    'opening_balance', 'stock_adjustment',
  ];

  static const stockAdjustmentReasons = [
    'restock', 'damage', 'correction', 'return',
  ];

  static const seedGarmentTypes = ['Shirt', 'Pants', 'Night Dress'];
  static const seedSizes = ['S', 'M', 'L', 'XL', 'XXL', '3XL'];

  static const ledgerTypeIcons = {
    'sale': '🛒',
    'wage': '👷',
    'expense': '💸',
    'income': '💰',
    'transfer_in': '📥',
    'transfer_out': '📤',
    'opening_balance': '🏦',
    'stock_adjustment': '📦',
  };
}
