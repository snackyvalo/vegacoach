import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/scan/scan_screen.dart';
import '../screens/coach/ai_coach_screen.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/neatqueue/neatqueue_screen.dart';
import '../screens/party/party_screen.dart';
import '../screens/main_layout.dart';
import '../screens/splash_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AuthStream extends ChangeNotifier {
  AuthStream() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}
final _authStream = AuthStream();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  refreshListenable: _authStream,
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
    final isSplash = state.matchedLocation == '/splash';

    if (isSplash) {
      return null;
    }

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    if (isLoggedIn && isAuthRoute) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/party',
      builder: (context, state) => const PartyScreen(),
    ),
    GoRoute(
      path: '/party/:id',
      builder: (context, state) => PartyScreen(initialRoomId: state.pathParameters['id']),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/scan',
          pageBuilder: (context, state) => const NoTransitionPage(child: ScanScreen()),
        ),
        GoRoute(
          path: '/coach',
          pageBuilder: (context, state) => const NoTransitionPage(child: AiCoachScreen()),
        ),
        GoRoute(
          path: '/shop',
          pageBuilder: (context, state) => const NoTransitionPage(child: ShopScreen()),
        ),
        GoRoute(
          path: '/stats',
          pageBuilder: (context, state) => const NoTransitionPage(child: StatsScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
        ),
        GoRoute(
          path: '/neatqueue',
          pageBuilder: (context, state) => const NoTransitionPage(child: NeatQueueScreen()),
        ),
      ],
    ),
  ],
);
