import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    log('UserService: Getting user data for uid: $uid');
    try {
      log('UserService: Querying users table with id: $uid');
      final response =
          await _supabase.from('users').select().eq('id', uid).single();

      log('UserService: User data retrieved successfully');
      log('UserService: User data: $response');
      return response;
    } catch (e) {
      log('UserService: Error getting user data: $e');
      if (e is PostgrestException) {
        log('UserService: Postgrest error code: ${e.code}');
        log('UserService: Postgrest error message: ${e.message}');
        log('UserService: Postgrest error details: ${e.details}');
      }
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _supabase.from('users').update(data).eq('id', uid);
  }

  // Update user points
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
    final response = await _supabase
        .from('levels')
        .select()
        .order('starting_points', ascending: false);

    // Find the appropriate level for the user's points
    for (var levelData in response) {
      final startingPoints = levelData['starting_points'] as int? ?? 0;

      if (points >= startingPoints) {
        // Update user's level
        await updateUserData(uid, {'level': levelData['name']});
        break;
      }
    }
  }

  // Admin user management methods
  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    try {
      // Get pending registration requests with user data
      final response = await _supabase
          .from('registration_requests')
          .select('*, users(*)')
          .eq('status', 'pending')
          .order('request_date', ascending: false);

      // Extract user data from the joined response
      final users = <Map<String, dynamic>>[];
      for (var request in response) {
        if (request['users'] != null) {
          final userData = Map<String, dynamic>.from(request['users']);
          // Add request_id to user data for later use
          userData['request_id'] = request['id'];
          users.add(userData);
        }
      }

      return users;
    } catch (e) {
      throw Exception('Failed to get pending users: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase.from('users').select();

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  Future<void> approveUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_approved': true,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to approve user: $e');
    }
  }

  Future<void> rejectUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_rejected': true,
            'rejected_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to reject user: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUsersPaginated({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  Future<void> verifyUser(String userId) async {
    try {
      // Update user verification status
      await _supabase
          .from('users')
          .update({'is_verified': true, 'is_approved': true})
          .eq('id', userId);

      // Update registration request status to approved
      await _supabase
          .from('registration_requests')
          .update({'status': 'approved'})
          .eq('user_id', userId)
          .eq('status', 'pending');
    } catch (e) {
      throw Exception('Failed to verify user: $e');
    }
  }

  Future<void> blockUser(String userId, bool isBlocked) async {
    try {
      await _supabase
          .from('users')
          .update({'is_blocked': isBlocked})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user block status: $e');
    }
  }

  Future<void> toggleAdminStatus(String userId, bool isAdmin) async {
    try {
      await _supabase
          .from('users')
          .update({'is_admin': isAdmin})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user admin status: $e');
    }
  }

  Future<void> updateUserPointsAdmin(String userId, int points) async {
    try {
      // Get current points
      final userData = await getUserData(userId);
      if (userData == null) throw Exception('User not found');

      final currentPoints = userData['points'] as int? ?? 0;

      // Update points
      await _supabase
          .from('users')
          .update({'points': currentPoints + points})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user points: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Update registration request status to rejected before deleting user
      await _supabase
          .from('registration_requests')
          .update({'status': 'rejected'})
          .eq('user_id', userId)
          .eq('status', 'pending');

      // Delete the user
      await _supabase.from('users').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<String> createUser(Map<String, dynamic> userData) async {
    try {
      log('UserService: Starting createUser with userData: $userData');

      // Extract password and email for auth creation
      final String email = userData['email'];
      final String password = userData['password'];

      log(
        'UserService: Extracted email: $email, password length: ${password.length}',
      );

      // Remove password from userData as it shouldn't be stored in the database
      userData.remove('password');
      log('UserService: Removed password from userData');

      // Create user in Supabase Auth
      log('UserService: Creating user in Supabase Auth...');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        log('UserService: Auth signup failed - no user returned');
        throw Exception('Failed to create user in authentication system');
      }

      log(
        'UserService: Auth user created successfully with ID: ${response.user!.id}',
      );

      // Create a new map for database insertion to avoid type conflicts
      final dbUserData = <String, dynamic>{
        'id': response.user!.id,
        'name': userData['name'] as String,
        'email':
            email, // Use the extracted email variable instead of userData['email']
        'address': userData['address'] as String,
        'national_id': userData['national_id'] as String,
        'phone_number': userData['phone_number'] as String,
        'position': userData['position'] as String,
        'is_verified': true, // Admin-created users are immediately verified
        'is_blocked': false,
        'is_admin': false,
        'is_approved': true, // Admin-created users are automatically approved
        'is_rejected': false,
        'points': 0,
        'level': 'مبتدئ',
        'created_at': DateTime.now().toIso8601String(),
      };

      log('UserService: Prepared dbUserData for insertion: $dbUserData');
      log(
        'UserService: Data types - is_verified: ${dbUserData['is_verified'].runtimeType}, is_blocked: ${dbUserData['is_blocked'].runtimeType}, is_admin: ${dbUserData['is_admin'].runtimeType}',
      );

      // Create user profile in database
      log('UserService: Inserting user data into database...');
      await _supabase.from('users').insert(dbUserData);
      log('UserService: User data inserted successfully');

      // Sign out the newly created user (admin shouldn't be logged in as the new user)
      log('UserService: Signing out newly created user...');
      await _supabase.auth.signOut();
      log('UserService: User signed out successfully');

      log(
        'UserService: createUser completed successfully, returning user ID: ${response.user!.id}',
      );
      return response.user!.id;
    } catch (e) {
      log('UserService: createUser failed with error: $e');
      log('UserService: Error type: ${e.runtimeType}');
      throw Exception('Failed to create user: $e');
    }
  }

  // Update user level (admin action)
  Future<void> updateUserLevel(String userId, String levelName) async {
    try {
      log('UserService: Updating user $userId level to: $levelName');
      
      await _supabase
          .from('users')
          .update({'level': levelName})
          .eq('id', userId);
      
      log('UserService: Successfully updated user level to: $levelName');
    } catch (e) {
      log('UserService: Error updating user level: $e');
      throw Exception('Failed to update user level: $e');
    }
  }

  // Bulk reset all users to a specific level
  Future<int> resetAllUsersToLevel(String levelName) async {
    try {
      print('🔄 Resetting all users to level: $levelName');
      
      // Update all users to the specified level
      final response = await _supabase
          .from('users')
          .update({'level': levelName})
          .neq('is_admin', true) // Don't reset admin users
          .select('id');
      
      final count = response.length;
      print('✅ Successfully reset $count users to level: $levelName');
      
      return count;
    } catch (e) {
      print('❌ Error resetting users to level: $e');
      throw Exception('Failed to reset users to level: $e');
    }
  }
}
