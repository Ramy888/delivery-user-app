import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final bool isBold;
  final double fontSize;
  final Color? color;
  final int? maxLines;
  final double? height;
  final TextOverflow? overFlow;
  final List<Shadow>? shadows;

  const AppText({
    Key? key,
    required this.text,
    this.isBold = false,
    this.fontSize = 16,
    this.color,
    this.maxLines,
    this.overFlow,
    this.shadows,
    this.height,
  }) : super(key: key);

  bool get isArabic => RegExp(r'[\u0600-\u06FF]').hasMatch(text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: isArabic ? 'Cairo' : 'Poppins',
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w300,
        fontSize: MediaQuery.of(context).textScaler.scale(fontSize),
        color: color,
        shadows: shadows,
        height: height,
      ),
      maxLines: maxLines,
      overflow: overFlow,
    );
  }
}
