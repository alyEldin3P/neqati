import 'package:get_it/get_it.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';
import 'navigation_service.dart';
import 'qr_encryption_service.dart';

class DependencyInjector {
  static final GetIt _getIt = GetIt.instance;
  static bool _isInitialized = false;

  // Singleton instance
  static final DependencyInjector _instance = DependencyInjector._internal();
  
  factory DependencyInjector() {
    return _instance;
  }
  
  DependencyInjector._internal();

  // Initialize all dependencies
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Register services
    _getIt.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
    _getIt.registerLazySingleton<FirestoreService>(() => FirestoreService());
    _getIt.registerLazySingleton<NavigationService>(() => NavigationService());
    _getIt.registerLazySingleton<QREncryptionService>(() => QREncryptionService());

    _isInitialized = true;
  }

  // Service getters
  FirebaseAuthService get authService => _getIt<FirebaseAuthService>();
  FirestoreService get firestoreService => _getIt<FirestoreService>();
  NavigationService get navigationService => _getIt<NavigationService>();
  QREncryptionService get qrEncryptionService => _getIt<QREncryptionService>();
  
  // Static resolve method for direct access
  static T resolve<T extends Object>() {
    return _getIt.get<T>();
  }
}
