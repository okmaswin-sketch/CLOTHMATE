import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/database.dart';
import '../../providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: FutureBuilder(
        future: db.settingsDao.getSettings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final settings = snapshot.data!;
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Price Override'),
                subtitle: const Text('Allow changing price during sale'),
                value: settings.allowPriceOverride == 1,
                onChanged: (v) async {
                  await db.settingsDao.updateSettings(
                    UsersSettingsCompanion(allowPriceOverride: Value(v ? 1 : 0)),
                  );
                  if (context.mounted) setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('GST Enabled'),
                subtitle: const Text('Show tax fields in sales'),
                value: settings.gstEnabled == 1,
                onChanged: (v) async {
                  await db.settingsDao.updateSettings(
                    UsersSettingsCompanion(gstEnabled: Value(v ? 1 : 0)),
                  );
                  if (context.mounted) setState(() {});
                },
              ),
              ListTile(
                title: const Text('Low Stock Threshold'),
                subtitle: Text('${settings.lowStockThreshold} units'),
                onTap: () => _editThreshold(context, ref, settings.lowStockThreshold),
              ),
              ListTile(
                title: const Text('Business Name'),
                subtitle: Text(settings.businessName, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _editBusinessName(context, ref, settings.businessName),
              ),
              const Divider(),
              ListTile(
                title: const Text('Security'),
                leading: const Icon(Icons.lock),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/pin'),
              ),
              ListTile(
                title: const Text('Backup & Restore'),
                leading: const Icon(Icons.backup),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/backup'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editThreshold(BuildContext context, WidgetRef ref, int current) {
    final ctrl = TextEditingController(text: '$current');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Low Stock Threshold'),
        content: SingleChildScrollView(
          child: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(isDense: true)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final val = int.tryParse(ctrl.text) ?? 5;
              await ref.read(databaseProvider).settingsDao.updateSettings(
                UsersSettingsCompanion(lowStockThreshold: Value(val)),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) setState(() {});
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _editBusinessName(BuildContext context, WidgetRef ref, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Business Name'),
        content: SingleChildScrollView(
          child: TextField(controller: ctrl, decoration: const InputDecoration(isDense: true)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(databaseProvider).settingsDao.updateSettings(
                UsersSettingsCompanion(businessName: Value(ctrl.text)),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}
