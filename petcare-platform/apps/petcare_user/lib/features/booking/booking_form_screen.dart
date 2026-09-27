import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';
import 'booking_flow_screen.dart';

class BookingFormScreen extends StatelessWidget {
  final ProviderSummary provider;
  final ServiceType serviceType;
  final ProviderServiceOffering offering;

  const BookingFormScreen({
    super.key,
    required this.provider,
    required this.serviceType,
    required this.offering,
  });

  @override
  Widget build(BuildContext context) {
    return BookingFlowScreen(
      provider: provider,
      initialService: serviceType,
    );
  }
}
