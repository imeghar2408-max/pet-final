import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/api_service.dart';
import '../../core/app_messenger.dart';
import '../../core/theme.dart';
import '../../widgets/petcare_button.dart';
import '../../widgets/petcare_card.dart';

class ReportIssueForm extends StatefulWidget {
  final Booking? booking;
  final String? preselectedBookingId;
  final VoidCallback? onSubmitted;

  const ReportIssueForm({
    super.key,
    this.booking,
    this.preselectedBookingId,
    this.onSubmitted,
  });

  @override
  State<ReportIssueForm> createState() => _ReportIssueFormState();
}

class _ReportIssueFormState extends State<ReportIssueForm> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  ComplaintCategory _category = ComplaintCategory.serviceQuality;
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectController.text.trim().isEmpty) {
      showAppSnackBar('Please provide a subject summary', isError: true);
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      showAppSnackBar('Please describe what happened', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final bookingId = widget.booking?.id ?? widget.preselectedBookingId;
      await UserApiService().submitComplaint(
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        bookingId: bookingId,
      );

      if (mounted) {
        _subjectController.clear();
        _descriptionController.clear();
        showAppSnackBar('Report submitted. Operations will review promptly.', isSuccess: true);
        widget.onSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar('Failed to submit report: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        if (widget.booking != null)
          PetCareCard(
            color: PetColors.primaryLight,
            padding: const EdgeInsets.all(14),
            border: Border.all(color: PetColors.primary.withOpacity(0.3)),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: PetColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Linked to: ${widget.booking!.serviceType.label} with ${widget.booking!.otherPartyName ?? 'Provider'}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PetColors.dark),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'Issue Category',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PetColors.dark),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ComplaintCategory.values.map((c) {
            final isSelected = _category == c;
            return ChoiceChip(
              label: Text(c.label),
              selected: isSelected,
              selectedColor: PetColors.primaryLight,
              labelStyle: TextStyle(
                fontSize: 12.5,
                color: isSelected ? PetColors.primary : PetColors.dark,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? PetColors.primary : PetColors.border,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (_) => setState(() => _category = c),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text(
          'Subject Summary *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PetColors.dark),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _subjectController,
          decoration: const InputDecoration(
            hintText: 'e.g. Walker arrived 30 mins late, Payment issue',
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Detailed Description *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PetColors.dark),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Please describe the incident in detail so support can assist...',
          ),
        ),
        const SizedBox(height: 28),
        PetCareButton(
          label: 'Submit Resolution Request',
          icon: Icons.send_rounded,
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class ReportIssueScreen extends StatelessWidget {
  final Booking? booking;
  final String? preselectedBookingId;

  const ReportIssueScreen({super.key, this.booking, this.preselectedBookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetColors.background,
      appBar: AppBar(
        title: const Text('Report an Issue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ReportIssueForm(
        booking: booking,
        preselectedBookingId: preselectedBookingId,
        onSubmitted: () => Navigator.pop(context, true),
      ),
    );
  }
}
