import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAJnPbMDcWyGsYQLn7j_0JYoxD5SIp9L2c',
    appId: '1:292195971249:android:a66c8dd6fca0b62ed40eba',
    messagingSenderId: '292195971249',
    projectId: 'saper-dimond',
    databaseURL: 'https://saper-dimond-default-rtdb.firebaseio.com',
    storageBucket: 'saper-dimond.appspot.com',
  );
}
