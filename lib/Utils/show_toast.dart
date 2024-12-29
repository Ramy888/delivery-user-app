import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';

class ToastUtil {
  static void showShortToast(String msg) {
    BotToast.showText(
      text: msg,
      duration: const Duration(seconds: 3),
      contentColor: Colors.black.withOpacity(0.5),
      textStyle: const TextStyle(color: Colors.white, fontSize: 16.0),
      align: const Alignment(0, 0.8),
    );
  }

  static void showLongToast(String msg) {
    BotToast.showText(
      text: msg,
      duration: const Duration(seconds: 5),
      contentColor: Colors.black.withOpacity(0.5),
      textStyle: const TextStyle(color: Colors.white, fontSize: 16.0),
      align: const Alignment(0, 0.8),
    );
  }

  static void showToastTop(String msg) {
    BotToast.showText(
      text: msg,
      duration: const Duration(seconds: 4),
      contentColor: Colors.black.withOpacity(0.5),
      textStyle: const TextStyle(color: Colors.white, fontSize: 15),
      align: const Alignment(0, -0.8), // Position at top
    );
  }

  static void showSimpleNotification(String txt, bool isShowing) {
    var cancel = BotToast.showSimpleNotification(
        title: txt,
        duration: const Duration(seconds: 3),
        titleStyle: const TextStyle(color: Colors.white, fontSize: 15),
        backgroundColor: Colors.black.withOpacity(0.5),
    );

    if(!isShowing){
      cancel();
    }
  }

  static void showHideLoading(bool isShowing) {
    if (!isShowing) {
      BotToast.closeAllLoading();
    }else{
      BotToast.showLoading();
    }
  }

}
