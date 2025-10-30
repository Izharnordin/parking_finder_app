import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/map_page.dart';
import 'screens/settings_page.dart';
import 'screens/profile_page.dart';
import 'screens/signup_page.dart';
import 'screens/parking_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCjhQiN2och7k_c0ByG7KLy5MjA8Tf4Lts", 
      authDomain: "parking-finder-app-f9f0d.firebaseapp.com",
      projectId: "parking-finder-app-f9f0d",
      storageBucket: "parking-finder-app-f9f0d.firebasestorage.app",
      messagingSenderId: "340914607999",
      appId: "1:340914607999:web:0a758dd69fd8f1c725ac4a", 
      measurementId: "G-MNVPYENGQR"
      )
  );
  runApp(const ParkingFinderApp());
}

class ParkingFinderApp extends StatelessWidget {
  const ParkingFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Outdoor Parking Finder',
      theme: ThemeData.light(),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/signup': (context) => const SignUpPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/map': (context) => const MapPage(),
        '/list': (context) => const ParkingListPage(), 
        '/settings': (context) => SettingsPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
