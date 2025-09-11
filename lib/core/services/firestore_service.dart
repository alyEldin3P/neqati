import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // User Operations
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<void> updateUserPoints(String uid, int points) async {
    // Get current user data
    final userData = await getUserData(uid);
    if (userData == null) return;
    
    final currentPoints = userData['points'] as int? ?? 0;
    final newPoints = currentPoints + points;
    
    // Update user points
    await updateUserData(uid, {'points': newPoints});
    
    // Check if user should level up
    await _checkAndUpdateUserLevel(uid, newPoints);
  }

  Future<void> _checkAndUpdateUserLevel(String uid, int points) async {
    // Get all levels sorted by starting points
    final levelsSnapshot = await _firestore.collection('levels')
        .orderBy('startingPoints', descending: true)
        .get();
    
    // Find the appropriate level for the user's points
    for (var levelDoc in levelsSnapshot.docs) {
      final levelData = levelDoc.data();
      final startingPoints = levelData['startingPoints'] as int? ?? 0;
      
      if (points >= startingPoints) {
        // Update user's level
        await updateUserData(uid, {'level': levelData['name']});
        break;
      }
    }
  }

  // QR Code Operations
  Future<Map<String, dynamic>> createQRCode({
    required int points,
    required String branch,
    required int expiryDuration,
    required String encryptedPayload,
  }) async {
    final qrData = {
      'points': points,
      'branch': branch,
      'status': 'active',
      'scannedBy': null,
      'scanDate': null,
      'creationDate': FieldValue.serverTimestamp(),
      'expiryDuration': expiryDuration,
      'encryptedPayload': encryptedPayload,
    };
    
    final docRef = await _firestore.collection('qrCodes').add(qrData);
    
    // Update the document with its ID
    await docRef.update({'id': docRef.id});
    
    // Return the created QR code data with ID
    final updatedData = Map<String, dynamic>.from(qrData);
    updatedData['id'] = docRef.id;
    return updatedData;
  }

  Future<Map<String, dynamic>?> getQRCodeData(String qrId) async {
    final doc = await _firestore.collection('qrCodes').doc(qrId).get();
    return doc.data();
  }

  Future<bool> scanQRCode(String qrId, String userId) async {
    // Get QR code data
    final qrData = await getQRCodeData(qrId);
    if (qrData == null) return false;
    
    // Check if QR code is active
    if (qrData['status'] != 'active') return false;
    
    // Check if QR code is expired
    final creationDate = (qrData['creationDate'] as Timestamp).toDate();
    final expiryDuration = qrData['expiryDuration'] as int? ?? 7;
    final expiryDate = creationDate.add(Duration(days: expiryDuration));
    
    if (DateTime.now().isAfter(expiryDate)) {
      // Mark QR code as expired
      await _firestore.collection('qrCodes').doc(qrId).update({
        'status': 'expired',
      });
      return false;
    }
    
    // Get user data for level multiplier
    final userData = await getUserData(userId);
    if (userData == null) return false;
    
    // Get level multiplier
    final userLevel = userData['level'] as String? ?? 'مبتدئ';
    final levelDoc = await _firestore.collection('levels')
        .where('name', isEqualTo: userLevel)
        .limit(1)
        .get();
    
    double multiplier = 1.0;
    if (levelDoc.docs.isNotEmpty) {
      multiplier = levelDoc.docs.first.data()['multiplier'] as double? ?? 1.0;
    }
    
    // Calculate points earned
    final basePoints = qrData['points'] as int? ?? 0;
    final pointsEarned = (basePoints * multiplier).toInt();
    
    // Update QR code status
    await _firestore.collection('qrCodes').doc(qrId).update({
      'status': 'scanned',
      'scannedBy': userId,
      'scanDate': FieldValue.serverTimestamp(),
    });
    
    // Record scan in history
    await _firestore.collection('scans').add({
      'userId': userId,
      'qrCodeId': qrId,
      'pointsEarned': pointsEarned,
      'scanDate': FieldValue.serverTimestamp(),
      'branch': qrData['branch'],
    });
    
    // Update user points
    await updateUserPoints(userId, pointsEarned);
    
    return true;
  }

  // Gift Operations
  Future<List<Map<String, dynamic>>> getAvailableGifts() async {
    final offersSnapshot = await _firestore.collection('offers')
        .orderBy('createdAt', descending: true)
        .get();
    
    return offersSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<bool> requestGift(String userId, String giftId) async {
    // Get user data
    final userData = await getUserData(userId);
    if (userData == null) return false;
    
    // Get gift data
    final giftDoc = await _firestore.collection('gifts').doc(giftId).get();
    if (!giftDoc.exists) return false;
    
    final giftData = giftDoc.data()!;
    
    // Check if user has enough points
    final userPoints = userData['points'] as int? ?? 0;
    final giftPoints = giftData['points'] as int? ?? 0;
    
    if (userPoints < giftPoints) return false;
    
    // Check if gift is in stock
    final stock = giftData['stock'] as int? ?? 0;
    if (stock <= 0) return false;
    
    // Create gift request
    await _firestore.collection('requests').add({
      'userId': userId,
      'giftId': giftId,
      'status': 'pending',
      'requestDate': FieldValue.serverTimestamp(),
    });
    
    // Create notification for admins
    await _firestore.collection('notifications').add({
      'userId': 'all_admins',
      'message': 'طلب هدية جديد من ${userData['name']}',
      'type': 'gift_request',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return true;
  }

  // Level Operations
  Future<List<Map<String, dynamic>>> getLevels() async {
    final levelsSnapshot = await _firestore.collection('levels')
        .orderBy('startingPoints')
        .get();
    
    return levelsSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Offer Operations
  Future<List<Map<String, dynamic>>> getOffers() async {
    final offersSnapshot = await _firestore.collection('offers')
        .orderBy('createdAt', descending: true)
        .get();
    
    return offersSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<List<dynamic>> getActiveOffers() async {
    try {
      final now = DateTime.now();
      final offersSnapshot = await _firestore.collection('offers')
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('endDate')
          .get();
      
      return offersSnapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
    } catch (e) {
      print('Error getting active offers: $e');
      return [];
    }
  }

  // Scan History Operations
  Future<List<Map<String, dynamic>>> getUserScanHistory(String userId) async {
    final scansSnapshot = await _firestore.collection('scans')
        .where('userId', isEqualTo: userId)
        .orderBy('scanDate', descending: true)
        .get();
    
    return scansSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Admin Operations
  Future<List<Map<String, dynamic>>> getPendingRegistrationRequests() async {
    final requestsSnapshot = await _firestore.collection('registrationRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestDate')
        .get();
    
    final requests = <Map<String, dynamic>>[];
    
    for (var doc in requestsSnapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      
      // Get user data
      final userId = data['userId'] as String;
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        data['userData'] = userData;
      }
      
      requests.add(data);
    }
    
    return requests;
  }

  Future<void> approveRegistrationRequest(String requestId, String userId) async {
    // Update user verification status
    await _firestore.collection('users').doc(userId).update({
      'isVerified': true,
    });
    
    // Update request status
    await _firestore.collection('registrationRequests').doc(requestId).update({
      'status': 'approved',
    });
    
    // Create notification for user
    await _firestore.collection('notifications').add({
      'userId': userId,
      'message': 'تم الموافقة على طلب التسجيل الخاص بك',
      'type': 'registration',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> denyRegistrationRequest(String requestId, String userId) async {
    // Update request status
    await _firestore.collection('registrationRequests').doc(requestId).update({
      'status': 'denied',
    });
    
    // Create notification for user
    await _firestore.collection('notifications').add({
      'userId': userId,
      'message': 'تم رفض طلب التسجيل الخاص بك',
      'type': 'registration',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Image Upload
  Future<String> uploadImage(File file, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
  
  // QR Scan Record
  Future<Map<String, dynamic>> recordQRScan({
    required String userId,
    required Map<String, dynamic> qrData,
  }) async {
    // Extract QR code ID from data
    final qrId = qrData['id'] as String?;
    if (qrId == null) {
      return {
        'success': false,
        'message': 'رمز QR غير صالح',
        'points': 0,
        'location': '',
      };
    }
    
    // Attempt to scan the QR code
    final scanSuccess = await scanQRCode(qrId, userId);
    
    if (!scanSuccess) {
      // Get QR code data to determine why scan failed
      final qrCodeData = await getQRCodeData(qrId);
      String message = 'فشل مسح الرمز';
      
      if (qrCodeData == null) {
        message = 'رمز QR غير موجود';
      } else if (qrCodeData['status'] == 'scanned') {
        message = 'تم مسح هذا الرمز مسبقاً';
      } else if (qrCodeData['status'] == 'expired') {
        message = 'انتهت صلاحية هذا الرمز';
      }
      
      return {
        'success': false,
        'message': message,
        'points': 0,
        'location': qrCodeData?['branch'] ?? '',
      };
    }
    
    // Get the latest scan for this user and QR code
    final scanQuery = await _firestore.collection('scans')
        .where('userId', isEqualTo: userId)
        .where('qrCodeId', isEqualTo: qrId)
        .orderBy('scanDate', descending: true)
        .limit(1)
        .get();
    
    if (scanQuery.docs.isEmpty) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تسجيل المسح',
        'points': 0,
        'location': qrData['branch'] ?? '',
      };
    }
    
    final scanData = scanQuery.docs.first.data();
    
    return {
      'success': true,
      'message': 'تم مسح الرمز بنجاح',
      'points': scanData['pointsEarned'] ?? 0,
      'location': scanData['branch'] ?? '',
    };
  }

  // Admin methods
  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    try {
      final query = await _firestore.collection('users')
          .where('isApproved', isEqualTo: false)
          .where('isRejected', isEqualTo: false)
          .get();
      
      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to get pending users: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final query = await _firestore.collection('users').get();
      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllQRCodes() async {
    try {
      final query = await _firestore.collection('qr_codes').get();
      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all QR codes: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentScans(int days) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final query = await _firestore.collection('scans')
          .where('scanDate', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .get();
      
      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to get recent scans: $e');
    }
  }

  Future<void> approveUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to approve user: $e');
    }
  }

  Future<void> rejectUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isRejected': true,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject user: $e');
    }
  }

  // Gift methods - remove duplicate

  Future<Map<String, dynamic>> redeemGift(String giftId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'يرجى تسجيل الدخول أولاً',
        };
      }

      // Get gift details
      final giftDoc = await _firestore.collection('gifts').doc(giftId).get();
      if (!giftDoc.exists) {
        return {
          'success': false,
          'message': 'الهدية غير موجودة',
        };
      }

      final giftData = giftDoc.data()!;
      final requiredPoints = giftData['requiredPoints'] as int? ?? 0;
      final isAvailable = giftData['isAvailable'] as bool? ?? false;

      if (!isAvailable) {
        return {
          'success': false,
          'message': 'هذه الهدية غير متاحة حالياً',
        };
      }

      // Get user points
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'بيانات المستخدم غير موجودة',
        };
      }

      final userData = userDoc.data()!;
      final userPoints = userData['points'] as int? ?? 0;

      if (userPoints < requiredPoints) {
        return {
          'success': false,
          'message': 'نقاطك غير كافية لاستبدال هذه الهدية',
        };
      }

      // Create redemption record
      await _firestore.collection('gift_redemptions').add({
        'userId': currentUser.uid,
        'giftId': giftId,
        'giftName': giftData['name'],
        'pointsUsed': requiredPoints,
        'redeemedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, approved, delivered
      });

      // Deduct points from user
      await _firestore.collection('users').doc(currentUser.uid).update({
        'points': FieldValue.increment(-requiredPoints),
      });

      return {
        'success': true,
        'message': 'تم استبدال الهدية بنجاح. سيتم التواصل معك قريباً',
      };
    } catch (e) {
      throw Exception('Failed to redeem gift: $e');
    }
  }
}
