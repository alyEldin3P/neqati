import 'package:flutter/foundation.dart';
import 'package:neqati/core/utils/qr_encryption_tester.dart';

/// QR Test Runner - Easy way to run QR encryption tests
class QRTestRunner {
  /// Run all QR encryption tests
  static void runAllTests() {
    if (kDebugMode) {
      debugPrint('🧪 Starting QR Encryption Test Suite...\n');
      QREncryptionTester.runComprehensiveTests();
    }
  }
  
  /// Run quick test only
  static void runQuickTest() {
    if (kDebugMode) {
      QREncryptionTester.quickTest();
    }
  }
  
  /// Run basic tests only
  static void runBasicTests() {
    if (kDebugMode) {
      QREncryptionTester.runAllTests();
    }
  }
  
  /// Run performance test only
  static void runPerformanceTest() {
    if (kDebugMode) {
      QREncryptionTester.testPerformance();
    }
  }
}
