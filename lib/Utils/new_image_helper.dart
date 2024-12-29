import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

// class ImageHelper2 {
//   static Future<XFile?> compress({required File image}) async {
//     final dir = await getTemporaryDirectory();
//     final targetPath = path.join(dir.absolute.path, "temp.jpg");
//
//     var result = await FlutterImageCompress.compressAndGetFile(
//       image.absolute.path,
//       targetPath,
//       quality: 88, // Adjust the quality as needed
//       minWidth: 1000, // Adjust the dimensions as needed
//       minHeight: 1000,
//     );
//
//     return result;
//   }
//
//   static Future<File?> cropImage(File image, BuildContext context) async {
//     // Implement cropping logic
//     return image; // Placeholder return
//   }
// }


// import 'package:image_cropper/image_cropper.dart';

// class ImageHelper2 {
//   static Future<File> compress({required File image}) async {
//     final filePath = image.absolute.path;
//     final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
//     final splitted = filePath.substring(0, lastIndex);
//     final outPath = "${splitted}_out${filePath.substring(lastIndex)}";
//
//     var result = await FlutterImageCompress.compressAndGetFile(
//       image.absolute.path,
//       outPath,
//       quality: 78,  // Adjust the quality as needed
//       minWidth: 500,  // Optional: Resize the image to reduce file size
//       minHeight: 500,
//     );
//
//     if (result != null) {
//       return File(result.path);  // Make sure to convert it back to File if needed
//     } else {
//       throw Exception("Failed to compress image.");
//     }
//   }

  // static Future<File?> cropImage(File image, BuildContext context) async {
  //   File? croppedFile = await ImageCropper.cropImage(
  //     sourcePath: image.path,
  //     aspectRatioPresets: [
  //       CropAspectRatioPreset.square,
  //       CropAspectRatioPreset.ratio3x2,
  //       CropAspectRatioPreset.original,
  //     ],
  //     androidUiSettings: AndroidUiSettings(
  //         toolbarTitle: 'Crop your image',
  //         toolbarColor: Colors.deepOrange,
  //         toolbarWidgetColor: Colors.white,
  //         initAspectRatio: CropAspectRatioPreset.original,
  //         lockAspectRatio: false),
  //     iosUiSettings: IOSUiSettings(
  //       title: 'Crop your image',
  //     ),
  //   );
  //   return croppedFile;
  // }



class ImageHelper2 {

  static Future<File> compress({
    required File image,
    int quality = 70,
    int minWidth = 400,
    int minHeight = 400,
    Function(bool)? onLoading,
  }) async {
    final filePath = image.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
    final splitted = filePath.substring(0, lastIndex);
    final outPath = "${splitted}_out${filePath.substring(lastIndex)}";

    // Notify to show spinner
    onLoading?.call(true);

    try {
      // Read the image from file
      Uint8List imageBytes = await image.readAsBytes();
      img.Image? baseSizeImage = img.decodeImage(imageBytes);

      // Resize if needed
      img.Image resizedImage = img.copyResize(baseSizeImage!, width: minWidth, height: minHeight);

      // Compress the image
      List<int> compressedBytes = img.encodeJpg(resizedImage, quality: quality);

      // Write the compressed image to a new file
      File outFile = File(outPath);
      await outFile.writeAsBytes(compressedBytes);

      return outFile;
    } finally {
      // Notify to hide spinner
      onLoading?.call(false);
    }
  }


}
