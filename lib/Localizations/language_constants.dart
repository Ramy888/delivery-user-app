import 'package:flutter/material.dart';
import 'package:eb3at/Localizations/demo_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';



const String LAGUAGE_CODE = 'languageCode';

//languages code
const String ENGLISH = 'en';
const String ARABIC = 'ar';

Future<Locale> setLocale(String languageCode) async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  await _prefs.setString(LAGUAGE_CODE, languageCode);
  // await LocaleManager.setLocale(languageCode); // Sets the locale to French
  return _locale(languageCode);
}

Future<Locale> getLocale() async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  String languageCode = _prefs.getString(LAGUAGE_CODE) ?? "en";
  // String languageCode = await LocaleManager.getLocale(); // Returns 'ar' or 'en'
  return _locale(languageCode);
}



Locale _locale(String languageCode) {
  switch (languageCode) {
    case ENGLISH:
      return const Locale(ENGLISH, 'US');
    case ARABIC:
      return const Locale(ARABIC, "EG");
    default:
      return const Locale(ENGLISH, 'US');
  }
}

String? getTranslated(BuildContext context, String key) {
  return DemoLocalization.of(context).translate(key);
}
