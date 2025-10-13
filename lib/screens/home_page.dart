import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Outdoor Parking Finder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF5F5F5), // light grey background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon (optional)
              const Icon(
                Icons.local_parking,
                size: 100,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),

              const Text(
                'Welcome to Smart Outdoor Parking Finder!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),

              // Find Parking button
              ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Find Parking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/map');
                },
              ),
              const SizedBox(height: 20),

              // View Parking List button
              ElevatedButton.icon(
                icon: const Icon(Icons.list),
                label: const Text('View Parking List'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/list');
                },
              ),
              const SizedBox(height: 20),

              // Settings button
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
