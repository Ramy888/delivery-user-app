import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Localizations/language_constants.dart';
import 'locale_utils.dart';
import 'dart:developer' as dev;

class PermissionManager {
  // Function to request the necessary permissions
  static Future<bool> requestStoragePermissions(BuildContext context) async {
    bool permissionGranted = false;
    if (Platform.isAndroid) {
      final androidVersion = Platform.version;
      final androidVersionComponents = androidVersion.split(' ');
      if (androidVersionComponents.length >= 3) {
        final androidApiVersion = int.tryParse(androidVersionComponents[2]);
        if (androidApiVersion != null && androidApiVersion < 33) {
          // Request storage permission for Android versions below API 33
          // Map<Permission, PermissionStatus> status = await [Permission.storage, Permission.photos].request();
          final status = await Permission.photos.request();
          // permissionGranted = status[Permission.storage] as bool;
          permissionGranted = status.isGranted;
        } else {
          // Request photo library permission for Android versions API 33 and above
          final status = await Permission.storage.request();
          permissionGranted = status.isGranted;
          dev.log(
              "Androidverion: ${androidApiVersion} state: ${permissionGranted}");
        }
      }
    } else if (Platform.isIOS) {
      // Request both photo library and storage permissions for iOS
      final status = await Permission.photos.request();

      permissionGranted = status.isGranted == true;
    }

    if (!permissionGranted) {
      if (!await Permission.storage.isGranted || !await Permission.photos.isGranted)
        showDialogPermissionRequired(context);
    }

    return permissionGranted;
  }

  // Function to show a dialog if permissions are not granted
  static void showDialogPermissionRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(getTranslated(context, "permissionRequired")!,
              style: TextStyle(
                fontFamily: LocaleUtils.getCurrentLang(context) == 'ar'
                    ? 'arFont'
                    : 'enBold',
              )),
          content: Text(getTranslated(context, "whyPermission")!,
          // content: Text(textWhy,
              style: TextStyle(
                fontFamily: LocaleUtils.getCurrentLang(context) == 'ar'
                    ? 'arFont'
                    : 'enBold',
              )),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                requestStoragePermissions(context); // Request permission again
              },
              child: Text(getTranslated(context, "ok")!,
                  style: TextStyle(
                    fontFamily: LocaleUtils.getCurrentLang(context) == 'ar'
                        ? 'arFont'
                        : 'enBold',
                  )),
            ),
          ],
        );
      },
    );
  }
}
