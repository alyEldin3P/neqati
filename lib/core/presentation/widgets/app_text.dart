import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isTitle;
  final bool isSubtitle;
  final bool isCaption;
  final bool isSmall;
  final Color? color;
  final FontWeight? fontWeight;

  const AppText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isTitle = false,
    this.isSubtitle = false,
    this.isCaption = false,
    this.isSmall = false,
    this.color,
    this.fontWeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle;

    if (isTitle) {
      textStyle = AppTextStyles.title(color: color, fontWeight: fontWeight);
    } else if (isSubtitle) {
      textStyle = AppTextStyles.subtitle(color: color, fontWeight: fontWeight);
    } else if (isCaption) {
      textStyle = AppTextStyles.caption(color: color, fontWeight: fontWeight);
    } else if (isSmall) {
      textStyle = AppTextStyles.small(color: color, fontWeight: fontWeight);
    } else {
      textStyle = AppTextStyles.body(color: color, fontWeight: fontWeight);
    }

    return Text(
      text,
      style: style ?? textStyle,
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: TextDirection.rtl, // RTL for Arabic
    );
  }

  // Factory constructors for different text styles
  factory AppText.title(
    String text, {
    Key? key,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    Color? color,
    FontWeight? fontWeight,
  }) {
    return AppText(
      text,
      key: key,
      isTitle: true,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      color: color,
      fontWeight: fontWeight,
    );
  }

  factory AppText.subtitle(
    String text, {
    Key? key,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    Color? color,
    FontWeight? fontWeight,
  }) {
    return AppText(
      text,
      key: key,
      isSubtitle: true,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      color: color,
      fontWeight: fontWeight,
    );
  }

  factory AppText.caption(
    String text, {
    Key? key,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    Color? color,
    FontWeight? fontWeight,
  }) {
    return AppText(
      text,
      key: key,
      isCaption: true,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      color: color,
      fontWeight: fontWeight,
    );
  }

  factory AppText.small(
    String text, {
    Key? key,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    Color? color,
    FontWeight? fontWeight,
  }) {
    return AppText(
      text,
      key: key,
      isSmall: true,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      color: color,
      fontWeight: fontWeight,
    );
  }
}
