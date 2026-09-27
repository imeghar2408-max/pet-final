import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';
import '../core/theme.dart';

class StatusBadge extends StatelessWidget {
  final BookingStatus? bookingStatus;
  final PaymentStatus? paymentStatus;
  final ComplaintStatus? complaintStatus;
  final String? customLabel;
  final Color? customBg;
  final Color? customFg;

  const StatusBadge.booking(this.bookingStatus, {super.key})
      : paymentStatus = null,
        complaintStatus = null,
        customLabel = null,
        customBg = null,
        customFg = null;

  const StatusBadge.payment(this.paymentStatus, {super.key})
      : bookingStatus = null,
        complaintStatus = null,
        customLabel = null,
        customBg = null,
        customFg = null;

  const StatusBadge.complaint(this.complaintStatus, {super.key})
      : bookingStatus = null,
        paymentStatus = null,
        customLabel = null,
        customBg = null,
        customFg = null;

  const StatusBadge.custom({
    super.key,
    required this.customLabel,
    required this.customBg,
    required this.customFg,
  })  : bookingStatus = null,
        paymentStatus = null,
        complaintStatus = null;

  @override
  Widget build(BuildContext context) {
    String label = '';
    Color bg = PetColors.borderSubtle;
    Color fg = PetColors.darkMuted;
    IconData? icon;

    if (bookingStatus != null) {
      label = bookingStatus!.label;
      switch (bookingStatus!) {
        case BookingStatus.requested:
          bg = PetColors.amberLight;
          fg = PetColors.warning;
          icon = Icons.hourglass_top_rounded;
          break;
        case BookingStatus.accepted:
          bg = PetColors.skyLight;
          fg = PetColors.sky;
          icon = Icons.done_all_rounded;
          break;
        case BookingStatus.inProgress:
          bg = PetColors.sageLight;
          fg = PetColors.sage;
          icon = Icons.pets_rounded;
          break;
        case BookingStatus.completed:
          bg = PetColors.successBg;
          fg = PetColors.success;
          icon = Icons.check_circle_rounded;
          break;
        case BookingStatus.rejected:
        case BookingStatus.cancelled:
          bg = PetColors.errorBg;
          fg = PetColors.error;
          icon = Icons.cancel_outlined;
          break;
      }
    } else if (paymentStatus != null) {
      switch (paymentStatus!) {
        case PaymentStatus.pending:
          label = 'Payment Due';
          bg = PetColors.amberLight;
          fg = PetColors.warning;
          icon = Icons.payment_rounded;
          break;
        case PaymentStatus.paid:
          label = 'Paid';
          bg = PetColors.successBg;
          fg = PetColors.success;
          icon = Icons.check_circle_outline_rounded;
          break;
        case PaymentStatus.failed:
          label = 'Failed';
          bg = PetColors.errorBg;
          fg = PetColors.error;
          icon = Icons.error_outline_rounded;
          break;
        case PaymentStatus.refunded:
          label = 'Refunded';
          bg = PetColors.skyLight;
          fg = PetColors.sky;
          icon = Icons.replay_rounded;
          break;
      }
    } else if (complaintStatus != null) {
      label = complaintStatus!.label;
      switch (complaintStatus!) {
        case ComplaintStatus.open:
          bg = PetColors.amberLight;
          fg = PetColors.warning;
          break;
        case ComplaintStatus.inProgress:
          bg = PetColors.skyLight;
          fg = PetColors.sky;
          break;
        case ComplaintStatus.resolved:
          bg = PetColors.successBg;
          fg = PetColors.success;
          break;
        case ComplaintStatus.closed:
          bg = PetColors.borderSubtle;
          fg = PetColors.darkMuted;
          break;
      }
    } else if (customLabel != null) {
      label = customLabel!;
      bg = customBg ?? PetColors.borderSubtle;
      fg = customFg ?? PetColors.darkMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
