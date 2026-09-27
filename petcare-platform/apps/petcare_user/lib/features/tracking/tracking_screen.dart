import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/api_service.dart';
import '../../core/app_messenger.dart';
import '../../core/theme.dart';
import '../../widgets/petcare_button.dart';
import '../../widgets/status_badge.dart';
import '../booking/booking_detail_screen.dart';
import '../chat/chat_screen.dart';
import '../reviews/review_flow_screen.dart';
import '../support/report_issue_screen.dart';

class TrackingScreen extends StatefulWidget {
  final Booking booking;

  const TrackingScreen({super.key, required this.booking});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with SingleTickerProviderStateMixin {
  late BookingSocket _socket;
  GoogleMapController? _mapController;

  late LatLng _safeZoneCenter;
  double _safeZoneRadiusM = 500;
  bool _savingZone = false;

  LatLng? _providerLocation;
  bool _isInsideSafeZone = true;
  double? _distanceFromCenterM;
  DateTime? _lastPingAt;
  Timer? _relativeTimeTimer;
  String _lastUpdatedText = 'Waiting for provider signal...';
  bool _isConnected = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final b = widget.booking;
    _safeZoneCenter = LatLng(
      b.safeZoneLat ?? b.lat,
      b.safeZoneLng ?? b.lng,
    );
    _safeZoneRadiusM = (b.safeZoneRadiusM ?? 500).toDouble();

    // Pulse animation for LIVE badge
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(_pulseController);

    _relativeTimeTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateRelativeTime();
    });

    _initSocket();
  }

  void _initSocket() {
    _socket = BookingSocket(
      baseUrl: ApiConfig.baseUrl,
      namespace: 'location',
      bookingId: widget.booking.id,
    );

    _socket.socket.onConnect((_) {
      if (mounted) setState(() => _isConnected = true);
    });

    _socket.socket.onDisconnect((_) {
      if (mounted) setState(() => _isConnected = false);
    });

    _socket.socket.on('location:broadcast', (data) {
      if (mounted && data != null) {
        final lat = (data['lat'] as num).toDouble();
        final lng = (data['lng'] as num).toDouble();
        _onLocationReceived(LatLng(lat, lng));
      }
    });

    _socket.socket.on('location:update', (data) {
      if (mounted && data != null) {
        final lat = (data['lat'] as num).toDouble();
        final lng = (data['lng'] as num).toDouble();
        _onLocationReceived(LatLng(lat, lng));
      }
    });

    _socket.socket.on('location:alert', (data) {
      if (mounted && data != null) {
        final inside = data['inside'] == true;
        setState(() {
          _isInsideSafeZone = inside;
          if (data['distanceM'] != null) {
            _distanceFromCenterM = (data['distanceM'] as num).toDouble();
          }
        });
      }
    });
  }

  void _onLocationReceived(LatLng pos) {
    setState(() {
      _providerLocation = pos;
      _lastPingAt = DateTime.now();
      _distanceFromCenterM = _computeDistanceM(_safeZoneCenter, pos);
      _isInsideSafeZone = _distanceFromCenterM! <= _safeZoneRadiusM;
    });
    _updateRelativeTime();

    // Optionally animate camera if initialized
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(pos),
      );
    }
  }

  void _updateRelativeTime() {
    if (!mounted) return;
    if (_lastPingAt == null) {
      setState(() => _lastUpdatedText = _isConnected ? 'Signal acquired · waiting for movement' : 'Connecting to GPS...');
      return;
    }
    final diffSec = DateTime.now().difference(_lastPingAt!).inSeconds;
    if (diffSec < 3) {
      setState(() => _lastUpdatedText = 'Updated just now');
    } else if (diffSec < 60) {
      setState(() => _lastUpdatedText = 'Updated ${diffSec}s ago');
    } else {
      final mins = (diffSec / 60).floor();
      setState(() => _lastUpdatedText = 'Updated ${mins}m ago');
    }
  }

  double _computeDistanceM(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * 3.141592653589793 / 180;
    final dLng = (b.longitude - a.longitude) * 3.141592653589793 / 180;
    final sinLat = (dLat / 2);
    final sinLng = (dLng / 2);
    final val = (sinLat * sinLat) +
        (a.latitude * 3.141592653589793 / 180).abs() *
            (b.latitude * 3.141592653589793 / 180).abs() *
            (sinLng * sinLng);
    return 2 * r * val.abs();
  }

  Future<void> _showSafeZoneDialog() async {
    double tempRadius = _safeZoneRadiusM;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Adjust Safe Zone Radius', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current boundary: ${tempRadius.toInt()} meters around the start location.',
                style: const TextStyle(fontSize: 13, color: PetColors.darkMuted),
              ),
              const SizedBox(height: 16),
              Slider(
                value: tempRadius,
                min: 100,
                max: 2000,
                divisions: 19,
                activeColor: PetColors.dark,
                inactiveColor: PetColors.border,
                label: '${tempRadius.toInt()}m',
                onChanged: (v) => setDialogState(() => tempRadius = v),
              ),
              Text(
                '${tempRadius.toInt()} m',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PetColors.dark),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: PetColors.darkMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: PetColors.dark, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _saveSafeZone(tempRadius);
              },
              child: const Text('Save Radius'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSafeZone(double newRadius) async {
    setState(() => _savingZone = true);
    try {
      await UserApiService().updateSafeZone(
        bookingId: widget.booking.id,
        lat: _safeZoneCenter.latitude,
        lng: _safeZoneCenter.longitude,
        radiusM: newRadius.toInt(),
      );
      setState(() {
        _safeZoneRadiusM = newRadius;
        if (_distanceFromCenterM != null) {
          _isInsideSafeZone = _distanceFromCenterM! <= _safeZoneRadiusM;
        }
      });
      showAppSnackBar('Safe zone updated to ${newRadius.toInt()}m', isSuccess: true);
    } catch (e) {
      showAppSnackBar('Failed to update safe zone: $e', isError: true);
    } finally {
      if (mounted) setState(() => _savingZone = false);
    }
  }

  void _recenterMap() {
    if (_mapController == null) return;
    final target = _providerLocation ?? _safeZoneCenter;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 16),
      ),
    );
  }

  @override
  void dispose() {
    _relativeTimeTimer?.cancel();
    _pulseController.dispose();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;

    final markers = <Marker>{
      // Service Origin / Home
      Marker(
        markerId: const MarkerId('service_center'),
        position: _safeZoneCenter,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Service Start Location'),
      ),
      // Live Walker
      if (_providerLocation != null)
        Marker(
          markerId: const MarkerId('provider_live'),
          position: _providerLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _isInsideSafeZone ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: b.otherPartyName ?? 'Provider',
            snippet: _isInsideSafeZone ? 'Inside Safe Zone' : '⚠️ Outside Safe Zone',
          ),
        ),
    };

    final circles = <Circle>{
      Circle(
        circleId: const CircleId('safe_zone_circle'),
        center: _safeZoneCenter,
        radius: _safeZoneRadiusM,
        fillColor: (_isInsideSafeZone ? PetColors.sage : PetColors.error).withOpacity(0.12),
        strokeColor: _isInsideSafeZone ? PetColors.sage : PetColors.error,
        strokeWidth: 2,
      ),
    };

    return Scaffold(
      backgroundColor: PetColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${b.serviceType.label} with ${b.otherPartyName ?? 'Provider'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Row(
              children: [
                FadeTransition(
                  opacity: _pulseAnimation,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isConnected ? PetColors.success : PetColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _isConnected ? 'Live GPS Active' : 'Connecting...',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isConnected ? PetColors.success : PetColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Chat with Caretaker',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    bookingId: b.id,
                    otherPartyName: b.otherPartyName ?? 'Provider',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Booking Details',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookingDetailScreen(booking: b),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map View
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _safeZoneCenter,
              zoom: 15.5,
            ),
            markers: markers,
            circles: circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (ctrl) => _mapController = ctrl,
          ),

          // TOP ALERT BANNER (If outside safe zone)
          if (!_isInsideSafeZone)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: PetColors.error,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: PetColors.error.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Safe Zone Alert: Provider outside zone',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          if (_distanceFromCenterM != null)
                            Text(
                              '${_distanceFromCenterM!.toInt()}m from origin (Limit: ${_safeZoneRadiusM.toInt()}m)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // MAP CONTROLS (Recenter & Safe Zone)
          Positioned(
            right: 16,
            bottom: 220,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'recenter_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: PetColors.dark,
                  onPressed: _recenterMap,
                  child: const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'zone_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: PetColors.dark,
                  onPressed: _showSafeZoneDialog,
                  child: const Icon(Icons.radar_rounded),
                ),
              ],
            ),
          ),

          // BOTTOM TELEMETRY SHEET
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: PetColors.sageLight,
                            child: Text(
                              (b.otherPartyName?.isNotEmpty ?? false) ? b.otherPartyName![0] : 'P',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: PetColors.sage),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.otherPartyName ?? 'Caretaker',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: PetColors.dark,
                                ),
                              ),
                              Text(
                                _lastUpdatedText,
                                style: const TextStyle(fontSize: 12, color: PetColors.darkMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isInsideSafeZone ? PetColors.successBg : PetColors.errorBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isInsideSafeZone ? 'In Safe Zone' : 'Zone Breach',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _isInsideSafeZone ? PetColors.success : PetColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Safe Zone Limit', style: TextStyle(fontSize: 11.5, color: PetColors.darkLight)),
                            const SizedBox(height: 2),
                            Text('${_safeZoneRadiusM.toInt()} meters', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PetColors.dark)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Distance from Home', style: TextStyle(fontSize: 11.5, color: PetColors.darkLight)),
                            const SizedBox(height: 2),
                            Text(
                              _distanceFromCenterM != null ? '${_distanceFromCenterM!.toInt()} meters' : 'Tracking...',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PetColors.dark),
                            ),
                          ],
                        ),
                      ),
                    ],
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
