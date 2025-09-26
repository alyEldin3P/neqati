// import 'dart:io';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:neqati/core/models/scan.dart';
// import 'package:neqati/core/services/auth_service.dart';
// import 'package:neqati/core/services/user_service.dart';
// import 'package:neqati/core/services/qr_code_service.dart';
// import 'package:neqati/core/services/gift_service.dart';
// import 'package:neqati/core/services/offer_service.dart';
// import 'package:neqati/core/services/level_service.dart';
// import 'package:neqati/core/services/scan_service.dart';
// import 'package:neqati/core/services/storage_service.dart';

// /// Backward-compatible wrapper that delegates to the new feature-based services
// /// This allows existing code to continue working while we gradually migrate to the new services
// class SupabaseService {
//   final AuthService _authService;
//   final UserService _userService;
//   final QRCodeService _qrCodeService;
//   final GiftService _giftService;
//   final OfferService _offerService;
//   final LevelService _levelService;
//   final ScanService _scanService;
//   final StorageService _storageService;

//   SupabaseService({
//     required AuthService authService,
//     required UserService userService,
//     required QRCodeService qrCodeService,
//     required GiftService giftService,
//     required OfferService offerService,
//     required LevelService levelService,
//     required ScanService scanService,
//     required StorageService storageService,
//   }) : _authService = authService,
//        _userService = userService,
//        _qrCodeService = qrCodeService,
//        _giftService = giftService,
//        _offerService = offerService,
//        _levelService = levelService,
//        _scanService = scanService,
//        _storageService = storageService;

//   // Auth-related methods (delegate to AuthService)
//   User? get currentUser => _authService.currentUser;
//   Stream<AuthState> get authStateChanges => _authService.authStateChanges;
  
//   static Future<void> initialize({
//     required String supabaseUrl,
//     required String supabaseKey,
//   }) async {
//     return AuthService.initialize(
//       supabaseUrl: supabaseUrl,
//       supabaseKey: supabaseKey,
//     );
//   }

//   Future<void> registerUser({
//     required String name,
//     required String address,
//     required String nationalId,
//     required String phoneNumber,
//     required String email,
//     required String password,
//     required String position,
//   }) => _authService.registerUser(
//     name: name,
//     address: address,
//     nationalId: nationalId,
//     phoneNumber: phoneNumber,
//     email: email,
//     password: password,
//     position: position,
//   );

//   Future<AuthResponse> signInWithEmailAndPassword(String email, String password) =>
//       _authService.signInWithEmailAndPassword(email, password);

//   Future<bool> isUserVerified(String uid) => _authService.isUserVerified(uid);
//   Future<bool> isUserAdmin(String uid) => _authService.isUserAdmin(uid);
//   Future<void> resetPassword(String email) => _authService.resetPassword(email);
//   Future<void> signOut() => _authService.signOut();

//   Future<List<Map<String, dynamic>>> getPendingRegistrationRequests() =>
//       _authService.getPendingRegistrationRequests();
  
//   Future<void> approveRegistrationRequest(String requestId, String userId) =>
//       _authService.approveRegistrationRequest(requestId, userId);
  
//   Future<void> denyRegistrationRequest(String requestId, String userId) =>
//       _authService.denyRegistrationRequest(requestId, userId);

//   // User-related methods (delegate to UserService)
//   Future<Map<String, dynamic>?> getUserData(String uid) => _userService.getUserData(uid);
//   Future<void> updateUserData(String uid, Map<String, dynamic> data) =>
//       _userService.updateUserData(uid, data);
//   Future<void> updateUserPoints(String uid, int points) =>
//       _userService.updateUserPoints(uid, points);

//   Future<List<Map<String, dynamic>>> getPendingUsers() => _userService.getPendingUsers();
//   Future<List<Map<String, dynamic>>> getAllUsers() => _userService.getAllUsers();
//   Future<void> approveUser(String userId) => _userService.approveUser(userId);
//   Future<void> rejectUser(String userId) => _userService.rejectUser(userId);
//   Future<List<Map<String, dynamic>>> getUsersPaginated({int limit = 20, int offset = 0}) =>
//       _userService.getUsersPaginated(limit: limit, offset: offset);
//   Future<void> verifyUser(String userId) => _userService.verifyUser(userId);
//   Future<void> blockUser(String userId, bool isBlocked) =>
//       _userService.blockUser(userId, isBlocked);
//   Future<void> updateUserPointsAdmin(String userId, int points) =>
//       _userService.updateUserPointsAdmin(userId, points);
//   Future<void> deleteUser(String userId) => _userService.deleteUser(userId);
//   Future<String> createUser(Map<String, dynamic> userData) =>
//       _userService.createUser(userData);

//   // QR Code-related methods (delegate to QRCodeService)
//   Future<Map<String, dynamic>> createQRCode({
//     required int points,
//     required String branch,
//     required int expiryDuration,
//     required String encryptedPayload,
//   }) => _qrCodeService.createQRCode(
//     points: points,
//     branch: branch,
//     expiryDuration: expiryDuration,
//     encryptedPayload: encryptedPayload,
//   );

