import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static String userIdKey = "USER_ID";
  static String userEmailKey = "USER_EMAIL";
  static String userFirstNameKey = "USER_FIRST_NAME";
  static String userLastNameKey = "USER_LAST_NAME";
  static String userPhotoUrlKey = "USER_PHOTO_URL";
  static String userTypeKey = "USER_TYPE";
  static String fcmTokenKey = "FCM_TOKEN";
  static String userAddress = "USER_ADDRESS";
  static String userBalance = "USER_BALANCE";

  // Save Data
  Future<bool> saveUserId(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userIdKey, userId);
  }

  Future<bool> saveUserEmail(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userEmailKey, email);
  }

  Future<bool> saveUserFirstName(String firstName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userFirstNameKey, firstName);
  }

  Future<bool> saveUserLastName(String lastName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userLastNameKey, lastName);
  }

  Future<bool> saveUserPhotoUrl(String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userPhotoUrlKey, url);
  }

  Future<bool> saveUserType(String userType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userTypeKey, userType);
  }

  Future<bool> saveFCMToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(fcmTokenKey, token);
  }

  Future<bool> saveAddress(String address) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userAddress, address);
  }

  // Get Data
  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  Future<String?> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userEmailKey);
  }

  Future<String?> getUserFirstName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userFirstNameKey);
  }

  Future<String?> getUserLastName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userLastNameKey);
  }

  Future<String?> getUserPhotoUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userPhotoUrlKey);
  }

  Future<String?> getUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userTypeKey);
  }

  Future<String?> getFCMToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(fcmTokenKey);
  }

  Future<String?> getAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userAddress);
  }

  Future<String?> getBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userBalance);
  }

  // Clear Data
  Future<bool> clearPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }
}