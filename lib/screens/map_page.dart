import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;

  // Fallback center (Kuala Lumpur)
  static const LatLng _klCenter = LatLng(3.1390, 101.6869);

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // Build markers from Firestore docs
  Set<Marker> _buildMarkers(List<QueryDocumentSnapshot> docs) {
    final markers = <Marker>{};

    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;

      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final name = (data['name'] ?? 'Parking Spot') as String;
      final status = (data['status'] ?? 'Unknown') as String;
      final availableSpots = data['available_spots'];
      final snippetParts = <String>[];

      if (availableSpots != null) snippetParts.add('$availableSpots spots');
      snippetParts.add(status);
      final snippet = snippetParts.join(' • ');

      final hue = status.toString().toLowerCase() == 'available'
          ? BitmapDescriptor.hueGreen
          : BitmapDescriptor.hueRed;

      markers.add(
        Marker(
          markerId: MarkerId(d.id),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(title: name, snippet: snippet),
        ),
      );
    }

    return markers;
  }

  // Optionally fit camera to all markers
  Future<void> _fitToMarkers(Set<Marker> markers) async {
    if (_mapController == null || markers.isEmpty) return;

    final latitudes = markers.map((m) => m.position.latitude).toList();
    final longitudes = markers.map((m) => m.position.longitude).toList();

    final sw = LatLng(
      latitudes.reduce((a, b) => a < b ? a : b),
      longitudes.reduce((a, b) => a < b ? a : b),
    );
    final ne = LatLng(
      latitudes.reduce((a, b) => a > b ? a : b),
      longitudes.reduce((a, b) => a > b ? a : b),
    );

    final bounds = LatLngBounds(southwest: sw, northeast: ne);

    // Animate after the first frame to avoid "CameraUpdate.newLatLngBounds" issues on web
    await Future.delayed(const Duration(milliseconds: 200));
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Nearby Parking"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parking_spots')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading parking spots'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final markers = _buildMarkers(docs);

          // Fit the camera to markers when they load
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitToMarkers(markers);
          });

          return GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _klCenter,
              zoom: 14,
            ),
            markers: markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          );
        },
      ),
    );
  }
}
