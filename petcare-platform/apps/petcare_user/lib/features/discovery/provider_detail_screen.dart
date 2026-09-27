import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/theme.dart';
import '../../widgets/petcare_button.dart';
import '../../widgets/petcare_card.dart';
import '../booking/booking_flow_screen.dart';

class ProviderDetailScreen extends StatelessWidget {
  final ProviderSummary provider;
  final ServiceType? preselectedService;

  const ProviderDetailScreen({
    super.key,
    required this.provider,
    this.preselectedService,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveService = preselectedService ??
        (provider.servicesOffered.isNotEmpty
            ? provider.servicesOffered.first.serviceType
            : null);

    return Scaffold(
      backgroundColor: PetColors.background,
      appBar: AppBar(
        title: const Text('Provider Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: PetColors.border)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (effectiveService != null && provider.offeringFor(effectiveService) != null) ...[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rate',
                      style: TextStyle(fontSize: 12, color: PetColors.darkMuted),
                    ),
                    Text(
                      '₹${provider.offeringFor(effectiveService)!.priceInr}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: PetColors.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
              ],
              Expanded(
                child: PetCareButton(
                  label: 'Book with ${provider.name.split(' ').first}',
                  icon: Icons.calendar_today_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookingFlowScreen(
                          provider: provider,
                          initialService: effectiveService,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Provider Hero Card
            PetCareCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: PetColors.sageLight,
                    backgroundImage: provider.profilePhoto != null && provider.profilePhoto!.isNotEmpty
                        ? NetworkImage(provider.profilePhoto!)
                        : null,
                    child: provider.profilePhoto == null || provider.profilePhoto!.isEmpty
                        ? Text(
                            provider.name.isNotEmpty ? provider.name[0].toUpperCase() : 'P',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: PetColors.sage,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: PetColors.dark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, color: PetColors.sage, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Rating & Status Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: PetColors.amberLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: PetColors.amber),
                            const SizedBox(width: 4),
                            Text(
                              provider.ratingCount > 0
                                  ? provider.ratingAvg.toStringAsFixed(1)
                                  : 'New',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: PetColors.amber,
                              ),
                            ),
                            if (provider.ratingCount > 0) ...[
                              const SizedBox(width: 3),
                              Text(
                                '(${provider.ratingCount})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: PetColors.darkMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: PetColors.successBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: PetColors.success),
                            SizedBox(width: 6),
                            Text(
                              'Verified & Active',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: PetColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Experience & About Section
            PetCareCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Provider',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: PetColors.dark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    provider.bio != null && provider.bio!.isNotEmpty
                        ? provider.bio!
                        : 'Dedicated pet care professional verified by PetCare. Passionate about providing a safe, attentive, and joyous experience for your pets.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: PetColors.darkMuted,
                      height: 1.45,
                    ),
                  ),
                  if (provider.yearsExperience != null && provider.yearsExperience! > 0) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_outlined, color: PetColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${provider.yearsExperience} years of pet care experience',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: PetColors.dark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Services & Pricing List
            PetCareCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Services & Pricing',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: PetColors.dark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (provider.servicesOffered.isEmpty) ...[
                    const Text(
                      'No specific service pricing listed currently.',
                      style: TextStyle(fontSize: 13.5, color: PetColors.darkMuted),
                    ),
                  ] else ...[
                    ...provider.servicesOffered.map((offering) {
                      final isSelected = offering.serviceType == effectiveService;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? PetColors.primaryLight : PetColors.borderSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? PetColors.primary : PetColors.border,
                            width: isSelected ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _serviceIcon(offering.serviceType),
                              color: isSelected ? PetColors.primary : PetColors.darkMuted,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    offering.serviceType.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? PetColors.primary : PetColors.dark,
                                    ),
                                  ),
                                  Text(
                                    '${offering.durationMin} minutes',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: PetColors.darkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${offering.priceInr}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? PetColors.primary : PetColors.dark,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Trust & Safety badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PetColors.sageLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PetColors.sage.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: PetColors.sage, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All bookings include live GPS safe-zone monitoring, in-app messaging, and customer support.',
                      style: TextStyle(fontSize: 12.5, color: PetColors.sage, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
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
