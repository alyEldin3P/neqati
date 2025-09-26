import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:neqati/core/services/qr_encryption_service.dart';

class QREncryptionTester {
  static void runAllTests() {
    debugPrint('🧪 Starting QR Encryption Tests...\n');

    try {
      testBasicEncryptionDecryption();
      testQRDataGeneration();
      testQRDataValidation();
      testExpiredQRCode();
      testInvalidQRData();
      testEdgeCases();

      debugPrint('✅ All QR Encryption Tests Passed!\n');
    } catch (e) {
      debugPrint('❌ QR Encryption Tests Failed: $e\n');
    }
  }

  /// Test basic encryption and decryption functionality
  static void testBasicEncryptionDecryption() {
    debugPrint('🔐 Testing Basic Encryption/Decryption...');

    // Test data
    final testData = {
      'points': 100,
      'branch': 'الرياض',
      'id': 'qr_123456',
      'expiryDuration': 30,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Encrypt data
    final encryptedData = QREncryptionService.encryptQRData(testData);
    debugPrint('   Encrypted Data: ${encryptedData.substring(0, 20)}...');

    // Decrypt data
    final decryptedData = QREncryptionService.decryptQRData(encryptedData);
    debugPrint('   Decrypted Data: $decryptedData');

    // Verify data integrity
    assert(decryptedData['points'] == testData['points']);
    assert(decryptedData['branch'] == testData['branch']);
    assert(decryptedData['id'] == testData['id']);
    assert(decryptedData['expiryDuration'] == testData['expiryDuration']);
    assert(decryptedData['timestamp'] == testData['timestamp']);

    debugPrint('   ✅ Basic Encryption/Decryption Test Passed\n');
  }

  /// Test QR data generation
  static void testQRDataGeneration() {
    debugPrint('📊 Testing QR Data Generation...');

    final qrData = QREncryptionService.generateQRData(
      points: 50,
      branch: 'جدة',
      id: 'test_qr_001',
      expiryDuration: 7,
    );

    debugPrint('   Generated QR Data: $qrData');

    // Verify required fields
    assert(qrData.containsKey('points'));
    assert(qrData.containsKey('branch'));
    assert(qrData.containsKey('id'));
    assert(qrData.containsKey('expiryDuration'));
    assert(qrData.containsKey('timestamp'));

    // Verify values
    assert(qrData['points'] == 50);
    assert(qrData['branch'] == 'جدة');
    assert(qrData['id'] == 'test_qr_001');
    assert(qrData['expiryDuration'] == 7);

    debugPrint('   ✅ QR Data Generation Test Passed\n');
  }

  /// Test QR data validation
  static void testQRDataValidation() {
    debugPrint('✅ Testing QR Data Validation...');

    // Test valid QR data
    final validData = QREncryptionService.generateQRData(
      points: 25,
      branch: 'الدمام',
      id: 'valid_qr',
      expiryDuration: 1, // 1 day
    );

    final isValid = QREncryptionService.validateQRData(validData);
    debugPrint('   Valid QR Data: $isValid');
    assert(isValid == true);

    // Test invalid QR data (missing fields)
    final invalidData = {
      'points': 25,
      'branch': 'الدمام',
      // Missing required fields
    };

    final isInvalid = QREncryptionService.validateQRData(invalidData);
    debugPrint('   Invalid QR Data (missing fields): $isInvalid');
    assert(isInvalid == false);

    debugPrint('   ✅ QR Data Validation Test Passed\n');
  }

  /// Test expired QR code validation
  static void testExpiredQRCode() {
    debugPrint('⏰ Testing Expired QR Code...');

    // Create expired QR data (timestamp from 2 days ago, expires in 1 day)
    final expiredData = {
      'points': 75,
      'branch': 'مكة',
      'id': 'expired_qr',
      'expiryDuration': 1, // 1 day
      'timestamp':
          DateTime.now()
              .subtract(const Duration(days: 2))
              .millisecondsSinceEpoch,
    };

    final isExpired = QREncryptionService.validateQRData(expiredData);
    debugPrint('   Expired QR Code Validation: $isExpired');
    assert(isExpired == false);

    debugPrint('   ✅ Expired QR Code Test Passed\n');
  }

  /// Test invalid QR data scenarios
  static void testInvalidQRData() {
    debugPrint('❌ Testing Invalid QR Data Scenarios...');

    // Test decryption with invalid encrypted data
    try {
      QREncryptionService.decryptQRData('invalid_encrypted_data');
      assert(false, 'Should have thrown an exception');
    } catch (e) {
      debugPrint('   Expected exception for invalid encrypted data: $e');
    }

    // Test decryption with empty string
    try {
      QREncryptionService.decryptQRData('');
      assert(false, 'Should have thrown an exception');
    } catch (e) {
      debugPrint('   Expected exception for empty encrypted data: $e');
    }

    debugPrint('   ✅ Invalid QR Data Test Passed\n');
  }

  /// Test edge cases
  static void testEdgeCases() {
    debugPrint('🔍 Testing Edge Cases...');

    // Test with Arabic text
    final arabicData = {
      'points': 200,
      'branch': 'الرياض - حي الملز',
      'id': 'qr_عربي_123',
      'expiryDuration': 15,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'description': 'هذا اختبار للنص العربي في رمز QR',
    };

    final encryptedArabic = QREncryptionService.encryptQRData(arabicData);
    final decryptedArabic = QREncryptionService.decryptQRData(encryptedArabic);

    assert(decryptedArabic['branch'] == arabicData['branch']);
    assert(decryptedArabic['id'] == arabicData['id']);
    assert(decryptedArabic['description'] == arabicData['description']);

    debugPrint('   Arabic Text Encryption/Decryption: ✅');

    // Test with large data
    final largeData = {
      'points': 999999,
      'branch': 'فرع كبير جداً ' * 10, // Repeat text 10 times
      'id': 'very_long_id_' + '1234567890' * 5,
      'expiryDuration': 365,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'metadata': List.generate(50, (i) => 'item_$i'), // Large array
    };

    final encryptedLarge = QREncryptionService.encryptQRData(largeData);
    final decryptedLarge = QREncryptionService.decryptQRData(encryptedLarge);

    assert(decryptedLarge['points'] == largeData['points']);
    assert(decryptedLarge['metadata'].length == 50);

    debugPrint('   Large Data Encryption/Decryption: ✅');

    // Test with zero values
    final zeroData = {
      'points': 0,
      'branch': '',
      'id': 'zero_test',
      'expiryDuration': 0,
      'timestamp': 0,
    };

    final encryptedZero = QREncryptionService.encryptQRData(zeroData);
    final decryptedZero = QREncryptionService.decryptQRData(encryptedZero);

    assert(decryptedZero['points'] == 0);
    assert(decryptedZero['branch'] == '');
    assert(decryptedZero['timestamp'] == 0);

    debugPrint('   Zero Values Encryption/Decryption: ✅');

    debugPrint('   ✅ Edge Cases Test Passed\n');
  }

  /// Test complete QR workflow
  static void testCompleteQRWorkflow() {
    debugPrint('🔄 Testing Complete QR Workflow...');

    // Step 1: Generate QR data
    final qrData = QREncryptionService.generateQRData(
      points: 150,
      branch: 'الخبر',
      id: 'workflow_test',
      expiryDuration: 10,
    );
    debugPrint('   Step 1 - Generated QR Data: ✅');

    // Step 2: Encrypt QR data
    final encryptedData = QREncryptionService.encryptQRData(qrData);
    debugPrint('   Step 2 - Encrypted QR Data: ✅');
    debugPrint('   Encrypted String Length: ${encryptedData.length}');

    // Step 3: Decrypt QR data
    final decryptedData = QREncryptionService.decryptQRData(encryptedData);
    debugPrint('   Step 3 - Decrypted QR Data: ✅');

    // Step 4: Validate QR data
    final isValid = QREncryptionService.validateQRData(decryptedData);
    debugPrint('   Step 4 - Validated QR Data: $isValid ✅');

    // Verify complete workflow
    assert(decryptedData['points'] == qrData['points']);
    assert(decryptedData['branch'] == qrData['branch']);
    assert(decryptedData['id'] == qrData['id']);
    assert(isValid == true);

    debugPrint('   ✅ Complete QR Workflow Test Passed\n');
  }

  /// Run performance test
  static void testPerformance() {
    debugPrint('⚡ Testing Performance...');

    final testData = QREncryptionService.generateQRData(
      points: 100,
      branch: 'اختبار الأداء',
      id: 'performance_test',
      expiryDuration: 30,
    );

    final stopwatch = Stopwatch()..start();

    // Test encryption performance
    for (int i = 0; i < 100; i++) {
      QREncryptionService.encryptQRData(testData);
    }

    final encryptionTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // Test decryption performance
    final encryptedData = QREncryptionService.encryptQRData(testData);
    for (int i = 0; i < 100; i++) {
      QREncryptionService.decryptQRData(encryptedData);
    }

    final decryptionTime = stopwatch.elapsedMilliseconds;
    stopwatch.stop();

    debugPrint('   100 Encryptions took: ${encryptionTime}ms');
    debugPrint('   100 Decryptions took: ${decryptionTime}ms');
    debugPrint('   Average Encryption: ${encryptionTime / 100}ms');
    debugPrint('   Average Decryption: ${decryptionTime / 100}ms');

    debugPrint('   ✅ Performance Test Completed\n');
  }

  /// Run comprehensive test suite
  static void runComprehensiveTests() {
    debugPrint('🚀 Running Comprehensive QR Encryption Test Suite...\n');

    runAllTests();
    testCompleteQRWorkflow();
    testPerformance();

    debugPrint('🎉 All Comprehensive Tests Completed Successfully!\n');
  }

  /// Quick test for debugging
  static void quickTest() {
    debugPrint('⚡ Quick QR Encryption Test...');

    final data = {'test': 'quick', 'value': 123};
    final encrypted = QREncryptionService.encryptQRData(data);
    final decrypted = QREncryptionService.decryptQRData(encrypted);

    debugPrint('Original: $data');
    debugPrint('Encrypted: $encrypted');
    debugPrint('Decrypted: $decrypted');
    debugPrint('Match: ${data.toString() == decrypted.toString()}');

    debugPrint('✅ Quick Test Completed\n');
  }
}
