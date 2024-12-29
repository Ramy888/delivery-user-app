import 'package:flutter/cupertino.dart';

class Language {
  final int id;
  final String flag;
  final String name;
  final String languageCode;

  Language(this.id, this.flag, this.name, this.languageCode);

  static List<Language> languageList() {
    return <Language>[
      Language(1, "assets/images/en.png", "English", "en"),
      //arabic egypt
      Language(2, "assets/images/ar.png", "العربية", "ar"),
    ];
  }
}
