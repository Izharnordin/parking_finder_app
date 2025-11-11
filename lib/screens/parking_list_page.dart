import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ParkingListPage extends StatefulWidget {
  const ParkingListPage({super.key});

  @override
  State<ParkingListPage> createState() => _ParkingListPageState();
}

enum SpotState { free, available, reserved, occupied, unknown }

class _ParkingListPageState extends State<ParkingListPage> {
  bool _showAvailableOnly = false;

  // ------------ Helpers ------------
  SpotState _parseState(dynamic raw) {
    final s = (raw ?? '').toString().toLowerCase().trim();
    switch (s) {
      case 'free':
      case 'available':
        return SpotState.free;
      case 'reserved':
        return SpotState.reserved;
      case 'occupied':
        return SpotState.occupied;
      default:
        return SpotState.unknown;
    }
  }

  bool _isFree(SpotState st) => st == SpotState.free || st == SpotState.available;

  Color _colorFor(SpotState st) {
    switch (st) {
      case SpotState.free:
      case SpotState.available:
        return Colors.green;
      case SpotState.reserved:
        return Colors.orange;
      case SpotState.occupied:
        return Colors.red;
      case SpotState.unknown:
        return Colors.blueGrey;
    }
  }

  String _labelFor(SpotState st) {
    switch (st) {
      case SpotState.free:
      case SpotState.available:
        return 'Available';
      case SpotState.reserved:
        return 'Reserved';
      case SpotState.occupied:
        return 'Occupied';
      case SpotState.unknown:
        return 'Unknown';
    }
  }

  String _ago(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking List'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            tooltip: _showAvailableOnly ? 'Show all' : 'Show available only',
            icon: Icon(_showAvailableOnly ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () => setState(() => _showAvailableOnly = !_showAvailableOnly),
          ),
        ],
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

          final allDocs = snapshot.data!.docs;
          final docs = _showAvailableOnly
              ? allDocs.where((d) => _isFree(_parseState((d.data() as Map<String, dynamic>)['status']))).toList()
              : allDocs;

          if (docs.isEmpty) {
            return const Center(child: Text('No parking spots found.'));
          }

          final total = allDocs.length;
          final availableCount = allDocs.where((d) => _isFree(_parseState((d.data() as Map<String, dynamic>)['status']))).length;

          return Column(
            children: [
              // Small live counter header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.black.withOpacity(0.05),
                child: Text(
                  'Available: $availableCount / $total',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final data = Map<String, dynamic>.from(docs[i].data() as Map);
                    final name = (data['name'] ?? 'Unnamed Spot').toString();
                    final st = _parseState(data['status']);
                    final availableSpots = data['available_spots'];
                    final updatedAt = data['updated_at'] is Timestamp ? data['updated_at'] as Timestamp : null;
                    final lat = (data['latitude'] as num?)?.toDouble();
                    final lng = (data['longitude'] as num?)?.toDouble();

                    final chips = <String>[
                      if (availableSpots != null) '${availableSpots} spots',
                      _labelFor(st),
                      if (updatedAt != null) 'Updated ${_ago(updatedAt)}',
                    ].join(' • ');

                    return ListTile(
                      leading: Icon(Icons.local_parking, color: _colorFor(st), size: 30),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(chips),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
