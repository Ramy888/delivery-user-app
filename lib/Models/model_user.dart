import 'package:shared_preferences/shared_preferences.dart';

class User {
  String createdAt;
  String firstName;
  String imageUrl;
  String lastName;
  String lastSeen;
  String role;
  String updatedAt;
  String fcmToken;
  String authToken;
  Map<String, dynamic>? userMetadata;

  User({
    required this.createdAt,
    required this.firstName,
    required this.imageUrl,
    required this.lastName,
    required this.lastSeen,
    required this.role,
    required this.updatedAt,
    required this.fcmToken,
    required this.authToken,
    this.userMetadata,
  });

  /// Factory method to create an empty User model
  factory User.emptyModel() {
    return User(
      createdAt: '',
      firstName: '',
      imageUrl: '',
      lastName: '',
      lastSeen: '',
      role: '',
      updatedAt: '',
      fcmToken: '',
      authToken: '',
      userMetadata: {},
    );
  }

  /// Convert a JSON map to a User instance
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      createdAt: json['createdAt'] ?? '',
      firstName: json['firstName'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      lastName: json['lastName'] ?? '',
      lastSeen: json['lastSeen'] ?? '',
      role: json['role'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      fcmToken: json['fcmToken'] ?? '',
      authToken: json['authToken'] ?? '',
      userMetadata: json['userMetadata'] != null
          ? Map<String, dynamic>.from(json['userMetadata'])
          : null,
    );
  }

  /// Convert a User instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt,
      'firstName': firstName,
      'imageUrl': imageUrl,
      'lastName': lastName,
      'lastSeen': lastSeen,
      'role': role,
      'updatedAt': updatedAt,
      'fcmToken': fcmToken,
      'authToken': authToken,
      'userMetadata': userMetadata,
    };
  }

  /// Cache authToken in SharedPreferences
  Future<void> cacheAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', authToken);
  }

  /// Retrieve authToken from SharedPreferences
  static Future<String?> getCachedAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// Clear authToken from SharedPreferences
  static Future<void> clearCachedAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }
}
