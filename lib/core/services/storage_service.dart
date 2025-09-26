import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Image Upload
  Future<String> uploadImage(File file, String path) async {
    final fileBytes = await file.readAsBytes();
    final fileExt = file.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = '$path/$fileName';

    await _supabase.storage
        .from('images')
        .uploadBinary(
          filePath,
          fileBytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'),
        );

    return _supabase.storage.from('images').getPublicUrl(filePath);
  }
}
