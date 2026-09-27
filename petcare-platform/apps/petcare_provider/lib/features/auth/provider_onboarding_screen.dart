import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/theme.dart';
import '../home/provider_home_screen.dart';

class ProviderOnboardingScreen extends StatefulWidget {
  final String phone;
  const ProviderOnboardingScreen({super.key, required this.phone});

  @override
  State<ProviderOnboardingScreen> createState() => _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends State<ProviderOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController(text: '2');
  final _radiusController = TextEditingController(text: '8');
  
  bool _isAvailable = true;
  bool _locationPermissionGranted = false;
  bool _submitting = false;

  final Map<ServiceType, bool> _selectedServices = {
    ServiceType.walking: true,
    ServiceType.petSitting: true,
    ServiceType.grooming: false,
    ServiceType.training: false,
    ServiceType.boarding: false,
    ServiceType.vetVisit: false,
  };

  final Map<ServiceType, TextEditingController> _priceControllers = {
    ServiceType.walking: TextEditingController(text: '350'),
    ServiceType.petSitting: TextEditingController(text: '500'),
    ServiceType.grooming: TextEditingController(text: '800'),
    ServiceType.training: TextEditingController(text: '700'),
    ServiceType.boarding: TextEditingController(text: '1200'),
    ServiceType.vetVisit: TextEditingController(text: '600'),
  };

  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _radiusController.dispose();
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final req = await Geolocator.requestPermission();
      setState(() {
        _locationPermissionGranted = req == LocationPermission.always || req == LocationPermission.whileInUse;
      });
    } else if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      setState(() => _locationPermissionGranted = true);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final anyService = _selectedServices.values.any((selected) => selected);
    if (!anyService) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one pet care service you offer.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // 1. Register user as PROVIDER
      await _api.post('/auth/register', data: {
        'role': 'PROVIDER',
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      });

      // 2. Build services list
      final servicesList = <Map<String, dynamic>>[];
      for (final entry in _selectedServices.entries) {
        if (entry.value) {
          final price = int.tryParse(_priceControllers[entry.key]?.text.trim() ?? '') ?? 350;
          servicesList.add({
            'serviceType': entry.key.name.toUpperCase(),
            'priceInr': price,
            'durationMin': 60,
          });
        }
      }

      // 3. Update provider profile details
      await _api.post('/providers/profile', data: {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'bio': _bioController.text.trim(),
        'yearsExperience': int.tryParse(_experienceController.text.trim()) ?? 1,
        'isAvailable': _isAvailable,
        'services': servicesList,
      });

      // 4. Update availability with GPS if permission granted
      if (_locationPermissionGranted) {
        try {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 4),
          );
          await _api.post('/providers/availability', data: {
            'isAvailable': _isAvailable,
            'lat': pos.latitude,
            'lng': pos.longitude,
          });
        } catch (_) {}
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProviderHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProviderTheme.background,
      appBar: AppBar(
        title: const Text('Complete Provider Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to PetCare',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ProviderTheme.charcoal,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set up your professional pet-care profile to start receiving verified booking requests near you.',
                  style: TextStyle(fontSize: 14, color: ProviderTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 24),

                // Name
                const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'e.g. Rahul Sharma'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Email
                const Text('Email Address (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'e.g. rahul@example.com'),
                ),
                const SizedBox(height: 16),

                // Years of Experience & Radius
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Experience (Years)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _experienceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'e.g. 3'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Service Radius (km)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _radiusController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'e.g. 8'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bio
                const Text('Professional Bio', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe your background with animals, handling philosophy, and schedule availability...',
                  ),
                ),
                const SizedBox(height: 24),

                // Services & Pricing
                const Text(
                  'Services & Pricing',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ProviderTheme.charcoal),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select the services you offer and set your standard rate per session.',
                  style: TextStyle(fontSize: 13, color: ProviderTheme.textMuted),
                ),
                const SizedBox(height: 12),

                ..._selectedServices.keys.map((st) {
                  final isChecked = _selectedServices[st] ?? false;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isChecked ? ProviderTheme.sageBorder : ProviderTheme.border,
                        width: isChecked ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: ProviderTheme.sagePrimary,
                          onChanged: (val) {
                            setState(() => _selectedServices[st] = val ?? false);
                          },
                        ),
                        Expanded(
                          child: Text(
                            st.label,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                        ),
                        if (isChecked)
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: _priceControllers[st],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                prefixText: '₹',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // Location Permission Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ProviderTheme.sageLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ProviderTheme.sageBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _locationPermissionGranted ? Icons.check_circle : Icons.location_on_outlined,
                            color: ProviderTheme.sagePrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _locationPermissionGranted ? 'Location Enabled' : 'Location Permission',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: ProviderTheme.charcoal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'PetCare uses your location only when you start an active service session (such as dog walking) so pet owners can track their pet in real time.',
                        style: TextStyle(fontSize: 12.5, color: ProviderTheme.textMuted, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      if (!_locationPermissionGranted)
                        OutlinedButton(
                          onPressed: _requestLocationPermission,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          child: const Text('Enable Location Access', style: TextStyle(fontSize: 13)),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Complete Setup & Start Receiving Jobs'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
