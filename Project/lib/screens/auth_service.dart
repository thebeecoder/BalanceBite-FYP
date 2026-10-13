import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Save user session when logging in
  static Future<void> saveUserSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userEmail', email);
  }

  // Check if user is logged in
  static Future<String?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail'); 
  }

  // Logout function to clear session
  static Future<void> logout() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail');
    print("User session cleared.");
  } catch (e) {
    print("Error clearing SharedPreferences: $e");
  }
}
}

