import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Initialize Supabase
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseKey,
  }) async {
    try {
      log('AuthService: Initializing Supabase with URL: $supabaseUrl');

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
        debug: true, // Enable debug mode to see more detailed logs
      );

      log('AuthService: Supabase initialized successfully');
      log('AuthService: Client instance created successfully');
      log('AuthService: Auth client available and ready');
    } catch (e) {
      log('AuthService: Error initializing Supabase: $e');
      if (e is AuthException) {
        log('AuthService: Auth exception message: ${e.message}');
        log('AuthService: Auth exception status code: ${e.statusCode}');
      }
      rethrow;
    }
  }

  // Register new user
  Future<void> registerUser({
    required String name,
    required String address,
    required String nationalId,
    required String phoneNumber,
    required String email,
    required String password,
    required String position,
  }) async {
    try {
      // Create user in Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to create user');
      }

      // Create user profile in Supabase Database
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'name': name,
        'email': email,  // Include email field
        'address': address,
        'national_id': nationalId,
        'phone_number': phoneNumber,
        'position': position,
        'is_verified': false,
        'is_blocked': false,
        'is_admin': false,
        'is_approved': false,  // Regular users need approval
        'is_rejected': false,
        'points': 0,
        'level': 'مبتدئ', // Default level
        'created_at': DateTime.now().toIso8601String(),
      });

      // Create registration request
      await _supabase.from('registration_requests').insert({
        'user_id': response.user!.id,
        'status': 'pending',
        'request_date': DateTime.now().toIso8601String(),
      });

      // Sign out after registration (user needs to be verified by admin)
      await _supabase.auth.signOut();
    } catch (e) {
      log('Registration error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      log("AuthService: Attempting login with email: $email");
      log("AuthService: Using Supabase client: ${_supabase.toString()}");
      log("AuthService: Auth client: ${_supabase.auth.toString()}");

      // Sign in with email and password
      log("AuthService: Calling signInWithPassword");
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      log("AuthService: Login successful, user: ${response.user?.email}");
      log(
        "AuthService: Session: ${response.session != null ? 'Valid' : 'Invalid'}",
      );
      return response;
    } catch (e) {
      log('AuthService: Authentication error: $e');
      if (e is AuthException) {
        log('AuthService: Auth exception message: ${e.message}');
        log('AuthService: Auth exception status code: ${e.statusCode}');
      }
      rethrow;
    }
  }

  // Check if user is verified
  Future<bool> isUserVerified(String uid) async {
    log('AuthService: Checking if user is verified, uid: $uid');
    try {
      final response =
          await _supabase.from('users').select().eq('id', uid).single();

      log('AuthService: User data retrieved for verification check');
      log(
        'AuthService: is_verified: ${response['is_verified']}, is_blocked: ${response['is_blocked']}',
      );

      final isVerified =
          response['is_verified'] == true && response['is_blocked'] == false;

      log('AuthService: User verification result: $isVerified');
      return isVerified;
    } catch (e) {
      log('AuthService: Error checking user verification: $e');
      return false;
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin(String uid) async {
    log('AuthService: Checking if user is admin, uid: $uid');
    try {
      final response =
          await _supabase.from('users').select().eq('id', uid).single();

      log('AuthService: User data retrieved for admin check');
      log('AuthService: is_admin: ${response['is_admin']}');

      final isAdmin = response['is_admin'] == true;
      log('AuthService: User admin status: $isAdmin');
      return isAdmin;
    } catch (e) {
      log('AuthService: Error checking admin status: $e');
      return false;
    }
  }

  // Reset password using email
  Future<void> resetPassword(String email) async {
    // Send password reset email
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Registration request operations
  Future<List<Map<String, dynamic>>> getPendingRegistrationRequests() async {
    final response = await _supabase
        .from('registration_requests')
        .select('*, users(*)')
        .eq('status', 'pending')
        .order('request_date');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> approveRegistrationRequest(
    String requestId,
    String userId,
  ) async {
    // Update user verification status
    await _supabase
        .from('users')
        .update({'is_verified': true})
        .eq('id', userId);

    // Update request status
    await _supabase
        .from('registration_requests')
        .update({'status': 'approved'})
        .eq('id', requestId);

    // Create notification for user
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'message': 'تم الموافقة على طلب التسجيل الخاص بك',
      'type': 'registration',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> denyRegistrationRequest(String requestId, String userId) async {
    // Update request status
    await _supabase
        .from('registration_requests')
        .update({'status': 'denied'})
        .eq('id', requestId);

    // Create notification for user
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'message': 'تم رفض طلب التسجيل الخاص بك',
      'type': 'registration',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
