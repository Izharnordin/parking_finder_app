import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/map_page.dart';

void main() {
  runApp(const ParkingFinderApp());
}

class ParkingFinderApp extends StatelessWidget {
  const ParkingFinderApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Outdoor Parking Finder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 17, 19, 23)),
        useMaterial3: true,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomePage(),
        '/map': (context) => const MapPage(),
        // Future pages:
        '/list': (context) => const Placeholder(),
        '/settings': (context) => const Placeholder(),
      },
    );
  }
}
