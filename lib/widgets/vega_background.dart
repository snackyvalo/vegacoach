import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VegaBackground extends StatelessWidget {
  final Widget child;
  final bool animate;

  const VegaBackground({super.key, required this.child, this.animate = true});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark background
        Container(color: const Color(0xFF0D0614)),
        // Top Left Vibrant Purple/Pink Glow
        Positioned(
          top: -200,
          left: -150,
          child: IgnorePointer(
            child: _buildOrb(
              color: const Color(0xFF9D00FF).withOpacity(0.4),
              size: 500,
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .move(begin: const Offset(0, 0), end: const Offset(50, 50), duration: 20.seconds, curve: Curves.easeInOutSine)
             .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 15.seconds, curve: Curves.easeInOut),
          ),
        ),
        // Bottom Right Deep Blue/Indigo Glow
        Positioned(
          bottom: -250,
          right: -100,
          child: IgnorePointer(
            child: _buildOrb(
              color: const Color(0xFF0038FF).withOpacity(0.35),
              size: 600,
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .move(begin: const Offset(0, 0), end: const Offset(-50, -50), duration: 25.seconds, curve: Curves.easeInOutSine)
             .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 18.seconds, curve: Curves.easeInOut),
          ),
        ),
        // Center-Right Accent Glow (Subtle Yellow/Gold for vibrancy)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          right: -200,
          child: IgnorePointer(
            child: _buildOrb(
              color: const Color(0xFFFFB800).withOpacity(0.15),
              size: 400,
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .move(begin: const Offset(0, 0), end: const Offset(-30, 30), duration: 22.seconds, curve: Curves.easeInOutSine),
          ),
        ),
        // Content
        SafeArea(child: child),
      ],
    );
  }

  Widget _buildOrb({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
