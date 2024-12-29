import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../CustomWidgets/customized_text.dart';
import '../Utils/shared_prefs.dart';
import '../main.dart';
import 'main_page.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SharedPreferenceHelper _prefs = SharedPreferenceHelper();

  Map<String, dynamic>? userData;
  bool isEditing = false;
  bool isLoading = true;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateFCMToken();
  }

  Future<void> _updateFCMToken() async {
    _fcmToken = await _fcm.getToken();
    if (_fcmToken != null) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          // .collection('userInfo')
          // .doc('profile')
          .update({'fcmToken': _fcmToken});
    }
  }

  Future<void> _loadUserData() async {
    try {
      // String uMail = await _prefs.getUserEmail() ?? '';
      // if(uMail != null && uMail.isNotEmpty) {
      //   String uFName = await _prefs.getUserFirstName() ?? '';
      //   String uLName = await _prefs.getUserLastName() ?? '';
      //   String uPhoto = await _prefs.getUserPhotoUrl() ?? '';
      //   String uType = await _prefs.getUserType() ?? '';
      //   String fcmToken = await _prefs.getFCMToken() ?? '';
      //
      //   if(fcmToken == null || fcmToken.isEmpty) {
      //     fcmToken = await _fcm.getToken() ?? '';
      //     await _prefs.saveFCMToken(fcmToken);
      //   }
      //
      //   final initialData = {
      //     'email': uMail,
      //     'firstName': uFName,
      //     'lastName': uLName,
      //     'photoURL': uPhoto,
      //     'phoneNumber': '',
      //     'country': '',
      //     'userType': uType,
      //     'fcmToken': fcmToken,
      //     'balance': '0.0',
      //   };
      // }

      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          // .collection('userInfo')
          // .doc('profile')
          .get();

      if (!userDoc.exists) {
        // Create new user profile if it doesn't exist
        final User? googleUser = _auth.currentUser;
        final initialData = {
          'email': googleUser?.email ?? '',
          'firstName': googleUser?.displayName?.split(' ').first ?? '',
          'lastName': googleUser?.displayName?.split(' ').last ?? '',
          'photoURL': googleUser?.photoURL ?? '',
          'phoneNumber': '',
          'country': '',
          'userType': 'customer',
          'fcmToken': _fcmToken ?? '',
          'balance': '0.0',
          'rating': '0',
          'numberOfOrdersOrDeliveries': '0',
          'currentLocation': '',
        };

        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            // .collection('userInfo')
            // .doc('profile')
            .set(initialData);

        setState(() {
          userData = initialData;
          isLoading = false;
        });
      } else {
        setState(() {
          userData = userDoc.data();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileStats(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildUserInfoForm(),
                      const SizedBox(height: 20),
                      _buildBalanceCard(),
                      const SizedBox(height: 20),
                      _buildUserTypeSwitch(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          // color: primaryColor.withOpacity(0.8,)
          color: Colors.white,
        ),
        child: FlexibleSpaceBar(
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withOpacity(0.7),
                  primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: _buildProfileImage(),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Profile Container with Background
          Column(
            children: [
              // Upper colored section
              Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      // secondaryColor,
                      accentColor.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
              // Lower white section
              Container(
                height: 80,
                color: Colors.transparent,
              ),
            ],
          ),

          // Profile Image
          Positioned(
            top: 20,
            child: Stack(
              children: [
                // Profile Photo with Border
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: userData?['photoURL'] != null &&
                            userData!['photoURL'].isNotEmpty
                        ? NetworkImage(userData!['photoURL']) as ImageProvider
                        : const AssetImage('assets/default_avatar.png'),
                    child: userData?['photoURL'] == null ||
                            userData!['photoURL'].isEmpty
                        ? Icon(
                            Icons.person,
                            size: 55,
                            color: Colors.grey[400],
                          )
                        : null,
                  ),
                ),

                // Edit Button
                if (isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showImagePickerSheet(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          // color: primaryColor,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              secondaryColor,
                              // secondaryColor.withOpacity(0.4),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // User Info
          Positioned(
            bottom: -2,
            child: Column(
              children: [
                Text(
                  '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'
                      .trim(),
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                // const SizedBox(height: 4),
                Text(
                  userData?['email'] ?? '',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Profile Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPickerOption(
                          icon: Icons.photo_camera,
                          label: 'Camera',
                          onTap: () =>
                              _handleImageSelection(ImageSource.camera),
                        ),
                        _buildPickerOption(
                          icon: Icons.photo_library,
                          label: 'Gallery',
                          onTap: () =>
                              _handleImageSelection(ImageSource.gallery),
                        ),
                        // if (userData?['photoURL'] != null)
                        //   _buildPickerOption(
                        //     icon: Icons.delete,
                        //     label: 'Remove',
                        //     onTap: _removeProfilePhoto,
                        //     isDestructive: true,
                        //   ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDestructive
                  ? Colors.red.withOpacity(0.1)
                  : primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDestructive ? Colors.red : primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDestructive ? Colors.red : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => isLoading = true);
        await _uploadAndUpdateProfilePhoto(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select image');
    }
  }

  Future<void> _uploadAndUpdateProfilePhoto(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${_auth.currentUser!.uid}.jpg');

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          // .collection('userInfo')
          // .doc('profile')
          .update({'photoURL': downloadUrl});

      setState(() {
        userData?['photoURL'] = downloadUrl;
        isLoading = false;
      });

      _showSuccessSnackBar('Profile photo updated successfully');
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to update profile photo');
    }
  }

  Widget _buildProfileStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Orders', userData?['numberOfOrders'] ?? '0'),
          _buildStatItem('Rating', '${userData?['rating'] ?? '0.0'} ★'),
          _buildStatItem('Balance', '\$${userData?['balance'] ?? '0.00'}'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoForm() {
    return Card(
      color: Colors.grey[200],
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: 'Personal Information',
                fontSize: 15,
                isBold: true,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'First Name',
                userData?['firstName'] ?? '',
                Icons.person_outline,
                (value) =>
                    value?.isEmpty ?? true ? 'First name is required' : null,
                (value) => userData?['firstName'] = value,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                'Last Name',
                userData?['lastName'] ?? '',
                Icons.person_outline,
                (value) =>
                    value?.isEmpty ?? true ? 'Last name is required' : null,
                (value) => userData?['lastName'] = value,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                'Phone Number',
                userData?['phoneNumber'] ?? '',
                Icons.phone_outlined,
                (value) =>
                    value?.isEmpty ?? true ? 'Phone number is required' : null,
                (value) => userData?['phoneNumber'] = value,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                'Country',
                userData?['country'] ?? '',
                Icons.location_on_outlined,
                null,
                (value) => userData?['country'] = value,
              ),
              const SizedBox(height: 20),
              if (isEditing)
                _buildActionButton('Save Changes', _saveProfile)
              else
                _buildActionButton(
                    'Edit Profile', () => setState(() => isEditing = true)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String initialValue,
    IconData icon,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  ) {
    return TextFormField(
      initialValue: initialValue,
      enabled: isEditing,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor),
        ),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: AppText(
          text: text,
          color: Colors.white,
          fontSize: 15,
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: primaryColor.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      color: Colors.grey[200],
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  text: 'Current Balance',
                  fontSize: 14,
                  isBold: true,
                  color: Colors.grey[600],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 16,
                        color: primaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Available',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Balance Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  userData?['balance'] ?? '0.00',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transaction Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Updated',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateTime.now().toString().substring(0, 10),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.history,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeSwitch() {
    final bool isCustomer = userData?['userType'] == 'customer';

    return Card(
      color: Colors.grey[200],
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            AppText(
              text: 'Switch Account Type',
              fontSize: 15,
              isBold: true,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),

            // Current Account Type Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCustomer
                          ? primaryColor.withOpacity(0.1)
                          : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCustomer ? Icons.person : Icons.delivery_dining,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Account Type Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCustomer ? 'Customer Account' : 'Delivery Account',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCustomer
                              ? 'You can request deliveries'
                              : 'You can deliver orders',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Switch Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showSwitchAccountDialog(isCustomer),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: primaryColor.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: AppText(
                  text:
                      'Switch to ${isCustomer ? 'Delivery' : 'Customer'} Account',
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSwitchAccountDialog(bool isCustomer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Account Type'),
        content: Text(
            'Are you sure you want to switch to ${isCustomer ? 'Delivery' : 'Customer'} account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleUserType();
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() => isLoading = true);

        // Upload to Firebase Storage
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${_auth.currentUser!.uid}.jpg');

        await ref.putFile(File(image.path));
        final downloadUrl = await ref.getDownloadURL();

        // Update Firestore
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            // .collection('userInfo')
            // .doc('profile')
            .update({'photoURL': downloadUrl});

        setState(() {
          userData?['photoURL'] = downloadUrl;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error updating profile image: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      setState(() => isLoading = true);

      try {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            // .collection('userInfo')
            // .doc('profile')
            .update(userData!);

        setState(() {
          isEditing = false;
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } catch (e) {
        print('Error saving profile: $e');
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating profile')),
        );
      }
    }
  }

  Future<void> _toggleUserType() async {
    try {
      final newUserType =
          userData?['userType'] == 'customer' ? 'delivery' : 'customer';

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          // .collection('userInfo')
          // .doc('profile')
          .update({'userType': newUserType});

      setState(() {
        userData?['userType'] = newUserType;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Switched to ${newUserType.capitalize()} account successfully',
          ),
        ),
      );
    } catch (e) {
      print('Error toggling user type: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error switching account type')),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
