import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eb3at/Localizations/language_constants.dart';
import 'package:eb3at/Models/model_message.dart';
import 'package:eb3at/Utils/locale_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:developer' as dev;

import '../API/firestore_operations.dart';
import '../Utils/new_image_helper.dart';
import '../Utils/permission_manager.dart';
import '../Utils/shared_prefs.dart';
import '../Utils/show_toast.dart';
import '../Utils/string_to_date_util.dart';

class ChatRequestPage extends StatefulWidget {
  final String requestType;
  final String pickUpLocation;
  final String dropOffLocation;
  final String expectedFees;
  final String reqId;

  ChatRequestPage({
    required this.requestType,
    required this.pickUpLocation,
    required this.dropOffLocation,
    required this.expectedFees,
    required this.reqId,
  });

  @override
  State<ChatRequestPage> createState() => _ChatRequestPageState();
}

class _ChatRequestPageState extends State<ChatRequestPage> {
  // FlutterEasyPermission? _easyPermission;
  // static const permissions = [Permissions.READ_EXTERNAL_STORAGE];
  //
  // static const permissionGroup = [PermissionGroup.Photos];
  static const platform = MethodChannel('com.pyramids/permissions');

  List<String> _selectedImages = [];
  TextEditingController _messageController = TextEditingController();
  final ValueNotifier<bool> _isTextNotEmpty = ValueNotifier<bool>(false);

  List<ModelMessage> _messageList = [];
  bool _isSending = false;
  bool _isSelecting = false;
  bool _isOfferActionTaken = false;
  String chat_status = 'pending';
  String userEmail = '';
  String userPhoto = '';
  String userRating = '';
  FireStoreApi _fireStoreApi = FireStoreApi();

  void _initialize() async {
    userEmail = (await SharedPreferenceHelper().getUserEmail())!;
    // userPhoto = await SharedPreferenceHelper().retrieveImagePath()!;

    // Start listening to chat messages
    _fireStoreApi.getChatMessages(widget.reqId).listen(_loadChatMessages);
  }

  void _loadChatMessages(QuerySnapshot snapshot) async {
    final messages = snapshot.docs.map((doc) {
      // Parse the message
      final messageData =
          ModelMessage.fromJson(doc.data() as Map<String, dynamic>);

      // If the message is an 'offer', fetch additional user data
      // if (messageData.msgType == 'offer') {
      //   final userDoc = await FirebaseFirestore.instance
      //       .collection('users')
      //       .doc(messageData.msgAuthor)
      //       .get();
      //
      //   if (userDoc.exists) {
      //     final userData = userDoc.data()!;
      //     messageData.userRating = userData['userRating'];
      //     messageData.userPhoto = userData['userPhoto'];
      //   }
      // }

      dev.log("showMeFetchedMessage:: ${messageData}");

      return messageData;
    }).toList();

    setState(() {
      _messageList = messages;
    });
  }

