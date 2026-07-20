import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    // Wait for the Firebase Auth to read token
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      if (FirebaseAuth.instance.currentUser != null) {
        context.go('/');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png', // Assuming this exists or falls back safely
              width: 120,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.sports_esports,
                size: 80,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
            ),
          ],
        ),
      ),
    );
  }
}
