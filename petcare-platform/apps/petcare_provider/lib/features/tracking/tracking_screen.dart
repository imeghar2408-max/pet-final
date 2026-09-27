import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/theme.dart';
import '../chat/chat_screen.dart';

class ProviderTrackingScreen extends StatefulWidget {
  final Booking booking;
  const ProviderTrackingScreen({super.key, required this.booking});

  @override
  State<ProviderTrackingScreen> createState() => _ProviderTrackingScreenState();
}

class _ProviderTrackingScreenState extends State<ProviderTrackingScreen> {
  GoogleMapController? _mapController;
  late BookingSocket _socket;
  StreamSubscription<Position>? _positionSub;
  Timer? _sessionTimer;

  LatLng? _currentPosition;
  String? _safeZoneAlert;
  DateTime? _serviceStartTime;
  Duration _elapsed = Duration.zero;
  bool _isStreaming = false;
  bool _completing = false;
  DateTime? _lastPingTime;

  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);

  @override
  void initState() {
    super.initState();
    _serviceStartTime = DateTime.now();

    // Start active service session timer
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _serviceStartTime != null) {
        setState(() {
          _elapsed = DateTime.now().difference(_serviceStartTime!);
        });
      }
    });

    // Connect to Socket.IO location namespace
    _socket = BookingSocket(
      baseUrl: ApiConfig.baseUrl,
      namespace: 'location',
      bookingId: widget.booking.id,
    );

    // Listen for safe zone alerts calculated by backend
    _socket.socket.on('location:alert', (data) {
      if (!mounted) return;
      final inside = data['inside'] == true;
      setState(() {
        _safeZoneAlert = inside
            ? null
            : 'Safe Zone Alert: You have moved ${data['distanceM']}m from center (limit: ${data['radiusM']}m). Please return to the safe area.';
      });
    });

    _startActiveGpsStreaming();
  }

  Future<void> _startActiveGpsStreaming() async {
    // 1. Verify or request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device location permission is required for live service tracking.')),
        );
      }
      return;
    }

    // 2. Fetch initial real device GPS location
    try {
      final initialPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
      if (mounted) {
        final loc = LatLng(initialPos.latitude, initialPos.longitude);
        setState(() {
          _currentPosition = loc;
          _isStreaming = true;
          _lastPingTime = DateTime.now();
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 16));
        _emitLocationPing(initialPos.latitude, initialPos.longitude);
      }
    } catch (_) {}

    // 3. Continuously stream real device GPS coordinates with 10m distance filter
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (!mounted) return;
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentPosition = loc;
        _isStreaming = true;
        _lastPingTime = DateTime.now();
      });
      _emitLocationPing(pos.latitude, pos.longitude);
    });
  }

  void _emitLocationPing(double lat, double lng) {
    _socket.socket.emit('location:update', {
      'bookingId': widget.booking.id,
      'lat': lat,
      'lng': lng,
    });
  }

  Future<void> _stopGpsStreaming() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _socket.dispose();
    if (mounted) setState(() => _isStreaming = false);
  }

  Future<void> _completeService() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Service?'),
        content: Text(
          'Are you sure you want to complete this ${widget.booking.serviceType.label.toLowerCase()} session? Live GPS location sharing will stop immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: ProviderTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: ProviderTheme.sagePrimary),
            child: const Text('Complete Service'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _completing = true);

    try {
      // Stop GPS location stream
      await _stopGpsStreaming();

      // Call backend complete endpoint
      await _api.post('/bookings/${widget.booking.id}/complete');

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: ProviderTheme.sagePrimary),
                SizedBox(width: 8),
                Text('Service Completed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Great job! The session for ${widget.booking.petName ?? "the pet"} has ended.',
                  style: const TextStyle(fontSize: 14, color: ProviderTheme.charcoal),
                ),
                const SizedBox(height: 12),
                Text(
                  'Session duration: ${_formatDuration(_elapsed)}\nTotal fee: ₹${widget.booking.priceInr}',
                  style: const TextStyle(fontSize: 13, color: ProviderTheme.textMuted, height: 1.4),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true); // Return to home/active jobs
                },
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing service: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  void _recenterMap() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 16));
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _sessionTimer?.cancel();
    _socket.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final hasSafeZone = b.safeZoneLat != null && b.safeZoneLng != null && b.safeZoneRadiusM != null;
    final safeZoneCenter = hasSafeZone ? LatLng(b.safeZoneLat!, b.safeZoneLng!) : null;

    final initialCenter = _currentPosition ??
        (hasSafeZone ? safeZoneCenter! : LatLng(b.lat, b.lng));

    return Scaffold(
      backgroundColor: ProviderTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${b.serviceType.label} · ${b.petName ?? "Pet"}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              'Owner: ${b.otherPartyName ?? "Pet Owner"}',
              style: const TextStyle(fontSize: 12, color: ProviderTheme.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chat with Owner',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatScreen(booking: b)),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initialCenter, zoom: 15.5),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (ctrl) {
              _mapController = ctrl;
              if (_currentPosition != null) {
                ctrl.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 16));
              }
            },
            circles: {
              if (hasSafeZone && safeZoneCenter != null)
                Circle(
                  circleId: const CircleId('safeZone'),
                  center: safeZoneCenter,
                  radius: b.safeZoneRadiusM!.toDouble(),
                  fillColor: ProviderTheme.sagePrimary.withOpacity(0.12),
                  strokeColor: ProviderTheme.sagePrimary,
                  strokeWidth: 2,
                ),
            },
            markers: {
              if (_currentPosition != null)
                Marker(
                  markerId: const MarkerId('provider_live_location'),
                  position: _currentPosition!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  infoWindow: const InfoWindow(title: 'Your Location (Live)'),
                ),
              if (b.lat != 0.0 && b.lng != 0.0)
                Marker(
                  markerId: const MarkerId('service_destination'),
                  position: LatLng(b.lat, b.lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
                  infoWindow: InfoWindow(title: 'Service Address', snippet: b.addressText),
                ),
            },
          ),

          // Safe Zone Breach Alert
          if (_safeZoneAlert != null)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: ProviderTheme.coralLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ProviderTheme.coralBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: ProviderTheme.coralAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _safeZoneAlert!,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: ProviderTheme.coralAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Floating Recenter Button
          Positioned(
            right: 16,
            bottom: 230,
            child: FloatingActionButton.small(
              heroTag: 'recenter_provider_btn',
              backgroundColor: Colors.white,
              foregroundColor: ProviderTheme.charcoal,
              elevation: 2,
              onPressed: _recenterMap,
              child: const Icon(Icons.my_location, size: 20),
            ),
          ),

          // Bottom Session Status & Control Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: ProviderTheme.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isStreaming ? ProviderTheme.sagePrimary : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isStreaming ? 'Location sharing active' : 'Acquiring GPS...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isStreaming ? ProviderTheme.sagePrimary : ProviderTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatDuration(_elapsed),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ProviderTheme.charcoal,
                          fontFeatures: [],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: ProviderTheme.border),
                  const SizedBox(height: 12),

                  // Job Detail Row
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: ProviderTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.pets, size: 20, color: ProviderTheme.charcoal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${b.petName ?? "Pet"} · ${b.serviceType.label}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              b.addressText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: ProviderTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${b.priceInr}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: ProviderTheme.charcoal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Complete Service Action Button
                  ElevatedButton(
                    onPressed: _completing ? null : _completeService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProviderTheme.sagePrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _completing
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Complete Service'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
