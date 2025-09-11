import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/dependency_injector.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;

  AuthCubit({FirebaseAuthService? authService, FirestoreService? firestoreService})
    : _authService = authService ?? DependencyInjector().authService,
      _firestoreService = firestoreService ?? DependencyInjector().firestoreService,
      super(AuthInitial());

  // Check current authentication state
  Future<void> checkAuthState() async {
    emit(AuthLoading());
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Check if user is verified by admin
        final isVerified = await _authService.isUserVerified(user.uid);
        if (isVerified) {
          final isAdmin = await _authService.isUserAdmin(user.uid);
          final userData = await _firestoreService.getUserData(user.uid);
          emit(AuthAuthenticated(user: user, userData: userData!, isAdmin: isAdmin));
        } else {
          emit(AuthNotVerified());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Sign in with phone and password
  Future<void> signInWithPhoneAndPassword(String phoneNumber, String password) async {
    emit(AuthLoading());
    try {
      // Sign in
      final userCredential = await _authService.signInWithPhoneAndPassword(phoneNumber, password);

      // Check if user is verified by admin
      final isVerified = await _authService.isUserVerified(userCredential.user!.uid);
      if (isVerified) {
        final isAdmin = await _authService.isUserAdmin(userCredential.user!.uid);
        final userData = await _firestoreService.getUserData(userCredential.user!.uid);
        emit(AuthAuthenticated(user: userCredential.user!, userData: userData!, isAdmin: isAdmin));
      } else {
        // Sign out if not verified
        await _authService.signOut();
        emit(AuthNotVerified());
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'لا يوجد حساب بهذا الرقم';
          break;
        case 'wrong-password':
          errorMessage = 'كلمة المرور غير صحيحة';
          break;
        case 'user-disabled':
          errorMessage = 'تم تعطيل هذا الحساب';
          break;
        default:
          errorMessage = 'حدث خطأ في تسجيل الدخول';
      }
      emit(AuthError(errorMessage));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
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
    emit(AuthLoading());
    try {
      // Format phone number
      final formattedPhone = phoneNumber.startsWith('0') ? phoneNumber.substring(1) : phoneNumber;

      // Register user
      await _authService.registerUser(
        name: name,
        address: address,
        nationalId: nationalId,
        phoneNumber: formattedPhone,
        password: password,
        position: position,
      );

      emit(AuthRegistrationSuccess());
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'هذا الرقم مسجل بالفعل';
          break;
        case 'weak-password':
          errorMessage = 'كلمة المرور ضعيفة جدًا';
          break;
        default:
          errorMessage = 'حدث خطأ في التسجيل';
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
      await _authService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  // Refresh user data
  Future<void> refreshUserData() async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      try {
        final user = currentState.user;
        final isAdmin = await _authService.isUserAdmin(user.uid);
        final userData = await _firestoreService.getUserData(user.uid);
        emit(AuthAuthenticated(user: user, userData: userData!, isAdmin: isAdmin));
      } catch (e) {
        // Keep the current state if refresh fails
        // but don't emit an error to avoid disrupting the UI
      }
    }
  }
}
