import 'package:flutter/material.dart';
import 'screens/home_page.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomePage(),
        // Future pages:
        '/map': (context) => const Placeholder(), // temporary
        '/list': (context) => const Placeholder(),
        '/settings': (context) => const Placeholder(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Outdoor Parking Finder"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Welcome to Smart Parking Finder!",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
