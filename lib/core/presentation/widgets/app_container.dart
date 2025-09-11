import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_dimensions.dart';

class AppContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? borderRadius;
  final double? elevation;
  final Border? border;
  final bool hasShadow;
  final double? width;
  final double? height;
  final Alignment? alignment;
  final Function()? onTap;

  const AppContainer({
    Key? key,
    required this.child,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.elevation,
    this.border,
    this.hasShadow = true,
    this.width,
    this.height,
    this.alignment,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        alignment: alignment,
        margin: margin ?? EdgeInsets.all(AppDimensions.small),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.white,
          borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.cardRadius),
          border: border,
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: elevation ?? AppDimensions.cardElevation * 2,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.cardRadius),
          child: Padding(
            padding: padding ?? EdgeInsets.all(AppDimensions.medium),
            child: child,
          ),
        ),
      ),
    );
  }
}
