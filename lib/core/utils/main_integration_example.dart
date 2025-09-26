// Example of how to integrate QR encryption testing in main.dart
// 
// Add this import to your main.dart:
// import 'package:neqati/core/utils/qr_test_runner.dart';
//
// Then add one of these calls in your main() function:

/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize your services here...
  
  // 🧪 OPTION 1: Run comprehensive QR encryption tests
  QRTestRunner.runAllTests();
  
  // 🧪 OPTION 2: Run quick test only
  // QRTestRunner.runQuickTest();
  
  // 🧪 OPTION 3: Run basic tests only
  // QRTestRunner.runBasicTests();
  
  // 🧪 OPTION 4: Run performance test only
  // QRTestRunner.runPerformanceTest();
  
  runApp(MyApp());
}
*/

// Example of testing specific scenarios:
import 'package:flutter/foundation.dart';
import 'package:neqati/core/services/qr_encryption_service.dart';

class QRTestExamples {
  /// Test a specific QR code scenario
  static void testSpecificScenario() {
    if (kDebugMode) {
      debugPrint('🧪 Testing Specific QR Scenario...');
      
      // Create test QR data
      final qrData = QREncryptionService.generateQRData(
        points: 100,
        branch: 'الرياض',
        id: 'test_qr_001',
        expiryDuration: 30,
      );
      
      debugPrint('Generated QR Data: $qrData');
      
      // Encrypt the data
      final encrypted = QREncryptionService.encryptQRData(qrData);
      debugPrint('Encrypted: $encrypted');
      
      // Decrypt the data
      final decrypted = QREncryptionService.decryptQRData(encrypted);
      debugPrint('Decrypted: $decrypted');
      
      // Validate the data
      final isValid = QREncryptionService.validateQRData(decrypted);
      debugPrint('Is Valid: $isValid');
      
      debugPrint('✅ Specific Scenario Test Completed\n');
    }
  }
  
  /// Test QR code with your actual app data
  static void testWithRealData() {
    if (kDebugMode) {
      debugPrint('🧪 Testing with Real App Data...');
      
      // Example with real branch names from your app
      final branches = ['الرياض', 'جدة', 'الدمام', 'مكة', 'المدينة'];
      
      for (final branch in branches) {
        final qrData = QREncryptionService.generateQRData(
          points: 50,
          branch: branch,
          id: 'real_qr_${branch.hashCode}',
          expiryDuration: 7,
        );
        
        final encrypted = QREncryptionService.encryptQRData(qrData);
        final decrypted = QREncryptionService.decryptQRData(encrypted);
        final isValid = QREncryptionService.validateQRData(decrypted);
        
        debugPrint('Branch: $branch - Valid: $isValid');
      }
      
      debugPrint('✅ Real Data Test Completed\n');
    }
  }
}
