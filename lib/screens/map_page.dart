import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  int _lastMarkerCount = -1;
  bool _didFitForThisBatch = false;
  bool _showAvailableOnly = false;

  // If navigated from list with coords, we’ll pan here
  LatLng? _focusPoint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> &&
        args.containsKey('lat') &&
        args.containsKey('lng')) {
      _focusPoint = LatLng(
        (args['lat'] as num).toDouble(),
        (args['lng'] as num).toDouble(),
      );
      _moveToPoint(_focusPoint!);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _moveToPoint(LatLng point) async {
    if (_mapController == null) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: point, zoom: 17),
      ),
    );
  }

  Set<Marker> _buildMarkers(List<QueryDocumentSnapshot> docs) {
    final markers = <Marker>{};

    for (final d in docs) {
      final spotId = d.id; // use doc id as canonical spot id
      final data = d.data() as Map<String, dynamic>;

      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final name = (data['name'] ?? spotId) as String;
      final status = (data['status'] ?? 'Unknown') as String;
      final availableSpots = data['available_spots'];

      final snippetBits = <String>[];
      if (availableSpots != null) snippetBits.add('$availableSpots spots');
      if (status.isNotEmpty)      snippetBits.add(status);
      final snippet = snippetBits.join(' • ');

      final hue = status.toLowerCase() == 'available'
          ? BitmapDescriptor.hueGreen
          : BitmapDescriptor.hueRed;

      markers.add(
        Marker(
          markerId: MarkerId(spotId),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(title: name, snippet: snippet),
          onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) => _SpotSheet(
                spotId: spotId,
                name: name,
                status: status,
                availableSpots: availableSpots is num ? availableSpots : null,
                lat: lat,
                lng: lng,
              ),
            );
          },
        ),
      );
    }

    return markers;
  }

  Future<void> _fitToMarkers(Set<Marker> markers) async {
    if (!mounted || _mapController == null || markers.isEmpty) return;

    if (markers.length == 1) {
      final pos = markers.first.position;
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: pos, zoom: 17),
        ),
      );
      return;
    }

    final lats = markers.map((m) => m.position.latitude).toList();
    final lngs = markers.map((m) => m.position.longitude).toList();

    final sw = LatLng(
      lats.reduce((a, b) => a < b ? a : b),
      lngs.reduce((a, b) => a < b ? a : b),
    );
    final ne = LatLng(
      lats.reduce((a, b) => a > b ? a : b),
      lngs.reduce((a, b) => a > b ? a : b),
    );
    final bounds = LatLngBounds(southwest: sw, northeast: ne);

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
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
            return const Center(child: Text('Error loading parking spots'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = _showAvailableOnly
              ? snapshot.data!.docs.where((d) {
                  final s = (d['status'] ?? '').toString().toLowerCase();
                  return s == 'available';
                }).toList()
              : snapshot.data!.docs;

          final markers = _buildMarkers(docs);

          // Fit camera only when marker count changes
          final count = markers.length;
          if (count != _lastMarkerCount) {
            _lastMarkerCount = count;
            _didFitForThisBatch = false;
          }
          if (!_didFitForThisBatch && count > 0) {
            _didFitForThisBatch = true;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _fitToMarkers(markers),
            );
          }

          // If we received a focus point from list, prioritize panning there once
          if (_focusPoint != null && _mapController != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _moveToPoint(_focusPoint!);
              _focusPoint = null; // consume once
            });
          }

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: const CameraPosition(
                  target: _klCenter,
                  zoom: 14,
                ),
                markers: markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: () => _fitToMarkers(markers),
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============= Bottom Sheet: Reserve / Cancel =============
class _SpotSheet extends StatefulWidget {
  final String spotId; // Firestore doc id of the spot
  final String name, status;
  final num? availableSpots;
  final double lat, lng;

  const _SpotSheet({
    required this.spotId,
    required this.name,
    required this.status,
    this.availableSpots,
    required this.lat,
    required this.lng,
  });

  @override
  State<_SpotSheet> createState() => _SpotSheetState();
}

class _SpotSheetState extends State<_SpotSheet> {
  bool _isLoading = false;
  String? _activeReservationId;

  @override
  void initState() {
    super.initState();
    _checkExistingReservation();
  }

  Future<void> _checkExistingReservation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('reservations')
        .where('user_id', isEqualTo: user.uid)
        .where('spot_id', isEqualTo: widget.spotId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (!mounted) return;
    if (snap.docs.isNotEmpty) {
      setState(() => _activeReservationId = snap.docs.first.id);
    }
  }

  Future<void> _reserveSpot() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to reserve a spot.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final expires = now.add(const Duration(minutes: 10));

      // Create reservation record
      final docRef = await FirebaseFirestore.instance
          .collection('reservations')
          .add({
        'user_id': user.uid,
        'spot_id': widget.spotId,
        'status': 'active', // active | cancelled | checked_in | expired
        'created_at': now,
        'expires_at': expires,
      });

      // Update the spot status + timestamp
      await FirebaseFirestore.instance
          .collection('parking_spots')
          .doc(widget.spotId)
          .update({
        'status': 'reserved',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _activeReservationId = docRef.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Spot reserved for 10 minutes')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reserving spot: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelReservation() async {
    if (_activeReservationId == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(_activeReservationId)
          .update({'status': 'cancelled'});

      await FirebaseFirestore.instance
          .collection('parking_spots')
          .doc(widget.spotId)
          .update({
        'status': 'available',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _activeReservationId = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation cancelled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling reservation: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = widget.status.toLowerCase() == 'available';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_parking,
                color: isAvailable ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Status: ${isAvailable ? "Available" : widget.status}'),
          if (widget.availableSpots != null)
            Text('Spots: ${widget.availableSpots}'),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_activeReservationId != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Reservation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _cancelReservation,
            )
          else if (isAvailable)
            ElevatedButton.icon(
              icon: const Icon(Icons.bookmark_add),
              label: const Text('Reserve Spot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _reserveSpot,
            )
          else
            const Text('This spot is not available right now.'),
        ],
      ),
    );
  }
}
