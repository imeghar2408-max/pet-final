import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/petcare_card.dart';
import '../../widgets/status_badge.dart';
import '../chat/chat_screen.dart';
import '../payments/payment_flow.dart';
import '../reviews/rate_provider_screen.dart';
import '../support/report_issue_screen.dart';
import '../tracking/tracking_screen.dart';
import 'booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  final bool showBackButton;

  const MyBookingsScreen({super.key, this.showBackButton = true});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await UserApiService().getMyBookings();
      if (mounted) {
        setState(() {
          _bookings = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Booking> get _activeBookings => _bookings.where((b) {
        return b.status == BookingStatus.accepted || b.status == BookingStatus.inProgress;
      }).toList();

  List<Booking> get _upcomingBookings => _bookings.where((b) {
        return b.status == BookingStatus.requested;
      }).toList();

  List<Booking> get _completedBookings => _bookings.where((b) {
        return b.status == BookingStatus.completed;
      }).toList();

  List<Booking> get _cancelledBookings => _bookings.where((b) {
        return b.status == BookingStatus.cancelled || b.status == BookingStatus.rejected;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetColors.background,
      appBar: AppBar(
        title: const Text('My Bookings'),
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        bottom: TabBar(
          controller: _tabController,
          labelColor: PetColors.primary,
          unselectedLabelColor: PetColors.darkMuted,
          indicatorColor: PetColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: [
            Tab(text: 'Active (${_activeBookings.length})'),
            Tab(text: 'Upcoming (${_upcomingBookings.length})'),
            Tab(text: 'Completed (${_completedBookings.length})'),
            Tab(text: 'Past (${_cancelledBookings.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PetColors.primary),
              ),
            )
          : _error != null
              ? EmptyStateView(
                  icon: Icons.error_outline_rounded,
                  iconColor: PetColors.error,
                  title: 'Could not load bookings',
                  description: _error!,
                  buttonLabel: 'Try Again',
                  onButtonPressed: _loadBookings,
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_activeBookings, 'No active services right now', 'Bookings currently in progress or accepted will appear here.'),
                    _buildList(_upcomingBookings, 'No pending booking requests', 'When you request a service, it will show here awaiting provider confirmation.'),
                    _buildList(_completedBookings, 'No completed services yet', 'Your service history and receipts will be stored here once finished.'),
                    _buildList(_cancelledBookings, 'No cancelled or rejected bookings', 'Any declined or cancelled requests are recorded here.'),
                  ],
                ),
    );
  }

  Widget _buildList(List<Booking> list, String emptyTitle, String emptyDesc) {
    if (list.isEmpty) {
      return EmptyStateView(
        icon: Icons.event_note_rounded,
        title: emptyTitle,
        description: emptyDesc,
      );
    }

    return RefreshIndicator(
      color: PetColors.primary,
      onRefresh: _loadBookings,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) => _buildBookingCard(list[i]),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final isLive = booking.status == BookingStatus.accepted || booking.status == BookingStatus.inProgress;
    final isUnpaid = booking.status == BookingStatus.completed && booking.paymentStatus != PaymentStatus.paid;
    final canReview = booking.status == BookingStatus.completed &&
        booking.paymentStatus == PaymentStatus.paid &&
        !booking.hasReview;

    return PetCareCard(
      hasShadow: true,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(
              booking: booking,
              onRefresh: _loadBookings,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Service, Date & Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PetColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_serviceIcon(booking.serviceType), color: PetColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceType.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PetColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEE, MMM d • h:mm a').format(booking.scheduledAt),
                      style: const TextStyle(fontSize: 12.5, color: PetColors.darkMuted),
                    ),
                  ],
                ),
              ),
              StatusBadge.booking(booking.status),
            ],
          ),
          const SizedBox(height: 14),

          // Provider & Pet Information
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: PetColors.borderSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: PetColors.darkMuted),
                    const SizedBox(width: 6),
                    Text(
                      booking.otherPartyName ?? 'Assigned Provider',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PetColors.dark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.pets_rounded, size: 16, color: PetColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      booking.petName ?? 'Pet',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PetColors.dark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Price & Contextual Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${booking.priceInr}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: PetColors.dark,
                ),
              ),
              Row(
                children: [
                  if (isLive) ...[
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: PetColors.sage,
                        backgroundColor: PetColors.sageLight,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: const Text('Live Track GPS', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TrackingScreen(booking: booking),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: PetColors.primary),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              bookingId: booking.id,
                              otherPartyName: booking.otherPartyName ?? 'Provider',
                            ),
                          ),
                        );
                      },
                    ),
                  ] else if (isUnpaid) ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PetColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final ok = await PaymentFlow.start(context, booking);
                        if (ok) _loadBookings();
                      },
                      child: const Text('Pay Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ] else if (canReview) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PetColors.amber,
                        side: const BorderSide(color: PetColors.amber),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.star_rounded, size: 16),
                      label: const Text('Rate', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      onPressed: () async {
                        final rated = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => RateProviderScreen(
                              bookingId: booking.id,
                              providerName: booking.otherPartyName ?? 'Provider',
                            ),
                          ),
                        );
                        if (rated == true) _loadBookings();
                      },
                    ),
                  ] else ...[
                    const Row(
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: PetColors.darkMuted),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: PetColors.darkLight),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _serviceIcon(ServiceType type) {
    switch (type) {
      case ServiceType.walking:
        return Icons.directions_walk_rounded;
      case ServiceType.grooming:
        return Icons.content_cut_rounded;
      case ServiceType.training:
        return Icons.psychology_rounded;
      case ServiceType.boarding:
        return Icons.night_shelter_rounded;
      case ServiceType.vetVisit:
        return Icons.medical_services_rounded;
      case ServiceType.petSitting:
        return Icons.chair_rounded;
    }
  }
}
