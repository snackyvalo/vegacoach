import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/glass_container.dart';
import '../widgets/vega_background.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Determine the current index based on the route
    final String location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/scan')) currentIndex = 1;
    if (location.startsWith('/coach')) currentIndex = 2;
    if (location.startsWith('/shop')) currentIndex = 3;
    if (location.startsWith('/stats')) currentIndex = 4;
    if (location.startsWith('/neatqueue')) currentIndex = 5;
    if (location.startsWith('/profile')) currentIndex = 6;

    return Scaffold(
      extendBody: true, // Crucial for floating nav over background
      body: VegaBackground(child: child),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: GlassContainer(
            borderRadius: 30,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, Icons.dashboard_rounded, 'Home', 0, currentIndex),
                _buildNavItem(context, Icons.qr_code_scanner_rounded, 'Scan', 1, currentIndex),
                _buildNavItem(context, Icons.smart_toy_rounded, 'Coach', 2, currentIndex),
                _buildNavItem(context, Icons.storefront_rounded, 'Shop', 3, currentIndex),
                _buildNavItem(context, Icons.bar_chart_rounded, 'Stats', 4, currentIndex),
                _buildNavItem(context, Icons.queue_rounded, 'Queue', 5, currentIndex),
                _buildNavItem(context, Icons.person_rounded, 'Profile', 6, currentIndex),
              ],
            ),
          ).animate().slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index, int currentIndex) {
    final isSelected = index == currentIndex;
    
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0: context.go('/'); break;
          case 1: context.go('/scan'); break;
          case 2: context.go('/coach'); break;
          case 3: context.go('/shop'); break;
          case 4: context.go('/stats'); break;
          case 5: context.go('/neatqueue'); break;
          case 6: context.go('/profile'); break;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryContainer.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primaryContainer.withOpacity(0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppTheme.primaryContainer : AppTheme.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }
}