//   Future<Map<String, dynamic>?> getQRCodeData(String qrId) =>
//       _qrCodeService.getQRCodeData(qrId);
//   Future<bool> scanQRCode(String qrId, String userId) =>
//       _qrCodeService.scanQRCode(qrId, userId);
//   Future<Map<String, dynamic>> recordQRScan({
//     required String userId,
//     required Map<String, dynamic> qrData,
//   }) => _qrCodeService.recordQRScan(userId: userId, qrData: qrData);

//   Future<List<Map<String, dynamic>>> getAllQRCodes() => _qrCodeService.getAllQRCodes();
//   Future<List<Map<String, dynamic>>> getQRCodesPaginated({
//     int limit = 10,
//     int offset = 0,
//     String? searchQuery,
//   }) => _qrCodeService.getQRCodesPaginated(
//     limit: limit,
//     offset: offset,
//     searchQuery: searchQuery,
//   );
//   Future<int> getQRCodesCount() => _qrCodeService.getQRCodesCount();
//   Future<String> createQRCodeAdmin({
//     required int points,
//     required String branch,
//     required int expiryDuration,
//   }) => _qrCodeService.createQRCodeAdmin(
//     points: points,
//     branch: branch,
//     expiryDuration: expiryDuration,
//   );
//   Future<void> deleteQRCode(String qrCodeId) => _qrCodeService.deleteQRCode(qrCodeId);

//   // Gift-related methods (delegate to GiftService)
//   Future<List<Map<String, dynamic>>> getAvailableGifts() => _giftService.getAvailableGifts();
//   Future<bool> requestGift(String userId, String giftId) =>
//       _giftService.requestGift(userId, giftId);
//   Future<Map<String, dynamic>> redeemGift(String giftId) => _giftService.redeemGift(giftId);

//   Future<List<Map<String, dynamic>>> getAllGifts() => _giftService.getAllGifts();
//   Future<String> createGift({
//     required String name,
//     required int points,
//     required int stock,
//     required String imageUrl,
//   }) => _giftService.createGift(
//     name: name,
//     points: points,
//     stock: stock,
//     imageUrl: imageUrl,
//   );
//   Future<void> updateGift({
//     required String giftId,
//     required Map<String, dynamic> giftData,
//   }) => _giftService.updateGift(giftId: giftId, giftData: giftData);
//   Future<void> deleteGift(String giftId) => _giftService.deleteGift(giftId);
//   Future<Map<String, dynamic>?> getGiftById(String giftId) =>
//       _giftService.getGiftById(giftId);
//   Future<List<Map<String, dynamic>>> getGiftRequests(String giftId) =>
//       _giftService.getGiftRequests(giftId);
//   Future<void> updateGiftRequestStatus(String requestId, String status) =>
//       _giftService.updateGiftRequestStatus(requestId, status);

//   // Offer-related methods (delegate to OfferService)
//   Future<List<Map<String, dynamic>>> getOffers() => _offerService.getOffers();
//   Future<List<dynamic>> getActiveOffers() => _offerService.getActiveOffers();
//   Future<String> createOffer({
//     required String title,
//     required String description,
//     required String imageUrl,
//   }) => _offerService.createOffer(
//     title: title,
//     description: description,
//     imageUrl: imageUrl,
//   );
//   Future<void> updateOffer({
//     required String offerId,
//     required Map<String, dynamic> offerData,
//   }) => _offerService.updateOffer(offerId: offerId, offerData: offerData);
//   Future<void> deleteOffer(String offerId) => _offerService.deleteOffer(offerId);
//   Future<Map<String, dynamic>?> getOfferById(String offerId) =>
//       _offerService.getOfferById(offerId);

//   // Level-related methods (delegate to LevelService)
//   Future<List<Map<String, dynamic>>> getLevels() => _levelService.getLevels();
//   Future<String> createLevel(Map<String, dynamic> levelData) =>
//       _levelService.createLevel(levelData);
//   Future<Map<String, dynamic>?> getLevelById(String levelId) =>
//       _levelService.getLevelById(levelId);
//   Future<void> updateLevel({
//     required String levelId,
//     required Map<String, dynamic> levelData,
//   }) => _levelService.updateLevel(levelId: levelId, levelData: levelData);
//   Future<void> deleteLevel(String levelId) => _levelService.deleteLevel(levelId);

//   // Scan-related methods (delegate to ScanService)
//   Future<List<Map<String, dynamic>>> getUserScanHistory(String userId) =>
//       _scanService.getUserScanHistory(userId);
//   Future<List<Map<String, dynamic>>> getRecentScans(int days) =>
//       _scanService.getRecentScans(days);
//   Future<List<Map<String, dynamic>>> getScansPaginated({
//     int limit = 20,
//     int offset = 0,
//   }) => _scanService.getScansPaginated(limit: limit, offset: offset);

//   Future<List<Scan>> getScansTyped({int limit = 20, int offset = 0}) =>
//       _scanService.getScansTyped(limit: limit, offset: offset);
//   Future<List<Scan>> getUserScanHistoryTyped(String userId) =>
//       _scanService.getUserScanHistoryTyped(userId);
//   Future<List<Scan>> getRecentScansTyped(int days) =>
//       _scanService.getRecentScansTyped(days);
//   Future<Scan?> getScanById(String scanId) => _scanService.getScanById(scanId);

//   // Storage-related methods (delegate to StorageService)
//   Future<String> uploadImage(File file, String path) =>
//       _storageService.uploadImage(file, path);
// }
