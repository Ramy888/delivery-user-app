// login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as dev;

import '../../Utils/shared_prefs.dart';
import '../main_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SharedPreferenceHelper _prefs = SharedPreferenceHelper();
  bool _isLoading = false;

  // Check if the user is already authenticated
  void checkUserAuthentication() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      dev.log("LoginPage", error: "loggedin moving to mainPage");
      // Navigate to MainPage if the user is already authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    checkUserAuthentication();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[700]!,
              Colors.blue[900]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    size: 60,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 40),
                // Welcome Text
                Text(
                  'Welcome to DeliveryApp',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 40),
                // Google Sign In Button
                if (_isLoading)
                  CircularProgressIndicator(color: Colors.white)
                else
                  ElevatedButton(
                    onPressed: _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/google.png',
                          height: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);

      // Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get Google Auth Credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase Sign In
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Get FCM Token
        final fcmToken = await FirebaseMessaging.instance.getToken();

        // Save to SharedPreferences
        await _prefs.saveUserId(user.uid);
        await _prefs.saveUserEmail(user.email ?? '');
        await _prefs
            .saveUserFirstName(user.displayName?.split(' ').first ?? '');
        await _prefs.saveUserLastName(user.displayName?.split(' ').last ?? '');
        await _prefs.saveUserPhotoUrl(user.photoURL ?? '');
        await _prefs.saveUserType('customer'); // Default type
        if (fcmToken != null) await _prefs.saveFCMToken(fcmToken);

        // Save to Firestore
        await _saveUserToFirestore(user, fcmToken);

        // Navigate to Home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } catch (e) {
      print('Error during Google Sign In: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in with Google')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserToFirestore(User user, String? fcmToken) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final userData = {
      'email': user.email,
      'firstName': user.displayName?.split(' ').first ?? '',
      'lastName': user.displayName?.split(' ').last ?? '',
      'phoneNumber': user.phoneNumber ?? '',
      'photoURL': user.photoURL ?? '',
      'country': '',
      'userType': 'customer',
      'fcmToken': fcmToken ?? '',
      'balance': '0.0',
      'rating': '0',
      'numberOfOrdersOrDeliveries': '0',
      'currentLocation': '',
    };

    final doc = await userDoc.get();
    if (!doc.exists) {
      await userDoc.set(userData);
    } else {
      // Update only FCM token if user exists
      await userDoc.update({
        'userInfo.fcmToken': fcmToken,
      });
    }
  }
}
