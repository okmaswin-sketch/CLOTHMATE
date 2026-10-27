import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';

class BackupRepository {
  Future<String> createBackup(String dbPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now();
    final fileName = 'clothmate_backup_${timestamp.year.toString().padLeft(4, '0')}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}.zip';

    final manifest = jsonEncode({
      'app_version': '1.0.0',
      'schema_version': 1,
      'exported_at': timestamp.toUtc().toIso8601String(),
      'platform': Platform.operatingSystem,
    });

    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('Database file not found');
    }

    final dbBytes = await dbFile.readAsBytes();
    final manifestBytes = utf8.encode(manifest);

    final archive = Archive();
    archive.addFile(ArchiveFile('clothmate.sqlite', dbBytes.length, dbBytes));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    final zipData = ZipEncoder().encode(archive);

    final backupFile = File(p.join(dir.path, fileName));
    await backupFile.writeAsBytes(zipData);
    return backupFile.path;
  }

  Future<String> restoreBackup(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final dbFileEntry = archive.findFile('clothmate.sqlite');
    if (dbFileEntry == null) throw Exception('Invalid backup: missing database');

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'clothmate.sqlite');
    final dbFile = File(dbPath);

    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    await dbFile.writeAsBytes(dbFileEntry.content as List<int>);
    return dbPath;
  }
}
