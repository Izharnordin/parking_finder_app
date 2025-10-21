import 'package:flutter/material.dart';

class ParkingListPage extends StatelessWidget {
  const ParkingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking List"),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          ParkingListItem(
            location: 'Block A - Outdoor Lot',
            distance: '120m away',
            availableSpots: 5,
          ),
          ParkingListItem(
            location: 'Visitor Parking - North Zone',
            distance: '250m away',
            availableSpots: 2,
          ),
          ParkingListItem(
            location: 'Main Entrance Parking',
            distance: '400m away',
            availableSpots: 0,
          ),
        ],
      ),
    );
  }
}

class ParkingListItem extends StatelessWidget {
  final String location;
  final String distance;
  final int availableSpots;

  const ParkingListItem({
    super.key,
    required this.location,
    required this.distance,
    required this.availableSpots,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(
          Icons.local_parking,
          size: 35,
          color: availableSpots > 0 ? Colors.green : Colors.redAccent,
        ),
        title: Text(
          location,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(distance),
        trailing: Text(
          availableSpots > 0
              ? '$availableSpots spots'
              : 'Full',
          style: TextStyle(
            color: availableSpots > 0 ? Colors.green : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
