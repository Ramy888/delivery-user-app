// import 'package:eb3at/Screens/home_page.dart';
// import 'package:eb3at/Screens/main_page.dart';
// import 'package:eb3at/Utils/show_toast.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'dart:developer' as dev;
//
//
// import '../../Utils/shared_prefs.dart';
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({Key? key}) : super(key: key);
//
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }
// //
// class _LoginPageState extends State<LoginPage> {
//   @override
//   void initState() {
//     super.initState();
//     checkUserAuthentication();
//   }
//
//   // Check if the user is already authenticated
//   void checkUserAuthentication() {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       dev.log("LoginPage", error: "loggedin moving to mainPage");
//       // Navigate to MainPage if the user is already authenticated
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (context) => const MainPage()),
//         );
//       });
//     }
//   }
//
//   /* Google Authentication and login function */
//   Future<void> signInWithGoogle(BuildContext context) async {
//     try {
//       final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
//
//       if (gUser == null) {
//         // User canceled the sign-in
//         return;
//       }
//
//       final GoogleSignInAuthentication? gAuth = await gUser.authentication;
//
//       final credential = GoogleAuthProvider.credential(
//         accessToken: gAuth?.accessToken,
//         idToken: gAuth?.idToken,
//       );
//       UserCredential user =
//       await FirebaseAuth.instance.signInWithCredential(credential);
//
//       // Save user details in shared preferences
//       SharedPreferenceHelper().saveUserName(user.user?.displayName);
//       SharedPreferenceHelper().saveEmail(user.user?.email);
//       SharedPreferenceHelper().saveImage(user.user?.photoURL);
//
//       // Navigate to MainPage after successful login
//       if (user.user != null) {
//         Navigator.of(context).pushAndRemoveUntil(
//           MaterialPageRoute(builder: (context) => const MainPage()),
//               (Route route) => false,
//         );
//       }
//     } catch (e) {
//       print("Error during Google Sign-In: $e");
//       ToastUtil.showShortToast("Something went wrong, please try again");
//       // Handle sign-in error
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.blue,
//       body: Padding(
//         padding: const EdgeInsets.all(15.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             SizedBox(
//               height: 500,
//               width: double.infinity,
//               child: Image.asset(
//                 "assets/images/signup.png",
//                 fit: BoxFit.cover,
//               ),
//             ),
//             Text(
//               "Sign up today and unlock exclusive access to thrilling bidding wars and unbeatable deals.",
//               style: const TextStyle(fontSize: 18, color: Colors.white),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 50),
//             InkWell(
//               onTap: () {
//                 signInWithGoogle(context);
//               },
//               child: Container(
//                 height: 50,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(30),
//                   color: Colors.green,
//                 ),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Image.asset(
//                       "assets/images/google.png",
//                       height: 30,
//                       width: 30,
//                     ),
//                     const SizedBox(width: 10),
//                     const Text(
//                       "Sign in with Google",
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
