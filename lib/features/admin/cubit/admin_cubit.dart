import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/services/firestore_service.dart';
import 'package:neqati/features/admin/cubit/admin_state.dart';
import 'package:neqati/features/admin/model/admin_stats.dart';
import 'package:neqati/features/auth/model/user.dart';

class AdminCubit extends Cubit<AdminState> {
  final FirestoreService _firestoreService;

  AdminCubit({required FirestoreService firestoreService})
    : _firestoreService = firestoreService,
      super(AdminInitial());

  // Load admin dashboard statistics
  Future<void> loadAdminStats() async {
    try {
      emit(AdminLoading());

      // Get counts from Firestore collections
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final pendingUsersSnapshot =
          await FirebaseFirestore.instance.collection('users').where('isVerified', isEqualTo: false).get();
      final scansSnapshot = await FirebaseFirestore.instance.collection('scans').get();
      final qrCodesSnapshot = await FirebaseFirestore.instance.collection('qrCodes').get();
      final giftsSnapshot = await FirebaseFirestore.instance.collection('gifts').get();
      final offersSnapshot = await FirebaseFirestore.instance.collection('offers').get();
      final pendingGiftRequestsSnapshot =
          await FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'pending').get();

      final stats = AdminStats(
        totalUsers: usersSnapshot.docs.length,
        totalPendingUsers: pendingUsersSnapshot.docs.length,
        totalScans: scansSnapshot.docs.length,
        totalQrCodes: qrCodesSnapshot.docs.length,
        totalGifts: giftsSnapshot.docs.length,
        totalOffers: offersSnapshot.docs.length,
        totalPendingGiftRequests: pendingGiftRequestsSnapshot.docs.length,
      );

      emit(AdminStatsLoaded(stats));
    } catch (e) {
      emit(AdminError('Failed to load admin statistics: ${e.toString()}'));
    }
  }

  // User Management
  Future<void> loadUsers({int limit = 20, DocumentSnapshot? lastDocument}) async {
    try {
      emit(AdminLoading());

      Query query = FirebaseFirestore.instance.collection('users').limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final users =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return AppUser.fromFirestore(data, doc.id);
          }).toList();

      final hasMore = snapshot.docs.length == limit;

      emit(UsersLoaded(users, hasMore: hasMore));
    } catch (e) {
      emit(AdminError('Failed to load users: ${e.toString()}'));
    }
  }

  Future<void> loadPendingUsers() async {
    try {
      emit(AdminLoading());

      final snapshot = await FirebaseFirestore.instance.collection('users').where('isVerified', isEqualTo: false).get();

      final pendingUsers =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return AppUser.fromFirestore(data, doc.id);
          }).toList();

      emit(PendingUsersLoaded(pendingUsers));
    } catch (e) {
      emit(AdminError('Failed to load pending users: ${e.toString()}'));
    }
  }

  Future<void> verifyUser(String userId) async {
    try {
      emit(AdminLoading());

      await FirebaseFirestore.instance.collection('users').doc(userId).update({'isVerified': true});

      emit(UserActionSuccess(message: 'تم تفعيل المستخدم بنجاح', userId: userId, action: 'verify'));
    } catch (e) {
      emit(AdminError('Failed to verify user: ${e.toString()}'));
    }
  }

  Future<void> blockUser(String userId, bool isBlocked) async {
    try {
      emit(AdminLoading());

      await FirebaseFirestore.instance.collection('users').doc(userId).update({'isBlocked': isBlocked});

      final message = isBlocked ? 'تم حظر المستخدم بنجاح' : 'تم إلغاء حظر المستخدم بنجاح';

      emit(UserActionSuccess(message: message, userId: userId, action: isBlocked ? 'block' : 'unblock'));
    } catch (e) {
      emit(AdminError('Failed to update user block status: ${e.toString()}'));
    }
  }

  Future<void> updateUserPoints(String userId, int points) async {
    try {
      emit(AdminLoading());

      // Get current points
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final currentPoints = userData['points'] as int? ?? 0;

      // Update points
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'points': currentPoints + points});

      emit(UserActionSuccess(message: 'تم تحديث نقاط المستخدم بنجاح', userId: userId, action: 'update_points'));
    } catch (e) {
      emit(AdminError('Failed to update user points: ${e.toString()}'));
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      emit(AdminLoading());

      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      emit(UserActionSuccess(message: 'تم حذف المستخدم بنجاح', userId: userId, action: 'delete'));
    } catch (e) {
      emit(AdminError('Failed to delete user: ${e.toString()}'));
    }
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      emit(AdminLoading());

      // Set default values
      userData['isVerified'] = true;
      userData['isBlocked'] = false;
      userData['isAdmin'] = false;
      userData['points'] = 0;
      userData['level'] = 'مبتدئ';
      userData['createdAt'] = FieldValue.serverTimestamp();

      // Create user document
      final docRef = await FirebaseFirestore.instance.collection('users').add(userData);

      emit(UserActionSuccess(message: 'تم إنشاء المستخدم بنجاح', userId: docRef.id, action: 'create'));
    } catch (e) {
      emit(AdminError('Failed to create user: ${e.toString()}'));
    }
  }

  // QR Code Management
  Future<void> loadQRCodes({int limit = 10, String? lastDocId, String? searchQuery}) async {
    try {
      emit(AdminLoading());

      Query query = FirebaseFirestore.instance.collection('qrCodes').orderBy('createdAt', descending: true);

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Search by QR code ID or branch
        query = query
            .where('id', isGreaterThanOrEqualTo: searchQuery)
            .where('id', isLessThanOrEqualTo: searchQuery + '\uf8ff');
      }

      // Apply pagination
      query = query.limit(limit);

      if (lastDocId != null) {
        final lastDoc = await FirebaseFirestore.instance.collection('qrCodes').doc(lastDocId).get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      final qrCodes = snapshot.docs.map((doc) => doc.data()).toList();
      final totalQrCodesSnapshot = await FirebaseFirestore.instance.collection('qrCodes').count().get();
      final totalQrCodes = totalQrCodesSnapshot.count ?? 0;

      emit(QrCodesLoaded(qrCodes, totalQrCodes));
    } catch (e) {
      emit(AdminError('Failed to load QR codes: ${e.toString()}'));
    }
  }

  Future<void> createQRCode({required int points, required String branch, required int expiryDuration}) async {
    try {
      emit(AdminLoading());

      // Generate a unique QR code ID
      final qrCodeRef = FirebaseFirestore.instance.collection('qrCodes').doc();
      final qrCodeId = qrCodeRef.id;

      // Create expiry date (current date + expiryDuration days)
      final expiryDate = DateTime.now().add(Duration(days: expiryDuration));

      // Create QR code data
      final qrCodeData = 'QR_$qrCodeId:$points:$branch';

      // Save QR code to Firestore
      await qrCodeRef.set({
        'id': qrCodeId,
        'points': points,
        'branch': branch,
        'data': qrCodeData,
        'expiryDate': expiryDate,
        'isUsed': false,
        'createdAt': FieldValue.serverTimestamp(),
        'usedBy': null,
        'usedAt': null,
      });

      emit(QrCodeCreated(qrCodeId: qrCodeId, qrCodeData: qrCodeData));
    } catch (e) {
      emit(AdminError('Failed to create QR code: ${e.toString()}'));
    }
  }

  Future<void> deleteQRCode(String qrCodeId) async {
    try {
      emit(AdminLoading());

      // Delete QR code from Firestore
      await FirebaseFirestore.instance.collection('qrCodes').doc(qrCodeId).delete();

      emit(QrCodeDeleted(qrCodeId: qrCodeId));
    } catch (e) {
      emit(AdminError('Failed to delete QR code: ${e.toString()}'));
    }
  }

  // Gift Management
  Future<void> loadGifts() async {
    try {
      emit(AdminLoading());

      final snapshot = await FirebaseFirestore.instance.collection('gifts').get();
      final gifts = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();

      emit(GiftsLoaded(gifts));
    } catch (e) {
      emit(AdminError('Failed to load gifts: ${e.toString()}'));
    }
  }

  Future<void> createGift({
    required String name,
    required int points,
    required int stock,
    required String imageUrl,
  }) async {
    try {
      emit(AdminLoading());

      final giftData = {
        'name': name,
        'points': points,
        'stock': stock,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance.collection('gifts').add(giftData);

      emit(GiftActionSuccess(message: 'تم إنشاء الهدية بنجاح', giftId: docRef.id, action: 'create'));
    } catch (e) {
      emit(AdminError('Failed to create gift: ${e.toString()}'));
    }
  }

  Future<void> updateGift({required String giftId, required Map<String, dynamic> giftData}) async {
    try {
      emit(AdminLoading());

      await FirebaseFirestore.instance.collection('gifts').doc(giftId).update(giftData);

      emit(GiftActionSuccess(message: 'تم تحديث الهدية بنجاح', giftId: giftId, action: 'update'));
    } catch (e) {
      emit(AdminError('Failed to update gift: ${e.toString()}'));
    }
  }

  Future<void> deleteGift(String giftId) async {
    try {
      emit(AdminLoading());

      // Get gift data to delete image if exists
      final giftDoc = await FirebaseFirestore.instance.collection('gifts').doc(giftId).get();
      final giftData = giftDoc.data() as Map<String, dynamic>?;

      if (giftData != null && giftData.containsKey('imageUrl')) {
        final imageUrl = giftData['imageUrl'] as String;
        if (imageUrl.startsWith('gs://') || imageUrl.contains('firebase')) {
          try {
            // Extract storage path from URL
            final ref = FirebaseStorage.instance.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            // Continue even if image deletion fails
            print('Failed to delete gift image: ${e.toString()}');
          }
        }
      }

      await FirebaseFirestore.instance.collection('gifts').doc(giftId).delete();

      emit(GiftActionSuccess(message: 'تم حذف الهدية بنجاح', giftId: giftId, action: 'delete'));
    } catch (e) {
      emit(AdminError('Failed to delete gift: ${e.toString()}'));
    }
  }
  
  // Get gift by ID
  Future<Map<String, dynamic>?> getGiftById(String giftId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('gifts').doc(giftId).get();
      if (!doc.exists) return null;
      
      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    } catch (e) {
      emit(AdminError('Failed to get gift: ${e.toString()}'));
      return null;
    }
  }
  
  // Get gift requests
  Future<List<Map<String, dynamic>>> getGiftRequests(String giftId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('giftRequests')
          .where('giftId', isEqualTo: giftId)
          .orderBy('requestDate', descending: true)
          .get();
      
      final requests = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        
        // Get user details
        String? userName;
        String? userPhone;
        
        if (userId != null) {
          try {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>?;
              userName = userData?['name'] as String?;
              userPhone = userData?['phone'] as String?;
            }
          } catch (e) {
            print('Error fetching user data: ${e.toString()}');
          }
        }
        
        requests.add({
          'id': doc.id,
          ...data,
          'userName': userName ?? 'مستخدم',
          'userPhone': userPhone ?? '-',
        });
      }
      
      return requests;
    } catch (e) {
      emit(AdminError('Failed to get gift requests: ${e.toString()}'));
      return [];
    }
  }
  
  // Update gift request status
  Future<void> updateGiftRequestStatus(String requestId, String status) async {
    try {
      emit(AdminLoading());
      
      await FirebaseFirestore.instance.collection('giftRequests').doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      emit(AdminInitial());
    } catch (e) {
      emit(AdminError('Failed to update request status: ${e.toString()}'));
    }
  }

  // Offer Management
  Future<void> loadOffers() async {
    try {
      emit(AdminLoading());

      final snapshot = await FirebaseFirestore.instance.collection('offers').get();
      final offers = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();

      emit(OffersLoaded(offers));
    } catch (e) {
      emit(AdminError('Failed to load offers: ${e.toString()}'));
    }
  }

  Future<void> createOffer({required String title, required String description, required String imageUrl}) async {
    try {
      emit(AdminLoading());

      final offerData = {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance.collection('offers').add(offerData);

      emit(OfferActionSuccess(message: 'تم إنشاء العرض بنجاح', offerId: docRef.id, action: 'create'));
    } catch (e) {
      emit(AdminError('Failed to create offer: ${e.toString()}'));
    }
  }

  Future<void> updateOffer({required String offerId, required Map<String, dynamic> offerData}) async {
    try {
      emit(AdminLoading());

      await FirebaseFirestore.instance.collection('offers').doc(offerId).update(offerData);

      emit(OfferActionSuccess(message: 'تم تحديث العرض بنجاح', offerId: offerId, action: 'update'));
    } catch (e) {
      emit(AdminError('Failed to update offer: ${e.toString()}'));
    }
  }

  Future<void> deleteOffer(String offerId) async {
    try {
      emit(AdminLoading());

      // Get offer data to delete image if exists
      final offerDoc = await FirebaseFirestore.instance.collection('offers').doc(offerId).get();
      final offerData = offerDoc.data() as Map<String, dynamic>?;

      if (offerData != null && offerData.containsKey('imageUrl')) {
        final imageUrl = offerData['imageUrl'] as String;
        if (imageUrl.startsWith('gs://') || imageUrl.contains('firebase')) {
          try {
            // Extract storage path from URL
            final ref = FirebaseStorage.instance.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            // Continue even if image deletion fails
            print('Failed to delete offer image: ${e.toString()}');
          }
        }
      }

      await FirebaseFirestore.instance.collection('offers').doc(offerId).delete();

      emit(OfferActionSuccess(message: 'تم حذف العرض بنجاح', offerId: offerId, action: 'delete'));
    } catch (e) {
      emit(AdminError('Failed to delete offer: ${e.toString()}'));
    }
  }
  
  // Get offer by ID
  Future<Map<String, dynamic>?> getOfferById(String offerId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('offers').doc(offerId).get();
      if (!doc.exists) return null;
      
      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    } catch (e) {
      emit(AdminError('Failed to get offer: ${e.toString()}'));
      return null;
    }
  }

  // Level Management
  Future<void> loadLevels() async {
    try {
      emit(AdminLoading());

      final snapshot = await FirebaseFirestore.instance.collection('levels').orderBy('startingPoints').get();

      final levels = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      emit(LevelsLoaded(levels));
    } catch (e) {
      emit(AdminError('Failed to load levels: ${e.toString()}'));
    }
  }
  
  Future<void> createLevel(Map<String, dynamic> levelData) async {
    try {
      emit(AdminLoading());
      
      final docRef = await FirebaseFirestore.instance.collection('levels').add(levelData);
      
      emit(LevelActionSuccess(
        message: 'تم إنشاء المستوى بنجاح',
        levelId: docRef.id,
        action: 'create',
      ));
    } catch (e) {
      emit(AdminError('Failed to create level: ${e.toString()}'));
    }
  }
  
  Future<Map<String, dynamic>?> getLevelById(String levelId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('levels').doc(levelId).get();
      if (!doc.exists) return null;
      
      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    } catch (e) {
      emit(AdminError('Failed to get level: ${e.toString()}'));
      return null;
    }
  }
  
  Future<void> updateLevel({required String levelId, required Map<String, dynamic> levelData}) async {
    try {
      emit(AdminLoading());
      
      await FirebaseFirestore.instance.collection('levels').doc(levelId).update(levelData);
      
      emit(LevelActionSuccess(
        message: 'تم تحديث المستوى بنجاح',
        levelId: levelId,
        action: 'update',
      ));
    } catch (e) {
      emit(AdminError('Failed to update level: ${e.toString()}'));
    }
  }
  
  Future<void> deleteLevel(String levelId) async {
    try {
      emit(AdminLoading());

      // Get level data to delete image if exists
      final levelDoc = await FirebaseFirestore.instance.collection('levels').doc(levelId).get();
      final levelData = levelDoc.data();

      if (levelData != null && levelData.containsKey('imageUrl')) {
        final imageUrl = levelData['imageUrl'] as String;
        if (imageUrl.startsWith('gs://') || imageUrl.contains('firebase')) {
          try {
            // Extract storage path from URL
            final ref = FirebaseStorage.instance.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            // Continue even if image deletion fails
            print('Failed to delete level image: ${e.toString()}');
          }
        }
      }

      await FirebaseFirestore.instance.collection('levels').doc(levelId).delete();

      emit(LevelActionSuccess(
        message: 'تم حذف المستوى بنجاح',
        levelId: levelId,
        action: 'delete',
      ));
    } catch (e) {
      emit(AdminError('Failed to delete level: ${e.toString()}'));
    }
  }


  // Scan History
  Future<void> loadScans({int limit = 20, DocumentSnapshot? lastDocument}) async {
    try {
      emit(AdminLoading());

      Query query = FirebaseFirestore.instance.collection('scans').orderBy('scanDate', descending: true).limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      // Get all user IDs from scans
      final userIds =
          snapshot.docs
              .map((doc) => (doc.data() as Map<String, dynamic>)['userId'] as String?)
              .where((id) => id != null)
              .toSet();

      // Get user data in batch
      final userDocs = await Future.wait(
        userIds.map((id) => FirebaseFirestore.instance.collection('users').doc(id).get()),
      );

      // Create user map for quick lookup
      final userMap = <String, Map<String, dynamic>>{};
      for (final doc in userDocs) {
        if (doc.exists && doc.data() != null) {
          userMap[doc.id] = doc.data()!;
        }
      }

      // Combine scan data with user data
      final scans =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final userId = data['userId'] as String?;
            final userData = userId != null ? userMap[userId] : null;

            return {'id': doc.id, ...data, 'user': userData ?? {}};
          }).toList();

      final hasMore = snapshot.docs.length == limit;

      emit(ScansLoaded(scans, hasMore: hasMore));
    } catch (e) {
      emit(AdminError('Failed to load scans: ${e.toString()}'));
    }
  }
}
