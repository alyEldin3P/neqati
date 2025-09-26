import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Arabic Font Families
  static const String cairoFontFamily = 'Cairo';
  static const String tajawalFontFamily = 'Tajawal';

  // Headings
  static TextStyle largeTitle({Color? color, FontWeight? fontWeight}) =>
      TextStyle(
        fontFamily: tajawalFontFamily,
        fontSize: 24,
        fontWeight: fontWeight ?? FontWeight.bold,
        color: color ?? AppColors.darkText,
        height: 1.3,
      );

  static TextStyle title({Color? color, FontWeight? fontWeight}) => TextStyle(
    fontFamily: tajawalFontFamily,
    fontSize: 20,
    fontWeight: fontWeight ?? FontWeight.bold,
    color: color ?? AppColors.darkText,
    height: 1.3,
  );

  static TextStyle subtitle({Color? color, FontWeight? fontWeight}) =>
      TextStyle(
        fontFamily: tajawalFontFamily,
        fontSize: 18,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.darkText,
        height: 1.3,
      );

  // Body Text
  static TextStyle body({Color? color, FontWeight? fontWeight}) => TextStyle(
    fontFamily: cairoFontFamily,
    fontSize: 16,
    fontWeight: fontWeight ?? FontWeight.normal,
    color: color ?? AppColors.mediumText,
    height: 1.5,
  );

  static TextStyle caption({Color? color, FontWeight? fontWeight}) => TextStyle(
    fontFamily: cairoFontFamily,
    fontSize: 14,
    fontWeight: fontWeight ?? FontWeight.normal,
    color: color ?? AppColors.lightText,
    height: 1.4,
  );

  static TextStyle small({Color? color, FontWeight? fontWeight}) => TextStyle(
    fontFamily: cairoFontFamily,
    fontSize: 12,
    fontWeight: fontWeight ?? FontWeight.normal,
    color: color ?? AppColors.lightText,
    height: 1.4,
  );

  static TextStyle medium({Color? color, FontWeight? fontWeight}) => TextStyle(
    fontFamily: tajawalFontFamily,
    fontSize: 16,
    fontWeight: fontWeight ?? FontWeight.w600,
    color: color ?? AppColors.darkText,
    height: 1.3,
  );

  // Button Text
  static TextStyle buttonText({Color? color}) => TextStyle(
    fontFamily: cairoFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.white,
    letterSpacing: 0.5,
  );
}
