import 'dart:io';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Image Upload
  Future<String> uploadImage(File file, String path) async {
    try {
      developer.log('📤 Starting image upload...');
      developer.log('📁 File path: ${file.path}');
      developer.log('📂 Storage path: $path');

      // Check if user is authenticated
      final user = _supabase.auth.currentUser;
      developer.log('👤 Current user: ${user?.id ?? "NOT AUTHENTICATED"}');
      developer.log('📧 User email: ${user?.email ?? "NO EMAIL"}');

      final fileBytes = await file.readAsBytes();
      developer.log('📊 File size: ${fileBytes.length} bytes');

      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$path/$fileName';

      developer.log('🏷️ File name: $fileName');
      developer.log('🗂️ Full file path: $filePath');
      developer.log('📝 Content type: image/$fileExt');

      developer.log('⬆️ Uploading to Supabase storage...');

      await _supabase.storage
          .from('images')
          .uploadBinary(
            filePath,
            fileBytes,
            // fileOptions: FileOptions(contentType: 'image/$fileExt'),
          );

      developer.log('✅ Upload successful!');

      final publicUrl = _supabase.storage.from('images').getPublicUrl(filePath);
      developer.log('🔗 Public URL: $publicUrl');

      return publicUrl;
    } catch (e, stackTrace) {
      developer.log('❌ Upload failed!', error: e, stackTrace: stackTrace);
      developer.log('🔍 Error type: ${e.runtimeType}');
      developer.log('📋 Error details: $e');
      rethrow;
    }
  }
}
