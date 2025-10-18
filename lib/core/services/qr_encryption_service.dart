import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

class QREncryptionService {
  // This key should be stored securely in Firebase Remote Config in production
  // Key is exactly 32 characters (256 bits) for AES-256 encryption
  static const String _secretKey = 'neqati_secure_key_32_characters!';

  // Encrypt QR code data
  static String encryptQRData(Map<String, dynamic> data) {
    try {
      print('🔐 Starting encryption with data: $data');

      // Convert data to JSON string
      final jsonString = jsonEncode(data);
      print(
        '🔐 JSON string created: $jsonString (length: ${jsonString.length})',
      );

      // Create encryption key
      print(
        '🔐 Creating encryption key from: $_secretKey (length: ${_secretKey.length})',
      );
      final key = encrypt.Key.fromUtf8(_secretKey);
      print('🔐 Key created successfully (${key.bytes.length} bytes)');

      // Use a fixed IV for consistency between encryption and decryption
      final iv = encrypt.IV.fromUtf8('neqati_iv_16byte');
      print('🔐 IV created successfully (fixed IV)');

      // Create encrypter
      print('🔐 Creating AES encrypter...');
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      print('🔐 Encrypter created successfully');

      // Encrypt data
      print('🔐 Encrypting JSON string...');
      final encrypted = encrypter.encrypt(jsonString, iv: iv);
      print('🔐 Encryption completed successfully');

      // Return base64 encoded encrypted data
      final base64Result = encrypted.base64;
      print(
        '🔐 Base64 encoding completed. Result length: ${base64Result.length}',
      );
      return base64Result;
    } catch (e) {
      print('❌ Error encrypting QR data: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      debugPrint('Error encrypting QR data: $e');
      throw Exception('Failed to encrypt QR data');
    }
  }

  // Decrypt QR code data - handles both encrypted and legacy plain text QR codes
  static Map<String, dynamic> decryptQRData(String qrData) {
    try {
      print('🔓 Starting QR code decryption...');
      print('🔓 Raw QR data: $qrData');

      // Check if this is a legacy plain text QR code (format: QR_id:points:branch)
      if (qrData.startsWith('QR_') && qrData.contains(':')) {
        print('🔓 Detected legacy plain text QR code format');
        return _parseLegacyQRCode(qrData);
      }

      // Otherwise, try to decrypt as encrypted QR code
      print('🔓 Attempting to decrypt as encrypted QR code...');
      print('🔓 Encrypted data length: ${qrData.length}');
      print(
        '🔓 Encrypted data preview: ${qrData.length > 50 ? qrData.substring(0, 50) + '...' : qrData}',
      );

      // Validate input
      if (qrData.isEmpty) {
        throw Exception('Empty encrypted data');
      }

      // Create encryption key
      print(
        '🔓 Creating decryption key from: $_secretKey (length: ${_secretKey.length})',
      );
      final key = encrypt.Key.fromUtf8(_secretKey);
      print('🔓 Key created successfully (${key.bytes.length} bytes)');

      // Use the same fixed IV as encryption
      final iv = encrypt.IV.fromUtf8('neqati_iv_16byte');
      print('🔓 IV created successfully (fixed IV)');

      // Create encrypter
      print('🔓 Creating AES decrypter...');
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      print('🔓 Decrypter created successfully');

      // Decrypt data
      print('🔓 Decrypting base64 data...');
      final decrypted = encrypter.decrypt64(qrData, iv: iv);
      print('🔓 Decryption completed. Decrypted string: $decrypted');

      // Parse JSON string to Map
      print('🔓 Parsing JSON string...');
      final result = jsonDecode(decrypted) as Map<String, dynamic>;
      print('🔓 JSON parsing completed successfully: $result');

      return result;
    } catch (e) {
      print('❌ Error decrypting QR data: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      debugPrint('Error decrypting QR data: $e');
      throw Exception('Invalid QR code format');
    }
  }

  // Parse legacy plain text QR code format: QR_id:points:branch
  static Map<String, dynamic> _parseLegacyQRCode(String qrData) {
    try {
      print('🔓 Parsing legacy QR code: $qrData');

      // Remove 'QR_' prefix
      final dataWithoutPrefix = qrData.substring(3);
      print('🔓 Data without prefix: $dataWithoutPrefix');

      // Split by colon
      final parts = dataWithoutPrefix.split(':');
      print('🔓 Split parts: $parts (count: ${parts.length})');

      if (parts.length < 3) {
        throw Exception(
          'Invalid legacy QR code format - expected at least 3 parts',
        );
      }

      final id = parts[0];
      final points = int.parse(parts[1]);
      final branch = parts
          .sublist(2)
          .join(':'); // Join remaining parts in case branch name has colons

      print('🔓 Parsed legacy QR code:');
      print('   - id: $id');
      print('   - points: $points');
      print('   - branch: $branch');

      // Return in the same format as encrypted QR codes
      // Use a default expiry of 30 days for legacy codes
      final result = {
        'id': id,
        'points': points,
        'branch': branch,
        'expiryDuration': 30,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      print('🔓 Legacy QR code parsed successfully: $result');
      return result;
    } catch (e) {
      print('❌ Error parsing legacy QR code: $e');
      throw Exception('Invalid legacy QR code format');
    }
  }

  // Generate QR code data
  static Map<String, dynamic> generateQRData({
    required int points,
    required String branch,
    required String id,
    required int expiryDuration,
  }) {
    print('📊 Generating QR data with:');
    print('   - points: $points (${points.runtimeType})');
    print('   - branch: $branch (${branch.runtimeType})');
    print('   - id: $id (${id.runtimeType})');
    print(
      '   - expiryDuration: $expiryDuration (${expiryDuration.runtimeType})',
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    print('   - timestamp: $timestamp (${timestamp.runtimeType})');

    final result = {
      'points': points,
      'branch': branch,
      'id': id,
      'expiryDuration': expiryDuration,
      'timestamp': timestamp,
    };

    print('📊 Generated QR data: $result');
    return result;
  }

  // Validate QR code data
  static bool validateQRData(Map<String, dynamic> data) {
    // Check if required fields exist
    if (!data.containsKey('points') ||
        !data.containsKey('branch') ||
        !data.containsKey('id') ||
        !data.containsKey('expiryDuration') ||
        !data.containsKey('timestamp')) {
      return false;
    }

    // Check if QR code is expired
    final timestamp = data['timestamp'] as int;
    final expiryDuration = data['expiryDuration'] as int;
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(
      timestamp,
    ).add(Duration(days: expiryDuration));

    return DateTime.now().isBefore(expiryDate);
  }
}
