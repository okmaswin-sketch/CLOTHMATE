import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/sales/sales_screen.dart';
import '../screens/sales/create_sale_screen.dart';
import '../screens/garments/garments_screen.dart';
import '../screens/garments/add_garment_screen.dart';
import '../screens/workers/workers_screen.dart';
import '../screens/workers/daily_wages_screen.dart';
import '../screens/accounts/accounts_screen.dart';
import '../screens/accounts/income_expenses_screen.dart';
import '../screens/accounts/transfers_screen.dart';
import '../screens/accounts/transaction_history_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/backup/backup_screen.dart';
import '../screens/settings/pin_screen.dart';
import '../screens/dashboard/first_time_setup.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// Consistent transition duration
const _transitionDuration = Duration(milliseconds: 220);
const _transitionCurve = Curves.easeOutCubic;

Page<dynamic> _buildPage<T>({
  required Widget child,
  required LocalKey key,
  String? name,
  Object? arguments,
  bool fullscreenDialog = false,
}) {
  return CustomTransitionPage<T>(
    key: key,
    name: name,
    arguments: arguments,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: _transitionDuration,
    reverseTransitionDuration: _transitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 0.04);
      const end = Offset.zero;
      const curve = _transitionCurve;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var fadeTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(opacity: animation.drive(fadeTween), child: child),
      );
    },
    child: child,
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, __) => _buildPage(key: const ValueKey('splash'), child: const SplashScreen()),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (_, __) => _buildPage(key: const ValueKey('dashboard'), child: const DashboardScreen()),
          ),
          GoRoute(
            path: '/sales',
            pageBuilder: (_, __) => _buildPage(key: const ValueKey('sales'), child: const SalesScreen()),
          ),
          GoRoute(
            path: '/accounts',
            pageBuilder: (_, __) => _buildPage(key: const ValueKey('accounts'), child: const AccountsScreen()),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (_, __) => _buildPage(key: const ValueKey('reports'), child: const ReportsScreen()),
          ),
          GoRoute(
            path: '/more',
            pageBuilder: (_, __) => _buildPage(key: const ValueKey('more'), child: const MoreScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/create-sale',
        pageBuilder: (_, __) => _buildPage(
          key: const ValueKey('create-sale'),
          child: const CreateSaleScreen(),
          fullscreenDialog: true,
        ),
      ),
      GoRoute(
        path: '/garments',
        pageBuilder: (_, __) => _buildPage(key: const ValueKey('garments'), child: const GarmentsScreen()),
      ),
      GoRoute(
        path: '/add-garment',
        pageBuilder: (_, __) => _buildPage(key: const ValueKey('add-garment'), child: const AddGarmentScreen()),
      ),
      GoRoute(
        path: '/workers',
        pageBuilder: (_, __) => _buildPage(key: const ValueKey('workers'), child: const WorkersScreen()),
      ),
      GoRoute(
        path: '/daily-wages',
        pageBuilder: (_, __) => _buildPage(key: const ValueKey('daily-wages'), child: const DailyWagesScreen()),
      ),
      GoRoute(
        path: '/income-expenses',
        pageBuilder: (_, __) => _buildPage(key: const ValueKey('income-expenses'), child: const IncomeExpensesScreen()),
      ),
      GoRoute(
        path: '/transfers',
        pageBuilder: (_, __) => _buildPage(key: const ValueKey('transfers'), child: const TransfersScreen()),
      ),
      GoRoute(
        path: '/transactions',
        pageBuilder: (_, __) => _buildPage(key: const ValueKey('transactions'), child: const TransactionHistoryScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, __) => _buildPage(key: const ValueKey('settings'), child: const SettingsScreen()),
      ),
      GoRoute(
        path: '/backup',
        pageBuilder: (_, __) => _buildPage(key: const ValueKey('backup'), child: const BackupScreen()),
      ),
      GoRoute(
        path: '/pin',
        pageBuilder: (_, __) => _buildPage(key: const ValueKey('pin'), child: const PinScreen()),
      ),
      GoRoute(
        path: '/first-time',
        pageBuilder: (_, __) => _buildPage(key: const ValueKey('first-time'), child: const FirstTimeSetupScreen()),
      ),
    ],
  );
});

class ScaffoldWithNav extends StatefulWidget {
  final Widget child;
  const ScaffoldWithNav({super.key, required this.child});

  @override
  State<ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends State<ScaffoldWithNav> {
  int _currentIndex = 0;
  late Widget _currentChild;

  @override
  void initState() {
    super.initState();
    _currentChild = widget.child;
  }

  @override
  void didUpdateWidget(covariant ScaffoldWithNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != oldWidget.child) {
      setState(() {
        _currentChild = widget.child;
        _currentIndex = _calculateIndexFromChild(widget.child);
      });
    }
  }

  int _calculateIndexFromChild(Widget child) {
    if (child is DashboardScreen) return 0;
    if (child is SalesScreen) return 1;
    if (child is AccountsScreen) return 2;
    if (child is ReportsScreen) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _currentChild,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => _onTap(context, i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Accounts'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), activeIcon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/dashboard');
      case 1: context.go('/sales');
      case 2: context.go('/accounts');
      case 3: context.go('/reports');
      case 4: context.go('/more');
    }
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          _tile(context, Icons.checkroom, 'Garment Management', '/garments'),
          _tile(context, Icons.people, 'Workers & Wages', '/workers'),
          _tile(context, Icons.swap_horiz, 'Transfers', '/transfers'),
          _tile(context, Icons.receipt_long, 'Transaction History', '/transactions'),
          _tile(context, Icons.backup, 'Backup & Restore', '/backup'),
          _tile(context, Icons.settings, 'Settings', '/settings'),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () => context.push(route),
    );
  }
}
