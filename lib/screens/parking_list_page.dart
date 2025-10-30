import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ParkingListPage extends StatelessWidget {
  const ParkingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking List'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('parking_spots').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading data'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No parking spots found.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final name = (data['name'] ?? 'Unnamed Spot') as String;
              final status = (data['status'] ?? 'Unknown') as String;
              final availableSpots = data['available_spots'];
              final lat = (data['latitude'] as num?)?.toDouble();
              final lng = (data['longitude'] as num?)?.toDouble();

              final isAvailable = status.toLowerCase() == 'available';
              final color = isAvailable ? Colors.green : Colors.red;

              return ListTile(
                leading: Icon(Icons.local_parking, color: color, size: 30),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${availableSpots ?? 0} spots • ${isAvailable ? "Available" : "Occupied"}',
                ),
                trailing: const Icon(Icons.map),
                onTap: () {
                  if (lat != null && lng != null) {
                    Navigator.pushNamed(
                      context,
                      '/map',
                      arguments: {'lat': lat, 'lng': lng},
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
