import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../model/support_models.dart';

Future<SupportLocalAttachment> cacheSupportDrop(Stream<List<int>> stream,
    String? name, String mime, String extension) async {
  final directory = await Directory.systemTemp.createTemp('support-drop-');
  final safeName = name == null ? 'attachment.$extension' : path.basename(name);
  final file = File(path.join(directory.path, 'attachment.$extension'));
  final sink = file.openWrite();
  var size = 0;
  try {
    await for (final bytes in stream.timeout(const Duration(seconds: 30))) {
      size += bytes.length;
      if (size > 10 * 1024 * 1024) {
        throw const FormatException('Attachment too large');
      }
      sink.add(bytes);
    }
    await sink.close();
    if (size == 0) throw const FormatException('Empty attachment');
    return SupportLocalAttachment(
        path: file.path,
        name: safeName,
        size: size,
        mimeType: mime,
        temporary: true);
  } catch (_) {
    await sink.close();
    if (await file.exists()) await file.delete();
    await directory.delete();
    rethrow;
  }
}

Future<void> removeSupportDrop(SupportLocalAttachment file) async {
  if (!file.temporary) return;
  try {
    await file.file.delete();
    await file.file.parent.delete();
  } on FileSystemException catch (_) {}
}
