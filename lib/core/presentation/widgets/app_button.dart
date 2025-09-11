import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_dimensions.dart';
import '../../utils/app_text_styles.dart';

enum AppButtonType { primary, secondary, text }

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;
  final double? height;

  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    switch (widget.type) {
      case AppButtonType.primary:
        return _buildElevatedButton(isDisabled);
      case AppButtonType.secondary:
        return _buildOutlinedButton(isDisabled);
      case AppButtonType.text:
        return _buildTextButton(isDisabled);
    }
  }

  Widget _buildElevatedButton(bool isDisabled) {
    return SizedBox(
      width: widget.isFullWidth ? double.infinity : widget.width,
      height: widget.height ?? AppDimensions.buttonHeight,
      child: ElevatedButton(
        onPressed: isDisabled ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? AppColors.neutralGray : AppColors.deepTeal,
          disabledBackgroundColor: AppColors.neutralGray.withOpacity(0.5),
          disabledForegroundColor: AppColors.white.withOpacity(0.7),
        ),
        child: _buildButtonContent(AppColors.white),
      ),
    );
  }

  Widget _buildOutlinedButton(bool isDisabled) {
    return SizedBox(
      width: widget.isFullWidth ? double.infinity : widget.width,
      height: widget.height ?? AppDimensions.buttonHeight,
      child: OutlinedButton(
        onPressed: isDisabled ? null : widget.onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDisabled ? AppColors.neutralGray : AppColors.deepTeal,
          side: BorderSide(
            color: isDisabled ? AppColors.neutralGray : AppColors.deepTeal,
            width: 1.5,
          ),
          disabledForegroundColor: AppColors.neutralGray.withOpacity(0.5),
        ),
        child: _buildButtonContent(AppColors.deepTeal),
      ),
    );
  }

  Widget _buildTextButton(bool isDisabled) {
    return SizedBox(
      width: widget.isFullWidth ? double.infinity : widget.width,
      height: widget.height ?? AppDimensions.buttonHeight,
      child: TextButton(
        onPressed: isDisabled ? null : widget.onPressed,
        style: TextButton.styleFrom(
          foregroundColor: isDisabled ? AppColors.neutralGray : AppColors.deepTeal,
          disabledForegroundColor: AppColors.neutralGray.withOpacity(0.5),
        ),
        child: _buildButtonContent(AppColors.deepTeal),
      ),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (widget.isLoading) {
      return SizedBox(
        width: AppDimensions.iconMedium,
        height: AppDimensions.iconMedium,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: AppDimensions.iconMedium),
          SizedBox(width: AppDimensions.small),
          Text(
            widget.text,
            style: AppTextStyles.buttonText(color: textColor),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: AppTextStyles.buttonText(color: textColor),
      textAlign: TextAlign.center,
    );
  }
}
