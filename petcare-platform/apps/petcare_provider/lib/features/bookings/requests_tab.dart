import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/theme.dart';

class RequestsTab extends StatefulWidget {
  final VoidCallback? onRequestHandled;
  const RequestsTab({super.key, this.onRequestHandled});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  late Future<List<Booking>> _future;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Booking>> _load() async {
    try {
      final res = await _api.get('/bookings/mine');
      final all = (res.data as List).map((e) => Booking.fromJson(e)).toList();
      return all.where((b) => b.status == BookingStatus.requested).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _respond(Booking b, bool accept) async {
    setState(() => _processingIds.add(b.id));
    try {
      await _api.post('/bookings/${b.id}/respond', data: {'accept': accept});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Booking accepted!' : 'Booking declined'),
          duration: const Duration(seconds: 2),
        ),
      );
      await _refresh();
      widget.onRequestHandled?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to respond: $e')),
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(b.id));
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

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
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
                            child: const Icon(Icons.inbox_outlined, size: 30, color: ProviderTheme.textMuted),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Pending Requests',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: ProviderTheme.charcoal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'When pet owners near you request a service, their booking requests will appear here for you to accept or decline.',
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
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final b = requests[index];
              final isProcessing = _processingIds.contains(b.id);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ProviderTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top header: Service & Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.serviceType.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: ProviderTheme.charcoal,
                              ),
                            ),
                            const SizedBox(height: 2),
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

                    // Pet info row
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
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Address row
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

                    if (b.notes != null && b.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: ProviderTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Note: ${b.notes}',
                          style: const TextStyle(fontSize: 12, color: ProviderTheme.charcoal, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Actions: Accept / Reject
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isProcessing ? null : () => _respond(b, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ProviderTheme.coralAccent,
                              side: const BorderSide(color: ProviderTheme.coralBorder),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isProcessing ? null : () => _respond(b, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ProviderTheme.sagePrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: isProcessing
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Accept Request'),
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
