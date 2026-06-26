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
    String? token, 
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyPhone, phone);
    if (user != null) {
      await prefs.setString(_keyUser, jsonEncode(user));
    }
     if (token != null && token.isNotEmpty) {
    await prefs.setString(_keyToken, token);   
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
static const _keyTempToken = 'temp_token';

static Future<void> saveTempToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyTempToken, token);
}

static Future<String?> getTempToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keyTempToken);
}
static const _keyAccessToken = 'access_token';
static const _keyRefreshToken = 'refresh_token';
static const _keyCustomer = 'customer_profile';

static Future<void> saveAccessToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyAccessToken, token);
}

static Future<String?> getAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keyAccessToken);
}

static Future<void> saveRefreshToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyRefreshToken, token);
}

static Future<String?> getRefreshToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keyRefreshToken);
}

static Future<void> saveCustomer(Map<String, dynamic> customer) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyCustomer, jsonEncode(customer));
}

static Future<Map<String, dynamic>?> getCustomer() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_keyCustomer);
  if (raw == null) return null;
  return jsonDecode(raw) as Map<String, dynamic>;
}

static Future<void> clearTempToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keyTempToken);
}
}