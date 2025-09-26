import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyRememberMe = 'remember_me';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPassword = 'user_password';
  static const String _keyLastLoginTime = 'last_login_time';
  static const String _keyAutoLoginEnabled = 'auto_login_enabled';

  static SessionManager? _instance;
  SharedPreferences? _prefs;

  SessionManager._internal();

  static SessionManager get instance {
    _instance ??= SessionManager._internal();
    return _instance!;
  }

  // Initialize SharedPreferences
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      log('SessionManager: Initialized successfully');
    } catch (e) {
      log('SessionManager: Failed to initialize: $e');
      rethrow;
    }
  }

  // Save login credentials for remember me
  Future<void> saveLoginCredentials({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    try {
      if (_prefs == null) {
        log('SessionManager: SharedPreferences not initialized');
        return;
      }

      await _prefs!.setBool(_keyRememberMe, rememberMe);
      await _prefs!.setBool(_keyAutoLoginEnabled, rememberMe);

      if (rememberMe) {
        await _prefs!.setString(_keyUserEmail, email);
        await _prefs!.setString(_keyUserPassword, password);
        await _prefs!.setInt(
          _keyLastLoginTime,
          DateTime.now().millisecondsSinceEpoch,
        );
        log('SessionManager: Login credentials saved for remember me');
      } else {
        // Clear credentials if remember me is disabled
        await clearLoginCredentials();
        log('SessionManager: Remember me disabled, credentials cleared');
      }
    } catch (e) {
      log('SessionManager: Failed to save login credentials: $e');
    }
  }

  // Get saved login credentials
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      if (_prefs == null) {
        log('SessionManager: SharedPreferences not initialized');
        return null;
      }

      final rememberMe = _prefs!.getBool(_keyRememberMe) ?? false;
      final autoLoginEnabled = _prefs!.getBool(_keyAutoLoginEnabled) ?? false;

      if (!rememberMe || !autoLoginEnabled) {
        log('SessionManager: Remember me or auto login disabled');
        return null;
      }

      final email = _prefs!.getString(_keyUserEmail);
      final password = _prefs!.getString(_keyUserPassword);
      final lastLoginTime = _prefs!.getInt(_keyLastLoginTime);

      if (email == null || password == null || lastLoginTime == null) {
        log('SessionManager: Incomplete saved credentials');
        return null;
      }

      // Check if credentials are not too old (optional: expire after 30 days)
      final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
      final daysSinceLastLogin = DateTime.now().difference(lastLogin).inDays;

      if (daysSinceLastLogin > 30) {
        log(
          'SessionManager: Saved credentials expired (${daysSinceLastLogin} days old)',
        );
        await clearLoginCredentials();
        return null;
      }

      log('SessionManager: Retrieved saved credentials for auto login');
      return {'email': email, 'password': password};
    } catch (e) {
      log('SessionManager: Failed to get saved credentials: $e');
      return null;
    }
  }

  // Clear saved login credentials
  Future<void> clearLoginCredentials() async {
    try {
      if (_prefs == null) {
        log('SessionManager: SharedPreferences not initialized');
        return;
      }

      await _prefs!.remove(_keyUserEmail);
      await _prefs!.remove(_keyUserPassword);
      await _prefs!.remove(_keyLastLoginTime);
      await _prefs!.setBool(_keyRememberMe, false);
      await _prefs!.setBool(_keyAutoLoginEnabled, false);

      log('SessionManager: Login credentials cleared');
    } catch (e) {
      log('SessionManager: Failed to clear login credentials: $e');
    }
  }

  // Check if remember me is enabled
  bool isRememberMeEnabled() {
    if (_prefs == null) return false;
    return _prefs!.getBool(_keyRememberMe) ?? false;
  }

  // Check if auto login is enabled
  bool isAutoLoginEnabled() {
    if (_prefs == null) return false;
    return _prefs!.getBool(_keyAutoLoginEnabled) ?? false;
  }

  // Enable/disable auto login
  Future<void> setAutoLoginEnabled(bool enabled) async {
    try {
      if (_prefs == null) {
        log('SessionManager: SharedPreferences not initialized');
        return;
      }

      await _prefs!.setBool(_keyAutoLoginEnabled, enabled);

      if (!enabled) {
        // If auto login is disabled, also clear credentials
        await clearLoginCredentials();
      }

      log('SessionManager: Auto login ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      log('SessionManager: Failed to set auto login: $e');
    }
  }

  // Update last login time
  Future<void> updateLastLoginTime() async {
    try {
      if (_prefs == null) {
        log('SessionManager: SharedPreferences not initialized');
        return;
      }

      await _prefs!.setInt(
        _keyLastLoginTime,
        DateTime.now().millisecondsSinceEpoch,
      );
      log('SessionManager: Last login time updated');
    } catch (e) {
      log('SessionManager: Failed to update last login time: $e');
    }
  }

  // Get last login time
  DateTime? getLastLoginTime() {
    if (_prefs == null) return null;

    final lastLoginTime = _prefs!.getInt(_keyLastLoginTime);
    if (lastLoginTime == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
  }

  // Clear all session data
  Future<void> clearAllSessionData() async {
    try {
      if (_prefs == null) {
        log('SessionManager: SharedPreferences not initialized');
        return;
      }

      await _prefs!.clear();
      log('SessionManager: All session data cleared');
    } catch (e) {
      log('SessionManager: Failed to clear all session data: $e');
    }
  }
}
