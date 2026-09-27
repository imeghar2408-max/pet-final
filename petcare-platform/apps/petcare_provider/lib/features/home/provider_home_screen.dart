import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/theme.dart';
import '../../core/app_messenger.dart';
import '../bookings/requests_tab.dart';
import '../bookings/active_jobs_tab.dart';
import '../bookings/history_tab.dart';
import '../profile/provider_profile_tab.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _currentIndex = 0;
  bool _isAvailable = false;
  String _providerName = 'Provider';
  double? _ratingAvg;
  int _ratingCount = 0;

  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);

  @override
  void initState() {
    super.initState();
    _loadProfile();
    PushService.register(
      _api,
      onForegroundMessage: (message) {
        final text = message.notification?.body;
        if (text != null) showAppSnackBar(text);
      },
    );
  }

  Future<void> _loadProfile() async {
    try {
      final me = await _api.post('/auth/me');
      final data = me.data;
      if (data != null && mounted) {
        final p = data['providerProfile'];
        setState(() {
          _providerName = data['name'] ?? 'Provider';
          if (p != null) {
            _isAvailable = p['isAvailable'] ?? false;
            _ratingAvg = (p['ratingAvg'] as num?)?.toDouble();
            _ratingCount = p['ratingCount'] ?? 0;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _isAvailable = value);

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
          content: Text(value ? 'You are now Online and accepting requests.' : 'You are now Offline.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _isAvailable = !value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Booking Requests', 'Active Jobs', 'Service History', 'Provider Profile'];

    final pages = [
      RequestsTab(
        onRequestHandled: () {
          // Switch to Active Jobs tab when a request is accepted
          setState(() => _currentIndex = 1);
        },
      ),
      const ActiveJobsTab(),
      const HistoryTab(),
      const ProviderProfileTab(),
    ];

    return Scaffold(
      backgroundColor: ProviderTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titles[_currentIndex],
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            if (_currentIndex == 0 || _currentIndex == 1)
              Text(
                'Welcome, $_providerName',
                style: const TextStyle(fontSize: 12, color: ProviderTheme.textMuted, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _isAvailable ? ProviderTheme.sagePrimary : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isAvailable ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _isAvailable ? ProviderTheme.sagePrimary : ProviderTheme.textMuted,
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _isAvailable,
                    activeColor: ProviderTheme.sagePrimary,
                    onChanged: _toggleAvailability,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Active',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
