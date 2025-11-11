import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

enum SpotState { free, available, reserved, occupied, unknown }

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;

  // Fallback center (Kuala Lumpur)
  static const LatLng _klCenter = LatLng(3.1390, 101.6869);

  int _lastMarkerCount = -1;
  bool _didFitForThisBatch = false;
  bool _showAvailableOnly = false;

  // If navigated from list with coordinates, pan here
  LatLng? _focusPoint;

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

  double _hueFor(SpotState st) {
    switch (st) {
      case SpotState.free:
      case SpotState.available:
        return BitmapDescriptor.hueGreen;
      case SpotState.reserved:
        return BitmapDescriptor.hueOrange;
      case SpotState.occupied:
        return BitmapDescriptor.hueRed;
      case SpotState.unknown:
        return BitmapDescriptor.hueAzure;
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
      final data = Map<String, dynamic>.from(d.data() as Map);


      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final name = (data['name'] ?? spotId).toString();
      final st = _parseState(data['status']);
      final availableSpots = data['available_spots'];
      final updatedAt = data['updated_at'] is Timestamp ? data['updated_at'] as Timestamp : null;

      final snippetBits = <String>[];
      if (availableSpots != null) snippetBits.add('$availableSpots spots');
      final label = _labelFor(st);
      if (label.isNotEmpty) snippetBits.add(label);
      final ago = _ago(updatedAt);
      if (ago.isNotEmpty) snippetBits.add('Updated $ago');
      final snippet = snippetBits.join(' • ');

      final hue = _hueFor(st);

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
                initialName: name,
                initialLat: lat,
                initialLng: lng,
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

          final allDocs = snapshot.data!.docs;
          final docs = _showAvailableOnly
              ? allDocs.where((d) => _isFree(_parseState((d.data() as Map<String, dynamic>)['status']))).toList()
              : allDocs;

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

          // Top-right availability pill
          final total = allDocs.length;
          final availableCount = allDocs.where((d) => _isFree(_parseState((d.data() as Map<String, dynamic>)['status']))).length;

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
                top: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Available: $availableCount / $total',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
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

// ============= Bottom Sheet (now live-updating) =============
class _SpotSheet extends StatefulWidget {
  final String spotId; // Firestore doc id of the spot
  final String initialName;
  final double initialLat, initialLng;

  const _SpotSheet({
    required this.spotId,
    required this.initialName,
    required this.initialLat,
    required this.initialLng,
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
    final docRef = FirebaseFirestore.instance.collection('parking_spots').doc(widget.spotId);

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snap) {
        final raw = snap.data?.data();
        final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
        final name = (data['name'] ?? widget.initialName).toString();
        final st = _parseState(data['status']);
        final isAvailable = st == SpotState.free || st == SpotState.available;
        final availableSpots = data['available_spots'];
        final updatedAt = data['updated_at'] is Timestamp ? data['updated_at'] as Timestamp : null;

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
                    color: isAvailable
                        ? Colors.green
                        : (st == SpotState.reserved ? Colors.orange : Colors.red),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Status: ${_labelFor(st)}'),
              if (availableSpots != null) Text('Spots: $availableSpots'),
              if (updatedAt != null) Text('Updated: ${_ago(updatedAt)}'),
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
      },
    );
  }

  // Reuse helpers inside the sheet
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
}
