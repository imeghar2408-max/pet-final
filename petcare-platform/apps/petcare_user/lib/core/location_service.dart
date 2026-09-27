import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'theme.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String? addressName;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.addressName,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Explain to the user WHY location is needed before prompting system dialog
  Future<bool> showPermissionRationaleDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PetColors.sageLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_on_rounded, color: PetColors.sage, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Find Caregivers Nearby',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: PetColors.dark,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'PetCare uses your real device location to show verified pet walkers, groomers, and sitters available in your immediate neighborhood.',
              style: TextStyle(fontSize: 14, color: PetColors.darkMuted, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'During active walks, live GPS enables safe-zone monitoring so you always know your pet is secure.',
              style: TextStyle(fontSize: 13, color: PetColors.darkLight, height: 1.35),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not Now', style: TextStyle(color: PetColors.darkMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PetColors.dark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Request permission with explanation flow
  Future<Position?> acquirePosition({
    required BuildContext context,
    bool showRationaleFirst = true,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        _showServiceDisabledDialog(context);
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      if (showRationaleFirst && context.mounted) {
        final agreed = await showPermissionRationaleDialog(context);
        if (!agreed) return null;
      }

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showPermanentlyDeniedDialog(context);
      }
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _lastKnownPosition = pos;
      return pos;
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _lastKnownPosition = last;
        return last;
      }
      return null;
    }
  }

  void _showServiceDisabledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please turn on GPS / Location Services on your device to discover nearby pet care providers.',
          style: TextStyle(color: PetColors.darkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PetColors.dark, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermanentlyDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Location Permission Needed'),
        content: const Text(
          'Location access is permanently disabled for PetCare. To find nearby providers and track services, please grant location access in App Settings.',
          style: TextStyle(color: PetColors.darkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PetColors.dark, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text('Open App Settings'),
          ),
        ],
      ),
    );
  }
}
