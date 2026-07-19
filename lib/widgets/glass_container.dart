import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 24.0, // Updated to 24px per Liquid Glass specs
    this.color,
    this.borderColor,
    this.blur = 20.0, // Increased to 20px
  });

  @override
  Widget build(BuildContext context) {
    // Reduced blur for better performance on Android while keeping the aesthetic
    final double optimizedBlur = blur > 12.0 ? 12.0 : blur;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: optimizedBlur, sigmaY: optimizedBlur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.12),
                width: 1.0,
              ),
              gradient: color == null ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.02),
                ],
              ) : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
