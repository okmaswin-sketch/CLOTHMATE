import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../data/database.dart';
import '../../providers.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final _pinController = TextEditingController();
  bool _isSetting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock, size: 48, color: AppColors.secondary),
            const SizedBox(height: 16),
            Text(
              _isSetting ? 'Set your PIN' : 'Enter PIN to test',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'PIN (4-6 digits)', counterText: ''),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_pinController.text.length < 4) return;
                final db = ref.read(databaseProvider);
                await db.settingsDao.updateSettings(
                  UsersSettingsCompanion(pinHash: Value(_pinController.text)),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN saved'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('SAVE PIN'),
            ),
          ],
        ),
      ),
    );
  }
}
