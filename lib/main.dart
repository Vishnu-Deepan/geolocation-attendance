import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // Import the permission_handler package
import 'screens/home_page.dart';
import 'screens/login_page.dart';

void main() async {
  // Ensure Flutter bindings are initialized before using platform channels (important for Firebase and location services)
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Request location permission before running the app
  await _requestLocationPermission();

  // Listen for authentication state changes
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      // User is logged in, navigate to the HomeScreen
      runApp(MyApp(user: user));
    } else {
      // No user logged in, navigate to the LoginScreen
      runApp(MyApp(user: null));
    }
  });
}

Future<void> _requestLocationPermission() async {
  // Check if location permission is granted
  PermissionStatus status = await Permission.location.request();

  // If permission is not granted, you can show a message to the user
  if (status.isDenied) {
    print("Location permission denied.");
  } else if (status.isPermanentlyDenied) {
    // If permission is permanently denied, open app settings
    print("Location permission permanently denied.");
    openAppSettings();
  } else if (status.isGranted) {
    print("Location permission granted.");
  }
}

class MyApp extends StatelessWidget {
  final User? user;

  MyApp({this.user});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Authentication',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        primaryColor: Colors.blueAccent,
      ),
      home: user == null ? LoginScreen() : HomeScreen(user: user),
    );
  }
}
