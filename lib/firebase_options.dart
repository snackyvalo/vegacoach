import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBHnmU4EKyT7p7jcDu_YyISJrtLxlz59M8',
    appId: '1:885213017005:web:a5f6f00699a5ae00522724',
    messagingSenderId: '885213017005',
    projectId: 'vega-coach',
    authDomain: 'vega-coach.firebaseapp.com',
    storageBucket: 'vega-coach.firebasestorage.app',
    measurementId: 'G-C5Z285ZGR3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA7qzdKS_nCiX0JYSoBcCyOxGOpb8wAj0U',
    appId: '1:885213017005:android:594930efcfd77a34522724',
    messagingSenderId: '885213017005',
    projectId: 'vega-coach',
    storageBucket: 'vega-coach.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBHnmU4EKyT7p7jcDu_YyISJrtLxlz59M8',
    appId: '1:885213017005:ios:mockapp_id',
    messagingSenderId: '885213017005',
    projectId: 'vega-coach',
    storageBucket: 'vega-coach.firebasestorage.app',
  );
}
