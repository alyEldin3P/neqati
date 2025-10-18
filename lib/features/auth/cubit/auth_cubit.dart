import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/services/auth_service.dart';
import 'package:neqati/core/services/user_service.dart';
import 'package:neqati/core/services/fcm_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/session_manager.dart';
import '../../../core/services/dependency_injector.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SessionManager _sessionManager;
  final AuthService _authService;
  final UserService _userService;
  // final FCMNotificationService _fcmService;

  AuthCubit({SessionManager? sessionManager})
    : _sessionManager = sessionManager ?? DependencyInjector().sessionManager,
      _authService = DependencyInjector().authService,
      _userService = DependencyInjector().userService,
      // _fcmService = DependencyInjector().fcmNotificationService,
      super(AuthInitial());

  // Check current authentication state
  Future<void> checkAuthState() async {
    emit(AuthLoading());
    try {
      final user = _authService.currentUser;
      if (user != null) {
        log('AuthCubit: User session exists, checking verification');
        // Check if user is verified by admin
        final isVerified = await _authService.isUserVerified(user.id);
        if (isVerified) {
          final isAdmin = await _authService.isUserAdmin(user.id);
          final userData = await _userService.getUserData(user.id);

          // Check if user is blocked
          final isBlocked = userData?['is_blocked'] as bool? ?? false;
          if (isBlocked) {
            log('AuthCubit: User is blocked during session check');
            // Sign out blocked user
            await _authService.signOut();
            // Clear saved credentials for blocked users
            await _sessionManager.clearLoginCredentials();
            emit(AuthBlocked());
            return;
          }

          // Save FCM device token for existing session
          log('AuthCubit: Saving FCM device token for existing session');
          // await _fcmService.saveDeviceToken();

          emit(
            AuthAuthenticated(
              user: user,
              userData: userData!,
              isAdmin: isAdmin,
            ),
          );
        } else {
          emit(AuthNotVerified());
        }
      } else {
        log('AuthCubit: No active session, checking for saved credentials');
        // Try automatic login with saved credentials
        await _tryAutoLogin();
      }
    } catch (e) {
      log('AuthCubit: Error checking auth state: $e');
      emit(AuthError(e.toString()));
    }
  }

  // Try automatic login with saved credentials
  Future<void> _tryAutoLogin() async {
    try {
      final savedCredentials = await _sessionManager.getSavedCredentials();
      if (savedCredentials != null) {
        log('AuthCubit: Found saved credentials, attempting auto login');
        final email = savedCredentials['email']!;
        final password = savedCredentials['password']!;

        // Attempt silent login
        await _performLogin(email, password, isAutoLogin: true);
      } else {
        log('AuthCubit: No saved credentials found');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      log('AuthCubit: Auto login failed: $e');
      // Clear invalid credentials and show unauthenticated state
      await _sessionManager.clearLoginCredentials();
      emit(AuthUnauthenticated());
    }
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    emit(AuthLoading());
    await _performLogin(email, password, isAutoLogin: false);
  }

  // Shared login method for both manual and automatic login
  Future<void> _performLogin(
    String email,
    String password, {
    required bool isAutoLogin,
  }) async {
    try {
      log('AuthCubit: Performing login for email: $email (auto: $isAutoLogin)');

      // Sign in
      final response = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      final user = response.user;

      if (user == null) {
        emit(AuthError('فشل تسجيل الدخول'));
        return;
      }

      // Check if user is verified by admin
      final isVerified = await _authService.isUserVerified(user.id);
      if (isVerified) {
        final isAdmin = await _authService.isUserAdmin(user.id);
        final userData = await _userService.getUserData(user.id);

        // Check if user is blocked
        final isBlocked = userData?['is_blocked'] as bool? ?? false;
        if (isBlocked) {
          log('AuthCubit: User is blocked');
          // Sign out blocked user
          await _authService.signOut();
          // Clear saved credentials for blocked users
          await _sessionManager.clearLoginCredentials();
          emit(AuthBlocked());
          return;
        }

        // Save credentials for remember me (only for manual login)
        if (!isAutoLogin) {
          log('AuthCubit: Saving login credentials for remember me');
          await _sessionManager.saveLoginCredentials(
            email: email,
            password: password,
            rememberMe: true, // Always remember for automatic caching
          );
        } else {
          // Update last login time for auto login
          await _sessionManager.updateLastLoginTime();
        }

        // Save FCM device token after successful login
        log('AuthCubit: Saving FCM device token after login');
        // await _fcmService.saveDeviceToken();

        emit(
          AuthAuthenticated(user: user, userData: userData!, isAdmin: isAdmin),
        );
      } else {
        // Sign out if not verified
        await _authService.signOut();
        emit(AuthNotVerified());
      }
    } on AuthException catch (e) {
      String errorMessage;
      switch (e.message) {
        case 'Invalid login credentials':
          errorMessage = 'بيانات الدخول غير صحيحة';
          break;
        case 'Email not confirmed':
          errorMessage = 'البريد الإلكتروني غير مؤكد';
          break;
        case 'User is disabled':
          errorMessage = 'تم تعطيل هذا الحساب';
          break;
        default:
          errorMessage = 'حدث خطأ في تسجيل الدخول: ${e.message}';
      }

      // Clear saved credentials if login fails
      if (errorMessage.contains('بيانات الدخول غير صحيحة')) {
        await _sessionManager.clearLoginCredentials();
      }

      emit(AuthError(errorMessage));
    } catch (e) {
      log('AuthCubit: Login error: $e');
      emit(AuthError(e.toString()));
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
    emit(AuthLoading());
    try {
      // Register user
      await _authService.registerUser(
        name: name,
        address: address,
        nationalId: nationalId,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
        position: position,
      );

      emit(AuthRegistrationSuccess());
    } on AuthException catch (e) {
      String errorMessage;
      switch (e.message) {
        case 'User already registered':
          errorMessage = 'هذا البريد الإلكتروني مسجل بالفعل';
          break;
        case 'Password should be at least 6 characters':
          errorMessage = 'كلمة المرور ضعيفة جدًا';
          break;
        default:
          errorMessage = 'حدث خطأ في التسجيل: ${e.message}';
      }
      emit(AuthError(errorMessage));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await _authService.resetPassword(email);
      emit(AuthPasswordResetSent());
    } on AuthException catch (e) {
      String errorMessage;
      switch (e.message) {
        case 'Email not found':
          errorMessage = 'لا يوجد حساب بهذا البريد الإلكتروني';
          break;
        case 'Invalid email':
          errorMessage = 'البريد الإلكتروني غير صحيح';
          break;
        default:
          errorMessage = 'حدث خطأ في إرسال رابط الاستعادة: ${e.message}';
      }
      emit(AuthError(errorMessage));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Sign out
  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      log('AuthCubit: Signing out user');
      await _authService.signOut();

      // Clear saved credentials on manual sign out
      await _sessionManager.clearLoginCredentials();
      log('AuthCubit: Cleared saved credentials');

      emit(AuthUnauthenticated());
    } catch (e) {
      log('AuthCubit: Sign out error: $e');
      emit(AuthError(e.toString()));
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      try {
        final user = currentState.user;
        final isAdmin = await _authService.isUserAdmin(user.id);
        final userData = await _userService.getUserData(user.id);
        emit(
          AuthAuthenticated(user: user, userData: userData!, isAdmin: isAdmin),
        );
      } catch (e) {
        // Keep the current state if refresh fails
        // but don't emit an error to avoid disrupting the UI
      }
    }
  }

  // Check if user is blocked by fetching fresh user data
  Future<bool> isUserBlocked(String userId) async {
    try {
      final userData = await _userService.getUserData(userId);
      return userData?['is_blocked'] as bool? ?? false;
    } catch (e) {
      log('AuthCubit: Error checking user blocked status: $e');
      // Return true as a safety measure if we can't verify
      return true;
    }
  }
}
