import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/theme.dart';
import '../tracking/tracking_screen.dart';
import '../chat/chat_screen.dart';

class ActiveJobsTab extends StatefulWidget {
  const ActiveJobsTab({super.key});

  @override
  State<ActiveJobsTab> createState() => _ActiveJobsTabState();
}

class _ActiveJobsTabState extends State<ActiveJobsTab> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  late Future<List<Booking>> _future;
  final Set<String> _startingIds = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Booking>> _load() async {
    try {
      final res = await _api.get('/bookings/mine');
      final all = (res.data as List).map((e) => Booking.fromJson(e)).toList();
      return all
          .where((b) => b.status == BookingStatus.accepted || b.status == BookingStatus.inProgress)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _startService(Booking b) async {
    setState(() => _startingIds.add(b.id));
    try {
      // Call backend start endpoint
      await _api.post('/bookings/${b.id}/start');
      
      // Update local booking model to IN_PROGRESS for tracking
      final updatedBooking = Booking(
        id: b.id,
        petOwnerId: b.petOwnerId,
        providerId: b.providerId,
        petId: b.petId,
        serviceType: b.serviceType,
        status: BookingStatus.inProgress,
        scheduledAt: b.scheduledAt,
        addressText: b.addressText,
        lat: b.lat,
        lng: b.lng,
        priceInr: b.priceInr,
        notes: b.notes,
        safeZoneLat: b.safeZoneLat,
        safeZoneLng: b.safeZoneLng,
        safeZoneRadiusM: b.safeZoneRadiusM,
        petName: b.petName,
        otherPartyName: b.otherPartyName,
        paymentStatus: b.paymentStatus,
        rating: b.rating,
      );

      if (mounted) {
        // Open the live GPS tracking screen
        final res = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderTrackingScreen(booking: updatedBooking),
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start service: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _startingIds.remove(b.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: ProviderTheme.sagePrimary,
      child: FutureBuilder<List<Booking>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: ProviderTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.assignment_outlined, size: 30, color: ProviderTheme.textMuted),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Active Jobs',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: ProviderTheme.charcoal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Accepted bookings and in-progress sessions will appear here with live GPS tracking and messaging.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: ProviderTheme.textMuted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final b = jobs[index];
              final isInProgress = b.status == BookingStatus.inProgress;
              final isStarting = _startingIds.contains(b.id);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isInProgress ? ProviderTheme.sageBorder : ProviderTheme.border,
                    width: isInProgress ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Service, Status, Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  b.serviceType.label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: ProviderTheme.charcoal,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isInProgress ? ProviderTheme.sageLight : ProviderTheme.surfaceMuted,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isInProgress ? 'In Progress' : 'Accepted',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isInProgress ? ProviderTheme.sagePrimary : ProviderTheme.charcoal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEE, MMM d · h:mm a').format(b.scheduledAt),
                              style: const TextStyle(fontSize: 12.5, color: ProviderTheme.textMuted),
                            ),
                          ],
                        ),
                        Text(
                          '₹${b.priceInr}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ProviderTheme.charcoal,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1, color: ProviderTheme.border),
                    const SizedBox(height: 14),

                    // Pet and Owner Row
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: ProviderTheme.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.pets, color: ProviderTheme.charcoal, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.petName ?? 'Pet',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              Text(
                                'Owner: ${b.otherPartyName ?? "Pet Owner"}',
                                style: const TextStyle(fontSize: 12, color: ProviderTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Chat with Owner',
                          icon: const Icon(Icons.chat_bubble_outline, color: ProviderTheme.charcoal),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ChatScreen(booking: b)),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: ProviderTheme.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            b.addressText,
                            style: const TextStyle(fontSize: 12.5, color: ProviderTheme.textMuted, height: 1.3),
                          ),
                        ),
                      ],
                    ),

                    if (b.safeZoneRadiusM != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 16, color: ProviderTheme.sagePrimary),
                          const SizedBox(width: 6),
                          Text(
                            'Safe Zone set by owner: ${b.safeZoneRadiusM}m radius',
                            style: const TextStyle(fontSize: 12, color: ProviderTheme.sagePrimary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Primary Action Button
                    if (!isInProgress)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isStarting ? null : () => _startService(b),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProviderTheme.sagePrimary,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: isStarting
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Start Service'),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProviderTrackingScreen(booking: b),
                                  ),
                                );
                                _refresh();
                              },
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text('Open Live Tracking & Map'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ProviderTheme.sagePrimary,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
