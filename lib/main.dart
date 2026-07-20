import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'routes/app_router.dart';
import 'providers/auth_provider.dart';
import 'firebase_options.dart';

import 'providers/voice_party_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed or not configured yet: $e');
  }

  runApp(const VegasCoachApp());
}

class VegasCoachApp extends StatefulWidget {
  const VegasCoachApp({super.key});

  @override
  State<VegasCoachApp> createState() => _VegasCoachAppState();
}

class _VegasCoachAppState extends State<VegasCoachApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    
    // Handle link when app is in background or foreground
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Deep link received: $uri');
      if (uri.host == 'party' && uri.pathSegments.isNotEmpty) {
        final roomId = uri.pathSegments.first;
        appRouter.go('/party/$roomId');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VoicePartyProvider()),
      ],
      child: MaterialApp.router(
        title: 'Vega\'s Coach',
        theme: AppTheme.darkTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
