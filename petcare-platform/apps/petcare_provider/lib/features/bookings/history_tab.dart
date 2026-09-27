import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/theme.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  late Future<List<Booking>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Booking>> _load() async {
    try {
      final res = await _api.get('/bookings/mine');
      final all = (res.data as List).map((e) => Booking.fromJson(e)).toList();
      return all.where((b) => b.status == BookingStatus.completed).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
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

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
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
                            child: const Icon(Icons.history, size: 30, color: ProviderTheme.textMuted),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Completed Jobs Yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: ProviderTheme.charcoal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Once you finish pet care appointments and walks, your complete service history, earnings, and owner reviews will appear here.',
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

          final totalEarned = history.fold<int>(0, (sum, b) => sum + b.priceInr);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ProviderTheme.sageLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ProviderTheme.sageBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Completed Jobs',
                          style: TextStyle(fontSize: 12, color: ProviderTheme.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${history.length} sessions',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ProviderTheme.charcoal),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total Earnings',
                          style: TextStyle(fontSize: 12, color: ProviderTheme.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹$totalEarned',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ProviderTheme.sagePrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              ...history.map((b) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ProviderTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            b.serviceType.label,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: ProviderTheme.charcoal),
                          ),
                          Text(
                            '₹${b.priceInr}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: ProviderTheme.charcoal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEE, MMM d, yyyy · h:mm a').format(b.scheduledAt),
                        style: const TextStyle(fontSize: 12, color: ProviderTheme.textMuted),
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: ProviderTheme.border),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: ProviderTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.pets, size: 16, color: ProviderTheme.charcoal),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${b.petName ?? "Pet"} (Owner: ${b.otherPartyName ?? "Owner"})',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ProviderTheme.sageLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Completed',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ProviderTheme.sagePrimary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
