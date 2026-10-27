import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../providers.dart';

class FirstTimeSetupScreen extends ConsumerStatefulWidget {
  const FirstTimeSetupScreen({super.key});

  @override
  ConsumerState<FirstTimeSetupScreen> createState() => _FirstTimeSetupScreenState();
}

class _FirstTimeSetupScreenState extends ConsumerState<FirstTimeSetupScreen> {
  final _cashController = TextEditingController();
  final _bankController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.account_balance_wallet, size: 64, color: AppColors.secondary),
                        const SizedBox(height: 16),
                        const Text('Welcome to ClothMate', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Set your opening balances to get started.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _cashController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Opening Cash Balance (₹)', prefixText: '₹ '),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bankController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Opening Bank Balance (₹)', prefixText: '₹ '),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final cashPaise = (double.parse(_cashController.text) * 100).round();
                              final bankPaise = (double.parse(_bankController.text) * 100).round();
                              await ref.read(balanceRepoProvider).setFirstTimeOpeningBalance(cashPaise, bankPaise);
                              if (context.mounted) context.go('/dashboard');
                            }
                          },
                          child: const Text('GET STARTED'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
