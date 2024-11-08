// File generated by FlutterFire CLI.
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyCc_5LbmBDoM8irTJ6Y9309s6o5fFRFOqA',
    appId: '1:291601062167:web:40e3786d6b5d9969c4ff52',
    messagingSenderId: '291601062167',
    projectId: 'meal-21843',
    authDomain: 'meal-21843.firebaseapp.com',
    storageBucket: 'meal-21843.firebasestorage.app',
    measurementId: 'G-KGVRTWWG76',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAjQ1KG9SoC-ajClWuOZ_1HlM0hBmqKrj4',
    appId: '1:291601062167:android:4d2d6c5cf07f1fc3c4ff52',
    messagingSenderId: '291601062167',
    projectId: 'meal-21843',
    storageBucket: 'meal-21843.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB3RqxmGpTTdsR_n3LkYUcLkZTHhoWRdmM',
    appId: '1:291601062167:ios:74ece4bd2c057f12c4ff52',
    messagingSenderId: '291601062167',
    projectId: 'meal-21843',
    storageBucket: 'meal-21843.firebasestorage.app',
    iosBundleId: 'com.example.meal',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB3RqxmGpTTdsR_n3LkYUcLkZTHhoWRdmM',
    appId: '1:291601062167:ios:74ece4bd2c057f12c4ff52',
    messagingSenderId: '291601062167',
    projectId: 'meal-21843',
    storageBucket: 'meal-21843.firebasestorage.app',
    iosBundleId: 'com.example.meal',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCc_5LbmBDoM8irTJ6Y9309s6o5fFRFOqA',
    appId: '1:291601062167:web:15f858cfd582e7e6c4ff52',
    messagingSenderId: '291601062167',
    projectId: 'meal-21843',
    authDomain: 'meal-21843.firebaseapp.com',
    storageBucket: 'meal-21843.firebasestorage.app',
    measurementId: 'G-0CE19CDJXJ',
  );

}