import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/api_service.dart';
import '../../core/app_messenger.dart';
import '../reviews/rate_provider_screen.dart';

class PaymentFlow {
  static Future<bool> start(BuildContext context, Booking booking) async {
    final completer = Completer<bool>();
    final razorpay = Razorpay();

    try {
      final orderData = await UserApiService().createPaymentOrder(booking.id);
      final orderId = orderData['id'] as String;
      final amount = orderData['amount'] as int;

      razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) async {
        try {
          final verifyRes = await UserApiService().verifyPayment(
            bookingId: booking.id,
            razorpayOrderId: response.orderId ?? orderId,
            razorpayPaymentId: response.paymentId ?? '',
            razorpaySignature: response.signature ?? '',
          );

          razorpay.clear();
          if (!context.mounted) {
            completer.complete(true);
            return;
          }

          if (verifyRes['valid'] == true) {
            showAppSnackBar('Payment completed successfully!', isSuccess: true);
            // Prompt to rate caregiver
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RateProviderScreen(
                  bookingId: booking.id,
                  providerName: booking.otherPartyName ?? 'Caregiver',
                ),
              ),
            );
            completer.complete(true);
          } else {
            showAppSnackBar('Payment verification failed. Please contact support.', isError: true);
            completer.complete(false);
          }
        } catch (e) {
          razorpay.clear();
          showAppSnackBar('Error verifying payment: $e', isError: true);
          completer.complete(false);
        }
      });

      razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        razorpay.clear();
        showAppSnackBar('Payment was not completed: ${response.message}', isError: true);
        completer.complete(false);
      });

      razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
        razorpay.clear();
        completer.complete(false);
      });

      razorpay.open({
        'key': const String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: 'rzp_test_5afa1852'),
        'order_id': orderId,
        'amount': amount,
        'currency': 'INR',
        'name': 'PetCare',
        'description': '${booking.serviceType.label} for ${booking.petName ?? 'your pet'}',
        'theme': {'color': '#FF6A4D'},
      });
    } catch (e) {
      razorpay.clear();
      showAppSnackBar('Failed to initiate payment: $e', isError: true);
      completer.complete(false);
    }

    return completer.future;
  }
}