  @override
  void initState() {
    // if (Platform.isIOS) {
    //   _easyPermission = FlutterEasyPermission()
    //     ..addPermissionCallback(
    //       onGranted: (requestCode, perms, perm) {
    //         _selectPhotoFromGallery();
    //         debugPrint("Android Authorized:$perms");
    //         debugPrint("iOS Authorized:$perm");
    //       },
    //       onDenied: (requestCode, perms, perm, isPermanent) {
    //         if (isPermanent) {
    //           // FlutterEasyPermission.showAppSettingsDialog(title: "Photo");
    //           PermissionManager.showDialogPermissionRequired(context);
    //         } else {
    //           debugPrint("Android Deny authorization:$perms");
    //           debugPrint("iOS Deny authorization:$perm");
    //         }
    //       },
    //     );
    // }
    _initialize();
    super.initState();
    _messageController.addListener(() {
      _isTextNotEmpty.value = _messageController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    // if (Platform.isIOS) {
    //   _easyPermission!.dispose();
    // }
    // WidgetsBinding.instance.removeObserver(this);
    // if (_timer != null) {
    //   _timer?.cancel();
    // }
    // _prefs!.setString("chatId", "");
    _messageController.dispose();
    _isTextNotEmpty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLTR = LocaleUtils.getCurrentLang(context) == 'en';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '${widget.requestType}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: MediaQuery.of(context).textScaler.scale(14),
            fontFamily: isLTR ? 'enBold' : 'arBold',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Show newest messages at the bottom
              itemCount: _messageList.length,
              itemBuilder: (context, index) {
                final message = _messageList[index];

                return _buildChatBubble(context, message);
              },
            ),
          ),

          // user input Selected images preview (above text field)
          if (_selectedImages.isNotEmpty)
            Container(
              height: 100,
              // padding: EdgeInsets.symmetric(vertical: 8.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_selectedImages[index]),
                              width: 100, height: 100),
                        ),
                      ),
                      Positioned(
                        top: -10,
                        right: -5,
                        child: IconButton(
                          icon: Icon(Icons.cancel, color: Colors.grey.shade300),
                          onPressed: () => _removeImage(index),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // Message input field
          chat_status == 'pending'
              ? Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        // Text field for message
                        Expanded(
                          child: TextFormField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 5, // Allow multiple lines of input
                            decoration: InputDecoration(
                              hintText:
                                  '${getTranslated(context, "typeMessage")}',
                              hintStyle: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).textScaler.scale(14),
                                fontFamily: isLTR ? 'enLight' : 'arLight',
                              ),
                              labelStyle: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).textScaler.scale(14),
                                fontFamily: isLTR ? 'enLight' : 'arLight',
                              ),
                              // border: OutlineInputBorder(
                              //     borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Image picker button
                        IconButton(
                          icon: const Icon(Icons.photo, color: Colors.purple),
                          onPressed: () {
                            if (!_isSending) {
                              //   if (Platform.isIOS) {
                              //     FlutterEasyPermission.request(
                              //         perms: permissions,
                              //         permsGroup: permissionGroup,
                              //         rationale: "Permission is required");
                              //     FlutterEasyPermission.has(
                              //             perms: permissions,
                              //             permsGroup: permissionGroup)
                              //         .then((value) => value
                              //             ? debugPrint("Authorized")
                              //             : debugPrint("not Authorized"));
                              //   } else {
                              checkPermissions();
                              //   }
                            }
                          },
                        ),
                        // Send button
                        _isSending
                            ? const SizedBox(
                                width: 15.0, // Set the width
                                height: 15.0, // Set the height
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.brown,
                                  ),
                                  strokeWidth: 1.5,
                                ),
                              )
                            : ValueListenableBuilder<bool>(
                                valueListenable: _isTextNotEmpty,
                                builder: (context, isNotEmpty, child) {
                                  return IconButton(
                                    icon: Icon(
                                      Icons.send,
                                      color: isNotEmpty
                                          ? Colors.purple
                                          : Colors.grey,
                                    ),
                                    onPressed:
                                        isNotEmpty || _selectedImages.isNotEmpty
                                            ? _sendMessage
                                            : null,
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text('${getTranslated(context, "chat_closed")}'),
                ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty && _selectedImages.isEmpty) {
      // Don't send empty messages
      ToastUtil.showShortToast("${getTranslated(context, "addMessage")}");
      return;
    } else if (_isSelecting) {
      ToastUtil.showShortToast("${getTranslated(context, "waitImage")}");
      return;
    } else if (chat_status != 'pending') {
      ToastUtil.showShortToast("${getTranslated(context, "chat_closed")}");
      return;
    }

    _addNewMessage();
  }

  void _addNewMessage() async{
    List<String> imgsUrls = [];

    setState(() {
      _isSending = true;
    });

    if(_selectedImages.isNotEmpty){
      imgsUrls = await _fireStoreApi.uploadImages(context, _selectedImages);
    }

    _fireStoreApi.addMessage(
      requestId: widget.reqId,
      msgText: _messageController.text,
      msgImagesFilesUrls: imgsUrls,
      // to be modified
      msgType: 'request',
      msgAuthor: userEmail,
      msgCreatedAt: DateTime.now().toString(),
      msgStatus: 'sent',
      userRating: '',
      //changeable variable
      userPhoto: userPhoto,
      userNumberOfRequestsOrDeliveries: '12', //changeable variable
    );

    setState(() {
      _messageList.insert(
        0,
        ModelMessage(
          msgId: '',
          msgType: 'request',
          msgAuthor: userEmail,
          msgCreatedAt: DateTime.now().toString(),
          msgStatus: 'sent',
          msgText: _messageController.text,
          msgImagesFilesUrls: [],
          requestId: widget.reqId,
        ),
      );
      _messageController.clear();
      _isSending = false;
    });
  }

  Widget _buildChatBubble(BuildContext context, ModelMessage message) {
    bool isUserMessage = message.msgType == 'request';
    bool _LTR = LocaleUtils.getCurrentLang(context) == 'en';

    return Directionality(
      textDirection: _LTR ? TextDirection.ltr : TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align avatar to the bottom
          mainAxisAlignment:
              isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUserMessage)
              Column(
                children: [
                  CircleAvatar(
                    radius: 25,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: message.userPhoto!,
                        width: 50,
                        height: 50,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            Image.asset('assets/images/logo.png'),
                      ),
                    ),
                  ),
                  Center(
                    child: Row(
                      children: [
                        if (message.userRating != null) ...[
                          const Icon(Icons.star,
                              color: Colors.orange, size: 14),
                          Text(
                            '${message.userRating}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: isUserMessage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (isUserMessage) _buildUserRequestBubble(context, message),
                  if (!isUserMessage)
                    _buildDeliveryOfferBubble(context, message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRequestBubble(BuildContext context, ModelMessage message) {
    return Container(
      width: MediaQuery.of(context).size.width * 2 / 3,
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.msgText?.isNotEmpty ?? false)
            Text(
              message.msgText!,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          const SizedBox(height: 5),
          if (message.msgImagesFilesUrls?.isNotEmpty ?? false)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: message.msgImagesFilesUrls!.map((url) {
                return GestureDetector(
                  onTap: () => _openMaximizedImage(url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: 100,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          Image.asset('assets/images/logo.png'),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 5),
          Text(
            StringToDateUtil.formatToRelativeDay(message.msgCreatedAt),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOfferBubble(BuildContext context, ModelMessage message) {
    return Container(
      width: MediaQuery.of(context).size.width * 2 / 3,
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Text(
              StringToDateUtil.formatToRelativeDay(message.msgCreatedAt),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
          Row(
            children: [
              Text(
                '${getTranslated(context, "offer")}: ${message.msgText} ${getTranslated(context, "egp")}',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          !_isOfferActionTaken
              ?
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () => _acceptOffer(message),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child:  Text('${getTranslated(context, "accept")}', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _rejectOffer(message),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child:  Text('${getTranslated(context, "reject")}', style: TextStyle(fontSize: 12)),
              ),
            ],
          ) : Container(),
        ],
      ),
    );
  }

  void _acceptOffer(ModelMessage m) {
    final totalAmount = double.tryParse(m.msgText!) ?? 0.0;

    final double vat = totalAmount * 0.14;
    final double profit = totalAmount * 0.15;
    final double deliveryFees = totalAmount - (vat + profit);

    final String vatString = vat.toStringAsFixed(2);
    final String profitString = profit.toStringAsFixed(2);
    final String deliveryFeesString = deliveryFees.toStringAsFixed(2);

    _fireStoreApi.updateOfferStatus(
        requestId: widget.reqId,
        messageId: m.msgId,
        offerStatus: 'accepted',
        reqVat: vatString,
        reqAcceptedDeliveryFees: deliveryFeesString,
        reqAppProfit: profitString,
    );

    setState(() {
      _isOfferActionTaken = true;
    });
  }

  void _rejectOffer(ModelMessage m) {

    _fireStoreApi.updateOfferStatus(
      requestId: widget.reqId,
      messageId: m.msgId,
      offerStatus: 'rejected',
    );

    setState(() {
      _isOfferActionTaken = true;
    });
  }

  void _openMaximizedImage(String imgUrl) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Scaffold(
          body: Stack(
            children: [
              PhotoView(
                imageProvider: NetworkImage(imgUrl),
                minScale: PhotoViewComputedScale.covered * 0.7,
                maxScale: PhotoViewComputedScale.covered * 2,
                backgroundDecoration: BoxDecoration(color: Colors.black),
              ),
              Positioned(
                top: 70,
                right: 10,
                child: IconButton(
                  icon: Icon(Icons.cancel, color: Colors.grey, size: 30),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
      isScrollControlled: true,
    );
  }

  Future<void> checkPermissions() async {
    if (Platform.isAndroid) {
      try {
        final bool result = await platform.invokeMethod('checkPermissions');
        if (result) {
          print("Permission granted");
          _selectPhotoFromGallery();
        } else {
          print("Permission denied");
          PermissionManager.showDialogPermissionRequired(context);
        }
      } on PlatformException catch (e) {
        print("Failed to get permissions: '${e.message}'.");
      }
    } else if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (status.isDenied) {
        // Request the permission
        if (await Permission.photos.request().isGranted) {
          // Permission granted, proceed with accessing the photo library
          _selectPhotoFromGallery();
        } else {
          // Permission denied, handle accordingly
          PermissionManager.showDialogPermissionRequired(context);
        }
      } else if (status.isPermanentlyDenied) {
        // Permission permanently denied, open app settings
        await openAppSettings();
      }
    }
  }

  Future<void> _selectPhotoFromGallery() async {
    final ImagePicker picker = ImagePicker();

    // Pick multiple images
    final List<XFile>? images = await picker.pickMultiImage(limit: 5);

    if (images != null && images.isNotEmpty) {
      if (images.length >= 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${getTranslated(context, "maxPhotosLimitReached")}'),
          ),
        );
      }
      setState(() {
        _isSelecting = true; // Update loading state while picking files
      });

      for (XFile image in images) {
        File imageFile = File(image.path);
        // Compress the image
        // final compressedImage = await _compressImage(imageFile);
        var _compressedImage = await ImageHelper2.compress(image: imageFile);

        if (_selectedImages.length < 6) {
          // Add the compressed image to the selected list
          setState(() {
            _selectedImages.add(_compressedImage.path);
          });
        } else {
          return;
        }
      }

      setState(() {
        _isSelecting = false; // Stop loading when done
      });
    } else {
      // Handle case where no file was selected
      ToastUtil.showShortToast("${getTranslated(context, "noPhotoSelected")}");
    }
  }

  // Future<File> _compressImage(File imageFile) async {
  //   final lastIndex = imageFile.absolute.path.lastIndexOf(RegExp(r'.jp'));
  //
  //   final compressedFile = await FlutterImageCompress.compressAndGetFile(
  //     imageFile.absolute.path,
  //     '${imageFile.parent.path}/compressed_${imageFile.absolute.path.substring(lastIndex)}',
  //     quality: 80, // Adjust quality as needed
  //   );
  //
  //   return compressedFile;
  // }

  // Future<void> _selectPhotoFromGallery() async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(
  //       type: FileType.image,
  //       allowMultiple: true, // Allow multiple image selection
  //       onFileLoading: (FilePickerStatus status) {
  //         if (status == FilePickerStatus.picking) {
  //           setState(() {
  //             _isSelecting = true; // Update loading state while picking files
  //           });
  //         } else {
  //           setState(() {
  //             _isSelecting = false; // Stop loading when done
  //           });
  //         }
  //       },
  //   );
  //
  //   if (result != null && result.files.isNotEmpty) {
  //     // Process each selected image file
  //     for (PlatformFile file in result.files) {
  //       if (file.path != null) {
  //         File image = File(file.path!);
  //
  //         // Before compression size
  //         final _sizeInKbBefore = image.lengthSync() / 1024;
  //         print('Before Compress $_sizeInKbBefore kb');
  //
  //         // Compress the image
  //         var _compressedImage = await ImageHelper2.compress(image: image);
  //
  //         // After compression size
  //         final _sizeInKbAfter = _compressedImage.lengthSync() / 1024;
  //         print('After Compress $_sizeInKbAfter kb');
  //
  //         // Add the compressed image to the selected list
  //         setState(() {
  //           _selectedImages.add(_compressedImage.path);
  //         });
  //       }
  //     }
  //   } else {
  //     // Handle case where no file was selected
  //     ToastUtil.showShortToast("${getTranslated(context, "noPhotoSelected")}");
  //   }
  // }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
}
