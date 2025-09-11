import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

class QREncryptionService {
  // This key should be stored securely in Firebase Remote Config in production
  static const String _secretKey = 'neqati_secure_encryption_key_123456';
  
  // Encrypt QR code data
  static String encryptQRData(Map<String, dynamic> data) {
    try {
      // Convert data to JSON string
      final jsonString = jsonEncode(data);
      
      // Create encryption key
      final key = encrypt.Key.fromUtf8(_secretKey.padRight(32, '0'));
      final iv = encrypt.IV.fromLength(16);
      
      // Create encrypter
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      // Encrypt data
      final encrypted = encrypter.encrypt(jsonString, iv: iv);
      
      // Return base64 encoded encrypted data
      return encrypted.base64;
    } catch (e) {
      debugPrint('Error encrypting QR data: $e');
      throw Exception('Failed to encrypt QR data');
    }
  }
  
  // Decrypt QR code data
  static Map<String, dynamic> decryptQRData(String encryptedData) {
    try {
      // Create encryption key
      final key = encrypt.Key.fromUtf8(_secretKey.padRight(32, '0'));
      final iv = encrypt.IV.fromLength(16);
      
      // Create encrypter
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      // Decrypt data
      final decrypted = encrypter.decrypt64(encryptedData, iv: iv);
      
      // Parse JSON string to Map
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error decrypting QR data: $e');
      throw Exception('Invalid QR code');
    }
  }
  
  // Generate QR code data
  static Map<String, dynamic> generateQRData({
    required int points,
    required String branch,
    required String id,
    required int expiryDuration,
  }) {
    return {
      'points': points,
      'branch': branch,
      'id': id,
      'expiryDuration': expiryDuration,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
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
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(timestamp)
        .add(Duration(days: expiryDuration));
    
    return DateTime.now().isBefore(expiryDate);
  }
}
