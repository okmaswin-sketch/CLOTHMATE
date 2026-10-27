import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

abstract class ShareService {
  Future<void> shareFile(File file, String mimeType);
  Future<String?> pickSaveLocation(String fileName, List<int> bytes);
}

class ShareServiceImpl implements ShareService {
  @override
  Future<void> shareFile(File file, String mimeType) async {
    await Share.shareXFiles([XFile(file.path, mimeType: mimeType)]);
  }

  @override
  Future<String?> pickSaveLocation(String fileName, List<int> bytes) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save $fileName',
      fileName: fileName,
    );
    if (result != null) {
      final file = File(result);
      await file.writeAsBytes(bytes);
      return result;
    }
    return null;
  }
}
