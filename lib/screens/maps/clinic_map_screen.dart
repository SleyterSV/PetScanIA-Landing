import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:petscania/screens/home_screen.dart';
import 'package:petscania/screens/maps/clinic_detail_screen.dart';
import 'package:petscania/services/places_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _PinType { user, allied, generic }

class _ClinicPin {
  const _ClinicPin({
    required this.id,
    required this.position,
    required this.title,
    required this.subtitle,
    required this.type,
    this.clinic,
    this.distanceKm = 0,
  });

  final String id;
  final ll.LatLng position;
  final String title;
  final String subtitle;
  final _PinType type;
  final Map<String, dynamic>? clinic;
  final double distanceKm;
}

class ClinicMapScreen extends StatefulWidget {
  const ClinicMapScreen({super.key});

  @override
  State<ClinicMapScreen> createState() => _ClinicMapScreenState();
}

class _ClinicMapScreenState extends State<ClinicMapScreen> {
  static const ll.LatLng _initialPosition = ll.LatLng(-12.0464, -77.0428);

  final MapController _mapController = MapController();
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<_ClinicPin> _pins = const [];
  bool _isLoading = false;
  bool _mapReady = false;
  int _alliedCount = 0;
  int _nearbyCount = 0;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeMapAndLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeMapAndLocation() async {
    setState(() => _isLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          _currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      debugPrint('Advertencia de GPS: $e');
    } finally {
      await _loadAllClinics('');
    }
  }

  Future<void> _loadAllClinics(String query) async {
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = true);

    final List<_ClinicPin> nextPins = [];
    final baseLat = _currentPosition?.latitude ?? _initialPosition.latitude;
    final baseLng = _currentPosition?.longitude ?? _initialPosition.longitude;
    var alliedCount = 0;
    var nearbyCount = 0;

    if (_currentPosition != null) {
      nextPins.add(
        _ClinicPin(
          id: 'user_current_location',
          position: ll.LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          title: 'Mi ubicacion',
          subtitle: 'Estas aqui',
          type: _PinType.user,
        ),
      );
    }

    try {
      final googleClinics = await GooglePlacesService.searchVeterinaries(
        query,
        baseLat,
        baseLng,
      );
      for (final place in googleClinics) {
        final latValue = place['geometry']?['location']?['lat'];
        final lngValue = place['geometry']?['location']?['lng'];
        if (latValue == null || lngValue == null) {
          continue;
        }
        final lat = (latValue as num).toDouble();
        final lng = (lngValue as num).toDouble();
        nextPins.add(
          _ClinicPin(
            id: 'google_${place['place_id']}',
            position: ll.LatLng(lat, lng),
            title: (place['name'] ?? 'Centro veterinario').toString(),
            subtitle: 'Centro general',
            type: _PinType.generic,
          ),
        );
      }
    } catch (_) {
      debugPrint('Error Google Places.');
    }

