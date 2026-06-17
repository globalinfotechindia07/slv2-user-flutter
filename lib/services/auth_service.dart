import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyUserId = 'user_id';
  static const _keyPhone = 'user_phone';
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUser = 'user_profile';

  static Future<void> saveSession({
    required String userId,
    required String phone,
    Map<String, dynamic>? user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyPhone, phone);
    if (user != null) {
      await prefs.setString(_keyUser, jsonEncode(user));
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Check if user is already logged in — call this in SplashScreen
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Get saved userId — use wherever you need userId (e.g. TransactionsScreen)
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId) ?? '';
  }

  /// Get saved phone number
  static Future<String> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone) ?? '';
  }

  /// Clear session on logout — call this in sidebar logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  static const _keyToken = 'auth_token';

static Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyToken, token);
}

static Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keyToken);
}
}