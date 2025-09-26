import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.deepTeal,
      colorScheme: ColorScheme.light(
        primary: AppColors.deepTeal,
        secondary: AppColors.goldAccent,
        surface: AppColors.white,
        background: AppColors.softWhite,
        error: AppColors.alertRed,
      ),
      scaffoldBackgroundColor: AppColors.softWhite,
      fontFamily: AppTextStyles.cairoFontFamily,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.largeTitle(),
        displayMedium: AppTextStyles.title(),
        displaySmall: AppTextStyles.subtitle(),
        bodyLarge: AppTextStyles.body(),
        bodyMedium: AppTextStyles.caption(),
        bodySmall: AppTextStyles.small(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.deepTeal,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.title(color: AppColors.white),
        iconTheme: IconThemeData(color: AppColors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepTeal,
          foregroundColor: AppColors.white,
          textStyle: AppTextStyles.buttonText(),
          elevation: AppDimensions.buttonElevation,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.buttonRadius)),
          minimumSize: Size(AppDimensions.buttonMinWidth, AppDimensions.buttonHeight),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepTeal,
          textStyle: AppTextStyles.buttonText(color: AppColors.deepTeal),
          side: BorderSide(color: AppColors.deepTeal, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.buttonRadius)),
          minimumSize: Size(AppDimensions.buttonMinWidth, AppDimensions.buttonHeight),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.deepTeal,
          textStyle: AppTextStyles.buttonText(color: AppColors.deepTeal),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.buttonRadius)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: AppDimensions.cardElevation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.cardRadius)),
        margin: EdgeInsets.all(AppDimensions.small),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: AppDimensions.medium, vertical: AppDimensions.small),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          borderSide: BorderSide(color: AppColors.neutralGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          borderSide: BorderSide(color: AppColors.neutralGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          borderSide: BorderSide(color: AppColors.deepTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          borderSide: BorderSide(color: AppColors.alertRed),
        ),
        labelStyle: AppTextStyles.body(color: AppColors.neutralGray),
        hintStyle: AppTextStyles.body(color: AppColors.lightText),
        errorStyle: AppTextStyles.small(color: AppColors.alertRed),
      ),
      dividerTheme: DividerThemeData(color: AppColors.divider, thickness: 1, space: AppDimensions.medium),
      iconTheme: IconThemeData(color: AppColors.deepTeal, size: AppDimensions.iconMedium),
    );
  }
}
