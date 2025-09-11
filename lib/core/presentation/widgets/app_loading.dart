import 'package:flutter/material.dart';

class AppLoading extends StatelessWidget {
  final Color? color;
  final double size;
  final double strokeWidth;

  const AppLoading({
    Key? key,
    this.color,
    this.size = 40.0,
    this.strokeWidth = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: color ?? Theme.of(context).primaryColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}
