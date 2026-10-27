import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/currency.dart';
import '../../data/database.dart';
import '../../providers.dart';
import '../../repositories/report_repository.dart';
import '../dashboard/dashboard_screen.dart';

final _activeAccountsProvider = StreamProvider<List<Account>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.accountDao.watchAllActiveAccounts();
});

class TransfersScreen extends ConsumerStatefulWidget {
  const TransfersScreen({super.key});

  @override
  ConsumerState<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends ConsumerState<TransfersScreen> {
  int? _selectedAccountId;
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _loading = false;
  bool _isReceived = true;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Account? _getAccount(List<Account> accounts, int? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Color _accountTypeColor(String type) {
    switch (type) {
      case 'cash':
        return AppColors.cash;
      case 'bank':
        return AppColors.bank;
      default:
        return AppColors.secondary;
    }
  }

  IconData _accountTypeIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.payments;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.other_houses;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(_activeAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Account',
            onPressed: () => _showAddAccountDialog(),
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) => _buildBody(accounts),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBody(List<Account> accounts) {
    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('No accounts found', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Add an account to start transferring', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddAccountDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Account'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTypeToggle(),
        const SizedBox(height: 16),
        _buildTransferCard(accounts),
        const SizedBox(height: 24),
        const Text('Recent Transfers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _transferHistory(),
      ],
    );
  }

  Widget _buildTypeToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _isReceived = true;
                  _selectedAccountId = null;
                  _amountController.clear();
                  _reasonController.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isReceived ? AppColors.income : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_downward, size: 18, color: _isReceived ? Colors.white : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text('Received', style: TextStyle(fontWeight: FontWeight.bold, color: _isReceived ? Colors.white : AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _isReceived = false;
                  _selectedAccountId = null;
                  _amountController.clear();
                  _reasonController.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_isReceived ? AppColors.expense : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward, size: 18, color: !_isReceived ? Colors.white : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text('Done', style: TextStyle(fontWeight: FontWeight.bold, color: !_isReceived ? Colors.white : AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferCard(List<Account> accounts) {
    final now = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isReceived ? Icons.arrow_downward : Icons.arrow_upward,
                    color: _isReceived ? AppColors.income : AppColors.expense,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isReceived ? 'Transfer Received' : 'Transfer Done',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${now.day}/${now.month}/${now.year}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedAccountId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: _isReceived ? 'Received To Account' : 'Sent From Account',
                prefixIcon: Icon(_isReceived ? Icons.arrow_downward : Icons.arrow_upward, size: 18),
              ),
              items: accounts.map((a) => DropdownMenuItem(
                value: a.id,
                child: Row(
                  children: [
                    Icon(_accountTypeIcon(a.accountType), size: 18, color: _accountTypeColor(a.accountType)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(a.name, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              )).toList(),
              onChanged: (val) => setState(() => _selectedAccountId = val),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _doTransfer(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isReceived ? AppColors.income : AppColors.expense,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isReceived ? 'RECEIVE MONEY' : 'SEND MONEY'),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _transferHistory() {
    final db = ref.read(databaseProvider);
    return FutureBuilder<List<Transfer>>(
      future: db.transferDao.getAllTransfers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final transfers = snapshot.data!;
        if (transfers.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No transfers yet', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          );
        }
        return Column(
          children: transfers.take(10).map((t) {
            final dt = DateTime.fromMillisecondsSinceEpoch(t.occurredAt);
            final isReceived = t.reason?.contains('received') == true || t.toAccount == 'bank' || t.toAccount == 'cash';
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (isReceived ? AppColors.income : AppColors.expense).withOpacity(0.1),
                  child: Icon(
                    isReceived ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isReceived ? AppColors.income : AppColors.expense,
                    size: 18,
                  ),
                ),
                title: Text(
                  '${t.fromAccount} → ${t.toAccount}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  t.reason != null && t.reason!.isNotEmpty
                      ? '${t.reason} · ${DateFormatter.dateTime(dt)}'
                      : DateFormatter.dateTime(dt),
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  CurrencyFormatter.formatPaise(t.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isReceived ? AppColors.income : AppColors.expense,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    String selectedType = 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Account Name'),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    const Text('Account Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTypeOption(ctx, setModalState, 'cash', 'Cash', Icons.payments, AppColors.cash, () => selectedType, (v) => selectedType = v),
                        const SizedBox(width: 8),
                        _buildTypeOption(ctx, setModalState, 'bank', 'Bank', Icons.account_balance, AppColors.bank, () => selectedType, (v) => selectedType = v),
                        const SizedBox(width: 8),
                        _buildTypeOption(ctx, setModalState, 'other', 'Other', Icons.other_houses, AppColors.secondary, () => selectedType, (v) => selectedType = v),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Enter account name'), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          final db = ref.read(databaseProvider);
                          await db.accountDao.insertAccount(AccountsCompanion.insert(
                            name: name,
                            accountType: selectedType,
                            createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
                          ));
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$name added'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        child: const Text('Add Account'),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom > 0 ? 16 : 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeOption(
    BuildContext ctx,
    StateSetter setModalState,
    String value,
    String label,
    IconData icon,
    Color color,
    String Function() getType,
    void Function(String) setType,
  ) {
    final selected = getType() == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setModalState(() => setType(value)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : AppColors.divider),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : AppColors.textSecondary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doTransfer(BuildContext context) async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter amount'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an account'), backgroundColor: Colors.red),
      );
      return;
    }

    final accounts = ref.read(_activeAccountsProvider).valueOrNull;
    if (accounts == null) return;

    final selectedAccount = _getAccount(accounts, _selectedAccountId);
    if (selectedAccount == null) return;

    final amount = (double.parse(_amountController.text) * 100).round();

    setState(() => _loading = true);

    try {
      String fromAccount;
      String toAccount;
      String reason;

      if (_isReceived) {
        fromAccount = 'external';
        toAccount = selectedAccount.name;
        reason = _reasonController.text.isEmpty ? 'Transfer received' : _reasonController.text;
      } else {
        fromAccount = selectedAccount.name;
        toAccount = 'external';
        reason = _reasonController.text.isEmpty ? 'Transfer done' : _reasonController.text;
      }

      await TransferRepository(ref.read(databaseProvider)).transfer(
        fromAccount: fromAccount,
        toAccount: toAccount,
        amount: amount,
        reason: reason,
        notes: null,
        fromAccountId: _isReceived ? null : selectedAccount.id,
        toAccountId: _isReceived ? selectedAccount.id : null,
        fromAccountType: _isReceived ? 'external' : selectedAccount.accountType,
        toAccountType: _isReceived ? selectedAccount.accountType : 'external',
      );
      ref.invalidate(cashBalanceProvider);
      ref.invalidate(bankBalanceProvider);
      _amountController.clear();
      _reasonController.clear();
      setState(() {
        _selectedAccountId = null;
        _loading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isReceived ? 'Money received' : 'Money sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
