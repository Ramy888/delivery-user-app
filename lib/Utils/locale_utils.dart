import 'package:flutter/material.dart';

class LocaleUtils {
  static String getCurrentLang(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }
}
