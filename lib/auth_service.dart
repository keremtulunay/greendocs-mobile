import 'dart:convert';
import 'package:http/http.dart' as http;
import 'Models/session.dart';
import 'Screens/main_menu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
class AuthService {
  static const _tokenKey = 'session_token';
  final String _baseUrl;
  static var authToken;
  AuthService(this._baseUrl);
  /// Perform login and optionally store token if "Remember Me" is true
  Future<bool> login(String username, String password, {bool rememberMe = false}) async {
    final url = Uri.parse('$_baseUrl/Login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'login': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final token = data['session']?['Token'];
          print('🟢 Login successful! Token: $token');
          final sessionJson = data['session'];
          final session = Session.fromJson(sessionJson);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session', jsonEncode(session.toJson()));
          if (rememberMe && token != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_tokenKey, token);
            print('💾 Token saved: $token'); // ✅ Confirmation log
          }
          authToken = token;
          return true;
        } else {
          print('🔴 Login failed. Status: ${data['status']}');
          return false;
        }
      } else {
        print('❌ Server error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('⚠️ Exception during login: $e');
      return false;
    }
  }

  /// Retrieve saved session token
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Optional: clear token for logout
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print('🚪 Logged out. Token cleared.');
  }

  Future<void> debugPrintSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);
    print('🧠 Retrieved saved token: $saved');
  }

  Future<Session?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('session');

    if (raw == null) return null;

    final json = jsonDecode(raw);
    return Session.fromJson(json);
  }

}
