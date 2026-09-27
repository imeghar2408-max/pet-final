import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/theme.dart';
import '../../widgets/petcare_button.dart';
import '../../widgets/petcare_card.dart';
import '../../widgets/status_badge.dart';
import '../chat/chat_screen.dart';
import '../payments/payment_flow.dart';
import '../reviews/rate_provider_screen.dart';
import '../support/report_issue_screen.dart';
import '../tracking/tracking_screen.dart';

class BookingDetailScreen extends StatelessWidget {
  final Booking booking;
  final VoidCallback onRefresh;

  const BookingDetailScreen({
    super.key,
    required this.booking,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isInProgress = booking.status == BookingStatus.inProgress;
    final isAccepted = booking.status == BookingStatus.accepted;
    final isRequested = booking.status == BookingStatus.requested;
    final isCompleted = booking.status == BookingStatus.completed;
    final isUnpaid = isCompleted && booking.paymentStatus != PaymentStatus.paid;
    final canReview = isCompleted && !booking.hasReview;

    return Scaffold(
      backgroundColor: PetColors.background,
      appBar: AppBar(
        title: const Text('Booking Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: PetColors.darkMuted),
            tooltip: 'Report Issue',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportIssueScreen(preselectedBookingId: booking.id),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: isInProgress || isAccepted || isUnpaid || canReview
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: PetColors.border)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (isInProgress) ...[
                      Expanded(
                        child: PetCareButton(
                          label: 'Live Track & Safe Zone',
                          icon: Icons.navigation_rounded,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TrackingScreen(booking: booking),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: PetColors.sageLight,
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: PetColors.sage),
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
                    ] else if (isAccepted) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: const Text('Chat with Provider'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: PetColors.border),
                          ),
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
                      ),
                    ] else if (isUnpaid) ...[
                      Expanded(
                        child: PetCareButton(
                          label: 'Pay Now (₹${booking.priceInr})',
                          icon: Icons.payment_rounded,
                          onPressed: () async {
                            final success = await PaymentFlow.start(context, booking);
                            if (success) {
                              onRefresh();
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    ] else if (canReview) ...[
                      Expanded(
                        child: PetCareButton(
                          label: 'Rate & Review Caregiver',
                          icon: Icons.star_rounded,
                          customColor: PetColors.amber,
                          onPressed: () async {
                            final rated = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => RateProviderScreen(
                                  bookingId: booking.id,
                                  providerName: booking.otherPartyName ?? 'Provider',
                                ),
                              ),
                            );
                            if (rated == true) {
                              onRefresh();
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner
            PetCareCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PetColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_serviceIcon(booking.serviceType), color: PetColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceType.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: PetColors.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEE, MMM d, yyyy • h:mm a').format(booking.scheduledAt),
                          style: const TextStyle(fontSize: 13, color: PetColors.darkMuted),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.booking(booking.status),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Lifecycle Guidance Card
            if (isRequested)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PetColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PetColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: PetColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Waiting for provider', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: PetColors.dark)),
                          SizedBox(height: 2),
                          Text('Your request has been sent to the provider. We\'ll notify you when they respond.', style: TextStyle(fontSize: 12, color: PetColors.darkMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (isAccepted)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PetColors.sageLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PetColors.sage.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: PetColors.sage, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Booking Confirmed', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: PetColors.sage)),
                          SizedBox(height: 2),
                          Text('Your provider accepted the booking. Location tracking will become active when they start the service.', style: TextStyle(fontSize: 12, color: PetColors.darkMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (isInProgress)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PetColors.sageLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PetColors.sage.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.near_me_rounded, color: PetColors.sage, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Service in Progress · Live GPS Active', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: PetColors.sage)),
                          SizedBox(height: 2),
                          Text('Provider has started the service session. Tap "Live Track & Safe Zone" below to follow them on the map.', style: TextStyle(fontSize: 12, color: PetColors.darkMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (isCompleted)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PetColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PetColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.celebration_rounded, color: PetColors.coral, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Service completed 🎉', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: PetColors.dark)),
                          const SizedBox(height: 2),
                          Text(
                            isUnpaid
                                ? 'Your provider has marked this service as completed. Please pay the service fee below.'
                                : 'Service completed and paid! Thank you for choosing PetCare.',
                            style: const TextStyle(fontSize: 12, color: PetColors.darkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Caregiver Card
            PetCareCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assigned Caregiver',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PetColors.darkMuted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: PetColors.sageLight,
                        backgroundImage: booking.otherPartyPhoto != null
                            ? NetworkImage(booking.otherPartyPhoto!)
                            : null,
                        child: booking.otherPartyPhoto == null
                            ? Text(
                                booking.otherPartyName != null && booking.otherPartyName!.isNotEmpty
                                    ? booking.otherPartyName![0]
                                    : 'P',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: PetColors.sage),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.otherPartyName ?? 'Verified Provider',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PetColors.dark),
                            ),
                            if (booking.otherPartyPhone != null && booking.otherPartyPhone!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                booking.otherPartyPhone!,
                                style: const TextStyle(fontSize: 13, color: PetColors.darkMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isInProgress || isAccepted) ...[
                        IconButton.filledTonal(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
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
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pet Info Card
            PetCareCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pet Registered',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PetColors.darkMuted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: PetColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.pets_rounded, color: PetColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.petName ?? 'Your Pet',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PetColors.dark),
                            ),
                            if (booking.petBreed != null && booking.petBreed!.isNotEmpty) ...[
                              Text(
                                booking.petBreed!,
                                style: const TextStyle(fontSize: 13, color: PetColors.darkMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Service Location
            PetCareCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service Address',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PetColors.darkMuted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, color: PetColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          booking.addressText,
                          style: const TextStyle(fontSize: 14, color: PetColors.dark, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text(
                      'Special Instructions:',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: PetColors.darkMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.notes!,
                      style: const TextStyle(fontSize: 13, color: PetColors.dark),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment & Billing Summary
            PetCareCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Billing Summary',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PetColors.dark),
                      ),
                      if (booking.paymentStatus != null) StatusBadge.payment(booking.paymentStatus),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Service Base Fee', style: TextStyle(fontSize: 13.5, color: PetColors.darkMuted)),
                      Text('₹${booking.priceInr}', style: const TextStyle(fontSize: 14, color: PetColors.dark, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Platform & GPS Monitoring Fee', style: TextStyle(fontSize: 13.5, color: PetColors.darkMuted)),
                      Text('FREE', style: TextStyle(fontSize: 14, color: PetColors.success, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PetColors.dark)),
                      Text(
                        '₹${booking.priceInr}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (booking.hasReview) ...[
              const SizedBox(height: 16),
              PetCareCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Review',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PetColors.dark),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < (booking.reviewRating ?? 5) ? Icons.star_rounded : Icons.star_border_rounded,
                          color: PetColors.amber,
                          size: 20,
                        );
                      }),
                    ),
                    if (booking.reviewComment != null && booking.reviewComment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '"${booking.reviewComment!}"',
                        style: const TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, color: PetColors.darkMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
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
