import 'package:shared_preferences/shared_preferences.dart';

class Store {
  static const String tokenKey = "token";
  static Future<void> setToken(String token) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(tokenKey, token);
  }

  static Future<String?> getToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(tokenKey);
  }

  static Future<void> removeToken() async {
    final preferences = await SharedPreferences.getInstance();
   preferences.remove(tokenKey);
  }
}

class StoreLogin {
  static Future<void> setLoginUser(String username, String password) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString("email", username);
    await preferences.setString("password", password);
  }

  static Future<String?> getEmail() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString("email");
  }

  static Future<String?> getPassword() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString("password");
  }

  static Future<void> clearLoginUser() async {
    final preferences = await SharedPreferences.getInstance();
    preferences.remove("email");
    preferences.remove("password");
  }

  static Future<void> setEmailFingerPrintRemember(String username) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString("emailFingerPrint", username);
  }

  static Future<String?> getEmailFingerPrintRemember() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString("emailFingerPrint");
  }

  static Future<void> clearEmailFingerPrintRemember() async {
    final preferences = await SharedPreferences.getInstance();
    preferences.remove("emailFingerPrint");
  }
}
