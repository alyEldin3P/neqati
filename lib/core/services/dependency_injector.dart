import 'package:get_it/get_it.dart';
import 'dart:developer' as dev;
import 'auth_service.dart';
import 'user_service.dart';
import 'qr_code_service.dart';
import 'gift_service.dart';
import 'offer_service.dart';
import 'level_service.dart';
import 'scan_service.dart';
import 'storage_service.dart';
import 'supabase_service.dart';
import 'navigation_service.dart';
import 'qr_encryption_service.dart';
import 'session_manager.dart';
import 'fcm_notification_service.dart';

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

    // Register feature-based services
    _getIt.registerLazySingleton<AuthService>(() => AuthService());
    _getIt.registerLazySingleton<UserService>(() => UserService());
    _getIt.registerLazySingleton<QRCodeService>(() => QRCodeService());
    _getIt.registerLazySingleton<GiftService>(() => GiftService());
    _getIt.registerLazySingleton<OfferService>(() => OfferService());
    _getIt.registerLazySingleton<LevelService>(() => LevelService());
    _getIt.registerLazySingleton<ScanService>(() => ScanService());
    _getIt.registerLazySingleton<StorageService>(() => StorageService());

    // // Register backward-compatible wrapper
    // _getIt.registerLazySingleton<SupabaseService>(() => SupabaseService(
    //   authService: _getIt<AuthService>(),
    //   userService: _getIt<UserService>(),
    //   qrCodeService: _getIt<QRCodeService>(),
    //   giftService: _getIt<GiftService>(),
    //   offerService: _getIt<OfferService>(),
    //   levelService: _getIt<LevelService>(),
    //   scanService: _getIt<ScanService>(),
    //   storageService: _getIt<StorageService>(),
    // ));

    // Register other services
    _getIt.registerLazySingleton<NavigationService>(() => NavigationService());
    _getIt.registerLazySingleton<QREncryptionService>(
      () => QREncryptionService(),
    );

    // Register and initialize SessionManager
    _getIt.registerLazySingleton<SessionManager>(() => SessionManager.instance);
    await SessionManager.instance.initialize();

    // Register and initialize FCMNotificationService
    dev.log('DependencyInjector: Registering FCMNotificationService...');
    // _getIt.registerLazySingleton<FCMNotificationService>(() => FCMNotificationService());
    dev.log('DependencyInjector: FCMNotificationService registered');

    dev.log('DependencyInjector: Initializing FCMNotificationService...');
    // await _getIt<FCMNotificationService>().initialize();
    dev.log(
      'DependencyInjector: FCMNotificationService initialized successfully',
    );

    _isInitialized = true;
  }

  // Service getters
  AuthService get authService => _getIt<AuthService>();
  UserService get userService => _getIt<UserService>();
  QRCodeService get qrCodeService => _getIt<QRCodeService>();
  GiftService get giftService => _getIt<GiftService>();
  OfferService get offerService => _getIt<OfferService>();
  LevelService get levelService => _getIt<LevelService>();
  ScanService get scanService => _getIt<ScanService>();
  StorageService get storageService => _getIt<StorageService>();

  // // Backward-compatible wrapper
  // SupabaseService get supabaseService => _getIt<SupabaseService>();

  NavigationService get navigationService => _getIt<NavigationService>();
  QREncryptionService get qrEncryptionService => _getIt<QREncryptionService>();
  SessionManager get sessionManager => _getIt<SessionManager>();
  // FCMNotificationService get fcmNotificationService =>
  //     _getIt<FCMNotificationService>();

  // Static resolve method for direct access
  static T resolve<T extends Object>() {
    return _getIt.get<T>();
  }
}
