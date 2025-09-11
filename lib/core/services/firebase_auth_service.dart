import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with phone number
  Future<void> signInWithPhoneNumber(
    String phoneNumber,
    Function(PhoneAuthCredential) verificationCompleted,
    Function(FirebaseAuthException) verificationFailed,
    Function(String, int?) codeSent,
    Function(String) codeAutoRetrievalTimeout,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  // Verify OTP code
  Future<UserCredential> verifyOTP(String verificationId, String otp) async {
    final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: otp);
    return await _auth.signInWithCredential(credential);
  }

  // Register new user
  Future<void> registerUser({
    required String name,
    required String address,
    required String nationalId,
    required String phoneNumber,
    required String password,
    required String position,
  }) async {
    try {
      // Format phone number if needed
      final formattedPhone = phoneNumber.startsWith('0') ? phoneNumber.substring(1) : phoneNumber;
      
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: '$formattedPhone@neqati.app', // Using phone as email
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'address': address,
        'nationalId': nationalId,
        'phoneNumber': phoneNumber,
        'position': position,
        'isVerified': false,
        'points': 0,
        'level': 'مبتدئ', // Default level
        'isBlocked': false,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create registration request
      await _firestore.collection('registrationRequests').add({
        'userId': userCredential.user!.uid,
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
      });

      // Sign out after registration (user needs to be verified by admin)
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Sign in with phone number and password
  Future<UserCredential> signInWithPhoneAndPassword(String phoneNumber, String password) async {
    try {
      // Format phone number if needed
      final formattedPhone = phoneNumber.startsWith('0') ? phoneNumber.substring(1) : phoneNumber;
      
      // Sign in with email and password
      return await _auth.signInWithEmailAndPassword(
        email: '$formattedPhone@neqati.app', // Using phone as email
        password: password,
      );
    } catch (e) {
      print('Authentication error: $e');
      rethrow;
    }
  }

  // Check if user is verified
  Future<bool> isUserVerified(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.exists && userDoc.data()?['isVerified'] == true && userDoc.data()?['isBlocked'] == false;
  }

  // Check if user is admin
  Future<bool> isUserAdmin(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.exists && userDoc.data()?['isAdmin'] == true;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
