import 'package:flutter/material.dart';
import '../widgets/parking_card.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool showAvailableOnly = false; // Example toggle

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Nearby Parking Spots'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            tooltip: 'Filter available spots',
            onPressed: () {
              setState(() {
                showAvailableOnly = !showAvailableOnly;
              });
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // Map Placeholder (replace with Google Maps or IoT map later)
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: const Color(0xFFDDEBFF),
              child: const Center(
                child: Text(
                  '🗺️ Map Display Placeholder\n(Google Maps or IoT data view)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // Parking list / info cards
          Expanded(
            flex: 1,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: const [
                ParkingCard(
                  location: 'Block A - Outdoor Lot',
                  distance: '120m away',
                  availableSpots: 5,
                ),
                ParkingCard(
                  location: 'Visitor Parking - North Zone',
                  distance: '250m away',
                  availableSpots: 2,
                ),
                ParkingCard(
                  location: 'Main Entrance Parking',
                  distance: '400m away',
                  availableSpots: 0,
                ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
        },
        label: const Text('Back'),
        icon: const Icon(Icons.arrow_back),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
