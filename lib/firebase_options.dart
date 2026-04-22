import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform: $defaultTargetPlatform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBAAsfFHn8k8Jj2ixDeXJh9Vo_hSSImabY',
    appId: '1:181388128583:android:3f8d5508c0ef20ae52dc62',
    messagingSenderId: '181388128583',
    projectId: 'sorta-3df17',
    storageBucket: 'sorta-3df17.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBcM2o9mDAHVmFBkKFxb4NZdeBZ_aSs1EM',
    appId: '1:181388128583:ios:b03da52704e77cd552dc62',
    messagingSenderId: '181388128583',
    projectId: 'sorta-3df17',
    storageBucket: 'sorta-3df17.firebasestorage.app',
    iosBundleId: 'com.sorta.sorta',
  );
}
