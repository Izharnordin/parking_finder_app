import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(3.1390, 101.6869); // Kuala Lumpur

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Parking"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 14.0,
        ),
        markers: {
          const Marker(
            markerId: MarkerId("spot1"),
            position: LatLng(3.1392, 101.6865),
            infoWindow: InfoWindow(title: "Parking Spot 1", snippet: "Available"),
          ),
          const Marker(
            markerId: MarkerId("spot2"),
            position: LatLng(3.1385, 101.6872),
            infoWindow: InfoWindow(title: "Parking Spot 2", snippet: "Occupied"),
          ),
        },
      ),
    );
  }
}
