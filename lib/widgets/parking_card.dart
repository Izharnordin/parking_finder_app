import 'package:flutter/material.dart';

class ParkingCard extends StatelessWidget {
  final String location;
  final String distance;
  final int availableSpots;

  const ParkingCard({
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