    try {
      final data = await _supabase.from('clinics').select();
      final localClinics = List<dynamic>.from(data as List<dynamic>);
      for (final raw in localClinics) {
        final clinic = Map<String, dynamic>.from(raw as Map);
        final name = (clinic['name'] ?? '').toString().toLowerCase();
        if (query.isNotEmpty && !name.contains(query.toLowerCase())) {
          continue;
        }

        final lat = _readLatitude(clinic);
        final lng = _readLongitude(clinic);
        if (lat == null || lng == null) {
          continue;
        }

        final isAllied = _isAlliedClinic(clinic);

        var distance = 0.0;
        if (_currentPosition != null) {
          distance = GooglePlacesService.calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            lat,
            lng,
          );
          if (distance <= 15) {
            nearbyCount += 1;
          }
        }
        if (isAllied) {
          alliedCount += 1;
        }

        nextPins.add(
          _ClinicPin(
            id: 'supabase_${clinic['id']}',
            position: ll.LatLng(lat, lng),
            title: (clinic['name'] ?? 'Clinica').toString(),
            subtitle: isAllied
                ? 'Aliado PetScanIA - A ${GooglePlacesService.formatDistance(distance)}'
                : _currentPosition == null
                ? 'Centro medico'
                : 'Centro medico - A ${GooglePlacesService.formatDistance(distance)}',
            type: isAllied ? _PinType.allied : _PinType.generic,
            clinic: clinic,
            distanceKm: distance,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error consultando Supabase: $e');
    }

    if (!mounted) {
      return;
    }
    nextPins.sort((a, b) {
      if (a.type != b.type) {
        if (a.type == _PinType.user) return -1;
        if (b.type == _PinType.user) return 1;
        if (a.type == _PinType.allied && b.type != _PinType.allied) return -1;
        if (b.type == _PinType.allied && a.type != _PinType.allied) return 1;
      }
      return a.distanceKm.compareTo(b.distanceKm);
    });

    setState(() {
      _pins = nextPins;
      _isLoading = false;
      _alliedCount = alliedCount;
      _nearbyCount = nearbyCount;
    });

    if (_mapReady && _currentPosition != null) {
      _mapController.move(
        ll.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        14,
      );
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      return double.tryParse(normalized);
    }
    return null;
  }

  double? _readLatitude(Map<String, dynamic> clinic) {
    return _toDouble(clinic['latitude']) ??
        _toDouble(clinic['lat']) ??
        _toDouble(clinic['location_lat']);
  }

  double? _readLongitude(Map<String, dynamic> clinic) {
    return _toDouble(clinic['longitude']) ??
        _toDouble(clinic['lng']) ??
        _toDouble(clinic['lon']) ??
        _toDouble(clinic['location_lng']);
  }

  bool _dynamicToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value == 1;
    final text = value.toString().trim().toLowerCase();
    return text == 'true' ||
        text == '1' ||
        text == 'si' ||
        text == 'yes' ||
        text == 'y' ||
        text == 'active' ||
        text == 'approved' ||
        text == 'aliado';
  }

  bool _isAlliedClinic(Map<String, dynamic> clinic) {
    if (_dynamicToBool(clinic['is_allied']) ||
        _dynamicToBool(clinic['allied']) ||
        _dynamicToBool(clinic['is_partner']) ||
        _dynamicToBool(clinic['partner']) ||
        _dynamicToBool(clinic['is_verified'])) {
      return true;
    }

    final acceptedAt = clinic['terms_accepted_at']?.toString().trim();
    if (acceptedAt != null &&
        acceptedAt.isNotEmpty &&
        acceptedAt.toLowerCase() != 'null') {
      return true;
    }

    final plan = clinic['plan']?.toString().toLowerCase() ?? '';
    if (plan.contains('pro') ||
        plan.contains('premium') ||
        plan.contains('allied') ||
        plan.contains('aliado')) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 13,
              onMapReady: () {
                _mapReady = true;
                if (_currentPosition != null) {
                  _mapController.move(
                    ll.LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    14,
                  );
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.petscania.app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: _pins.map(_buildMarker).toList(growable: false),
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 15,
            right: 15,
            child: _buildSearchBar(),
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildLegendRibbon()),
          if (_isLoading) _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Marker _buildMarker(_ClinicPin pin) {
    final color = switch (pin.type) {
      _PinType.user => Colors.green,
      _PinType.allied => Colors.blue,
      _PinType.generic => Colors.red,
    };

    return Marker(
      point: pin.position,
      width: 52,
      height: 52,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () {
          if (pin.type == _PinType.allied && pin.clinic != null) {
            _showClinicProfile(pin.clinic!, pin.distanceKm);
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${pin.title}: ${pin.subtitle}')),
          );
        },
        child: Icon(Icons.location_on_rounded, color: color, size: 44),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A),
              size: 20,
            ),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre, ej. Mundo Vet...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 5),
              ),
              onSubmitted: _loadAllClinics,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8)),
            onPressed: () => _loadAllClinics(_searchController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRibbon() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 35),
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 15,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(
            iconColor: Colors.blue,
            title: 'Aliados PetScanIA',
            description: '$_alliedCount aliados activos',
          ),
          Container(width: 1, height: 35, color: Colors.grey[300]),
          _buildLegendItem(
            iconColor: Colors.red,
            title: 'Otros Centros',
            description: '$_nearbyCount cercanos (<=15 km)',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_rounded, color: iconColor, size: 22),
            const SizedBox(width: 5),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const CircularProgressIndicator(color: Color(0xFF38BDF8)),
      ),
    );
  }

  void _showClinicProfile(Map<String, dynamic> clinic, double distance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClinicDetailScreen(clinic: clinic, distance: distance),
      ),
    );
  }
}
