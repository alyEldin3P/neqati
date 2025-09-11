import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_dimensions.dart';
import 'app_text.dart';

class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  final bool withBackground;

  const AppLoadingIndicator({
    Key? key,
    this.message,
    this.size = 40.0,
    this.color,
    this.withBackground = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loadingWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.deepTeal,
            ),
          ),
        ),
        if (message != null) ...[
          SizedBox(height: AppDimensions.medium),
          AppText(
            message!,
            textAlign: TextAlign.center,
            color: color ?? AppColors.deepTeal,
          ),
        ],
      ],
    );

    if (withBackground) {
      return Container(
        padding: EdgeInsets.all(AppDimensions.large),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: AppDimensions.cardElevation * 2,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: loadingWidget,
      );
    }

    return loadingWidget;
  }
}
