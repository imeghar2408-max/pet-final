import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/api_service.dart';
import '../../core/location_service.dart';
import '../../core/theme.dart';
import '../../widgets/petcare_card.dart';
import '../../widgets/status_badge.dart';
import '../booking/booking_detail_screen.dart';
import '../discovery/provider_list_screen.dart';
import '../pets/add_pet_screen.dart';
import '../pets/pet_detail_screen.dart';
import '../support/support_screen.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onNavigateToBookings;
  final VoidCallback onNavigateToPets;

  const HomeTab({
    super.key,
    required this.onNavigateToBookings,
    required this.onNavigateToPets,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Map<String, dynamic>? _user;
  List<Pet> _pets = [];
  Booking? _nextBooking;
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await LocationService().acquirePosition(
        context: context,
        showRationaleFirst: false,
      );
      if (mounted && pos != null) {
        setState(() => _currentPosition = pos);
      }
    } catch (e) {
      debugPrint('Location acquisition note: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Independent calls with individual timeouts so one slow/failing call doesn't hang the app
      final userFuture = UserApiService()
          .getMe()
          .timeout(const Duration(seconds: 6))
          .catchError((e) {
        debugPrint('HomeTab getMe failed: $e');
        return <String, dynamic>{};
      });

      final petsFuture = UserApiService()
          .getPets()
          .timeout(const Duration(seconds: 6))
          .catchError((e) {
        debugPrint('HomeTab getPets failed: $e');
        return <Pet>[];
      });

      final bookingsFuture = UserApiService()
          .getMyBookings()
          .timeout(const Duration(seconds: 6))
          .catchError((e) {
        debugPrint('HomeTab getMyBookings failed: $e');
        return <Booking>[];
      });

      final results = await Future.wait([userFuture, petsFuture, bookingsFuture]);

      final user = results[0] as Map<String, dynamic>?;
      final pets = (results[1] as List<dynamic>?)?.cast<Pet>() ?? <Pet>[];
      final bookings = (results[2] as List<dynamic>?)?.cast<Booking>() ?? <Booking>[];

      // Find next active or upcoming booking
      Booking? next;
      final active = bookings
          .where((b) => b.status == BookingStatus.inProgress || b.status == BookingStatus.accepted)
          .toList();

      if (active.isNotEmpty) {
        next = active.first;
      } else {
        final upcoming = bookings.where((b) => b.status == BookingStatus.requested).toList();
        if (upcoming.isNotEmpty) next = upcoming.first;
      }

      if (mounted) {
        setState(() {
          _user = user != null && user.isNotEmpty ? user : null;
          _pets = pets;
          _nextBooking = next;
        });
      }
    } catch (e, stack) {
      debugPrint('HomeTab _loadData unexpected error: $e\n$stack');
    } finally {
      // Guaranteed to terminate the loading spinner regardless of success or failure
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(PetColors.dark),
        ),
      );
    }

    final userName = _user?['name']?.toString().split(' ').first ?? 'Pet Parent';

    return RefreshIndicator(
      color: PetColors.dark,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TOP HEADER: Greeting + Profile Avatar + Support
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: PetColors.primaryLight,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: PetColors.dark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()}, $userName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PetColors.dark,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: _currentPosition != null ? PetColors.sage : PetColors.darkLight,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _currentPosition != null
                                ? 'Device GPS active'
                                : 'Location permission pending',
                            style: TextStyle(
                              fontSize: 12,
                              color: _currentPosition != null ? PetColors.sage : PetColors.darkMuted,
                              fontWeight: _currentPosition != null ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded, color: PetColors.dark, size: 22),
                  tooltip: 'Support & Help',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SupportScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // MINIMAL TRUST CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PetColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: PetColors.sageLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, color: PetColors.sage, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'Verified Caretakers Only',
                              style: TextStyle(
                                color: PetColors.sage,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Reliable, live-tracked care for your pets',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: PetColors.dark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Book certified walkers, sitters, and groomers near you with live GPS tracking and safe-zone alerts.',
                    style: TextStyle(
                      fontSize: 13,
                      color: PetColors.darkMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // UPCOMING / ACTIVE REAL BOOKING BANNER (IF ONE EXISTS)
            if (_nextBooking != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: PetColors.dark,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onNavigateToBookings,
                    child: const Text('View All', style: TextStyle(color: PetColors.dark, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PetCareCard(
                hasShadow: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookingDetailScreen(
                        booking: _nextBooking!,
                        onRefresh: _loadData,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PetColors.sageLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.pets_rounded, color: PetColors.sage, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _nextBooking!.serviceType.label,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: PetColors.dark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge.booking(_nextBooking!.status),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_nextBooking!.petName ?? 'Pet'} • ${DateFormat('EEE, MMM d • h:mm a').format(_nextBooking!.scheduledAt)}',
                            style: const TextStyle(fontSize: 12.5, color: PetColors.darkMuted),
                          ),
                          Text(
                            'Provider: ${_nextBooking!.otherPartyName ?? 'Pending match'}',
                            style: const TextStyle(fontSize: 12, color: PetColors.darkLight),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: PetColors.darkLight),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // PETS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Pets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: PetColors.dark,
                  ),
                ),
                TextButton(
                  onPressed: widget.onNavigateToPets,
                  child: const Text('Manage', style: TextStyle(color: PetColors.dark, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_pets.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PetColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.pets_rounded, size: 36, color: PetColors.darkLight),
                    const SizedBox(height: 12),
                    const Text(
                      'No pets added yet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: PetColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add your pet to find the right care nearby.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: PetColors.darkMuted),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PetColors.dark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Pet'),
                      onPressed: () async {
                        final added = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => const AddPetScreen()),
                        );
                        if (added == true) _loadData();
                      },
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pets.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == _pets.length) {
                      return GestureDetector(
                        onTap: () async {
                          final added = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => const AddPetScreen()),
                          );
                          if (added == true) _loadData();
                        },
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: PetColors.border),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded, color: PetColors.dark, size: 24),
                              SizedBox(height: 6),
                              Text('Add Pet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PetColors.dark)),
                            ],
                          ),
                        ),
                      );
                    }

                    final pet = _pets[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PetDetailScreen(pet: pet),
                          ),
                        );
                      },
                      child: Container(
                        width: 90,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: PetColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: PetColors.sageLight,
                              backgroundImage: pet.photoUrl != null && pet.photoUrl!.isNotEmpty
                                  ? NetworkImage(pet.photoUrl!)
                                  : null,
                              child: pet.photoUrl == null || pet.photoUrl!.isEmpty
                                  ? const Icon(Icons.pets_rounded, size: 20, color: PetColors.sage)
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              pet.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: PetColors.dark,
                              ),
                            ),
                            Text(
                              pet.species,
                              style: const TextStyle(fontSize: 10.5, color: PetColors.darkMuted),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 28),

            // SERVICES GRID
            const Text(
              'Explore Services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: PetColors.dark,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: ServiceType.values.map((svc) {
                return _buildServiceCard(svc);
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServiceType service) {
    IconData icon;
    String desc;

    switch (service) {
      case ServiceType.walking:
        icon = Icons.directions_walk_rounded;
        desc = 'Daily brisk exercise';
        break;
      case ServiceType.grooming:
        icon = Icons.shower_rounded;
        desc = 'Bath, haircut & styling';
        break;
      case ServiceType.petSitting:
        icon = Icons.home_rounded;
        desc = 'Attentive in-home care';
        break;
      case ServiceType.boarding:
        icon = Icons.night_shelter_rounded;
        desc = 'Overnight safe stay';
        break;
      case ServiceType.training:
        icon = Icons.school_rounded;
        desc = 'Positive behavior training';
        break;
      case ServiceType.vetVisit:
        icon = Icons.local_hospital_rounded;
        desc = 'Clinic assistance & rides';
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProviderListScreen(serviceType: service),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PetColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PetColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: PetColors.dark, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PetColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: PetColors.darkMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}