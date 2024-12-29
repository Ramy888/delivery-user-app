import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Localizations/language_constants.dart';
import '../Utils/new_image_helper.dart';
import '../Utils/permission_manager.dart';
import '../Utils/show_toast.dart';

class PhotoSelectionField extends StatefulWidget {
  final Function(List<String>) onPhotosSelected;
  final String hintText;
  final int maxPhotos;

  const PhotoSelectionField({
    Key? key,
    required this.onPhotosSelected,
    this.hintText = 'Add up to 5 photos...',
    this.maxPhotos = 5,
  }) : super(key: key);

  @override
  State<PhotoSelectionField> createState() => _PhotoSelectionFieldState();
}

class _PhotoSelectionFieldState extends State<PhotoSelectionField> {
  final List<File> _selectedPhotos = [];
  final List<String> _selectedImages = [];
  bool _isSelecting = false;
  static const platform = MethodChannel('com.pyramids/permissions');

  // Future<void> _pickImage() async {
  //   if (_selectedPhotos.length >= widget.maxPhotos) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Maximum ${widget.maxPhotos} photos allowed'),
  //         behavior: SnackBarBehavior.floating,
  //       ),
  //     );
  //     return;
  //   }
  //
  //   try {
  //     final XFile? image = await _picker.pickImage(
  //       source: ImageSource.gallery,
  //       imageQuality: 80,
  //     );
  //
  //     if (image != null) {
  //       setState(() {
  //         _selectedPhotos.add(File(image.path));
  //       });
  //       widget.onPhotosSelected(_selectedPhotos);
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Failed to pick image'),
  //         behavior: SnackBarBehavior.floating,
  //       ),
  //     );
  //   }
  // }
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

      widget.onPhotosSelected(_selectedImages);

      setState(() {
        _isSelecting = false; // Stop loading when done
      });
    } else {
      // Handle case where no file was selected
      ToastUtil.showShortToast("${getTranslated(context, "noPhotoSelected")}");
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
      _selectedImages.removeAt(index);
    });
    widget.onPhotosSelected(_selectedImages);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue[300]!),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Photo Grid
          if (_selectedPhotos.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _selectedPhotos.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_selectedPhotos[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: _selectedPhotos.isEmpty
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.hintText,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontFamily: _isArabic(widget.hintText)
                          ? 'Cairo'
                          : 'Poppins',
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.blue[300],
                  ),
                  onPressed: checkPermissions,
                ),
              ],
            ),
          ),

          // Counter
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${_selectedPhotos.length}/${widget.maxPhotos} photos',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: _isArabic(widget.hintText)
                        ? 'Cairo'
                        : 'Poppins',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }
}
