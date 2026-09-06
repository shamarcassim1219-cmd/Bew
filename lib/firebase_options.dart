import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBdfFpevNs4uflfio_M8zpsep2fqonkkmg',
    appId: '1:1050625555685:android:234224eed485932e8fa80c',
    messagingSenderId: '1050625555685',
    projectId: 'gamestore-7e350',
    storageBucket: 'gamestore-7e350.firebasestorage.app',
  );
}
