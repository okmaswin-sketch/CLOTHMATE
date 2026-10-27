import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../app/theme.dart';
import '../../repositories/backup_repository.dart';
import '../../services/share_service.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _restoreController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.backup, color: AppColors.income),
                title: const Text('Create Backup'),
                subtitle: const Text('Save all your data to a zip file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _createBackup,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.restore, color: AppColors.warning),
                title: const Text('Restore Backup'),
                subtitle: const Text('Restore data from a backup file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _restoreBackup,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: AppColors.bank),
                title: const Text('Export PDF'),
                subtitle: const Text('Export daily statement as PDF'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.table_chart, color: AppColors.cash),
                title: const Text('Export CSV'),
                subtitle: const Text('Export data as CSV files'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
            if (_loading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() => _loading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dir.path, 'clothmate.sqlite');
      final backupRepo = BackupRepository();
      final path = await backupRepo.createBackup(dbPath);
      final shareService = ShareServiceImpl();
      final file = File(path);
      await shareService.shareFile(file, 'application/zip');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restoreBackup() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('RESTORE WILL OVERWRITE ALL DATA', maxLines: 2, overflow: TextOverflow.ellipsis),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This action cannot be undone.'),
              const SizedBox(height: 12),
              const Text('To confirm, type RESTORE in the box below:'),
              const SizedBox(height: 8),
              TextField(
                controller: _restoreController,
                decoration: const InputDecoration(hintText: 'Type RESTORE', isDense: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              if (_restoreController.text != 'RESTORE') return;
              Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a backup file'), backgroundColor: Colors.blue),
                );
              }
            },
            child: const Text('RESTORE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
