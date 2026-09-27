import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/theme.dart';
import '../auth/phone_login_screen.dart';

class ProviderProfileTab extends StatefulWidget {
  const ProviderProfileTab({super.key});

  @override
  State<ProviderProfileTab> createState() => _ProviderProfileTabState();
}

class _ProviderProfileTabState extends State<ProviderProfileTab> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  bool _loading = true;
  bool _savingAvailability = false;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _provider;
  List<dynamic> _services = [];
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await _api.post('/auth/me');
      final data = res.data;
      if (data != null && mounted) {
        setState(() {
          _user = data;
          _provider = data['providerProfile'];
          _services = _provider?['servicesOffered'] ?? [];
          _isAvailable = _provider?['isAvailable'] ?? false;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() {
      _isAvailable = value;
      _savingAvailability = true;
    });

    double? lat;
    double? lng;

    if (value) {
      try {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 4),
          );
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (_) {}
    }

    try {
      await _api.post('/providers/availability', data: {
        'isAvailable': value,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'You are now Online and visible to pet owners.' : 'You are now Offline.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _isAvailable = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update availability: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingAvailability = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of your provider account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: ProviderTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: ProviderTheme.coralAccent),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final name = _user?['name'] ?? 'Pet Care Provider';
    final phone = _user?['phone'] ?? FirebaseAuth.instance.currentUser?.phoneNumber ?? '—';
    final email = _user?['email'] ?? 'Not set';
    final bio = _provider?['bio'] ?? 'Professional pet care provider dedicated to keeping your pets safe, exercised, and happy.';
    final years = _provider?['yearsExperience'] ?? 2;
    final ratingAvg = (_provider?['ratingAvg'] as num?)?.toDouble() ?? 5.0;
    final ratingCount = _provider?['ratingCount'] ?? 0;
    final verificationStatus = _provider?['verificationStatus'] ?? 'VERIFIED';

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: ProviderTheme.sagePrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ProviderTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: ProviderTheme.sageLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ProviderTheme.sageBorder),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, size: 32, color: ProviderTheme.sagePrimary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ProviderTheme.charcoal),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.verified, size: 15, color: ProviderTheme.sagePrimary),
                              const SizedBox(width: 4),
                              Text(
                                verificationStatus == 'VERIFIED' ? 'Verified Provider' : 'Pending Verification',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ProviderTheme.sagePrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: ProviderTheme.border),
                const SizedBox(height: 14),

                // Ratings and Experience
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rating', style: TextStyle(fontSize: 12, color: ProviderTheme.textMuted)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${ratingAvg.toStringAsFixed(1)} ($ratingCount reviews)',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ProviderTheme.charcoal),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Experience', style: TextStyle(fontSize: 12, color: ProviderTheme.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            '$years Years',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ProviderTheme.charcoal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Availability Switch Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ProviderTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isAvailable ? ProviderTheme.sagePrimary : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isAvailable ? 'Online for Bookings' : 'Currently Offline',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ProviderTheme.charcoal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isAvailable ? 'Pet owners nearby can discover and book you' : 'Toggle online to receive new booking requests',
                      style: const TextStyle(fontSize: 12, color: ProviderTheme.textMuted),
                    ),
                  ],
                ),
                Switch(
                  value: _isAvailable,
                  activeColor: ProviderTheme.sagePrimary,
                  onChanged: _savingAvailability ? null : _toggleAvailability,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Contact & Bio Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ProviderTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About & Contact',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ProviderTheme.charcoal),
                ),
                const SizedBox(height: 12),
                Text(
                  bio,
                  style: const TextStyle(fontSize: 13, color: ProviderTheme.charcoal, height: 1.4),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: ProviderTheme.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: ProviderTheme.textMuted),
                    const SizedBox(width: 8),
                    Text(phone, style: const TextStyle(fontSize: 13, color: ProviderTheme.charcoal)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 16, color: ProviderTheme.textMuted),
                    const SizedBox(width: 8),
                    Text(email, style: const TextStyle(fontSize: 13, color: ProviderTheme.charcoal)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Services Offered & Pricing Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ProviderTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Services Offered & Pricing',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ProviderTheme.charcoal),
                ),
                const SizedBox(height: 12),
                if (_services.isEmpty)
                  const Text('Dog Walking · ₹350 / session\nPet Sitting · ₹500 / session',
                      style: TextStyle(fontSize: 13, color: ProviderTheme.charcoal, height: 1.5))
                else
                  ..._services.map((s) {
                    final type = s['serviceType'] ?? '';
                    final price = s['priceInr'] ?? 350;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(type.toString().replaceAll('_', ' '), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                          Text('₹$price', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ProviderTheme.charcoal)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Log out Button
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 18, color: ProviderTheme.coralAccent),
            label: const Text('Log Out', style: TextStyle(color: ProviderTheme.coralAccent, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: ProviderTheme.coralBorder),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
