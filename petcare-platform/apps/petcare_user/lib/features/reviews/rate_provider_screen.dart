import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/api_service.dart';
import '../../core/app_messenger.dart';
import '../../core/theme.dart';
import '../../widgets/petcare_button.dart';
import '../../widgets/petcare_card.dart';

class RateProviderScreen extends StatefulWidget {
  final String bookingId;
  final String providerName;

  const RateProviderScreen({
    super.key,
    required this.bookingId,
    required this.providerName,
  });

  factory RateProviderScreen.fromBooking(Booking booking) {
    return RateProviderScreen(
      bookingId: booking.id,
      providerName: booking.otherPartyName ?? 'Caregiver',
    );
  }

  @override
  State<RateProviderScreen> createState() => _RateProviderScreenState();
}

class _RateProviderScreenState extends State<RateProviderScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _submitting = false;
  final List<String> _selectedCompliments = [];

  final List<String> _compliments = [
    'Super friendly',
    'Punctual',
    'Gentle with pet',
    'Great updates',
    'Followed instructions',
    'Highly recommended',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final combinedComment = [
        if (_selectedCompliments.isNotEmpty) '[${_selectedCompliments.join(', ')}]',
        if (_commentController.text.trim().isNotEmpty) _commentController.text.trim(),
      ].join(' ');

      await UserApiService().submitReview(
        bookingId: widget.bookingId,
        rating: _rating,
        comment: combinedComment.isEmpty ? null : combinedComment,
      );

      if (mounted) {
        showAppSnackBar('Thank you for rating ${widget.providerName}!', isSuccess: true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar('Could not submit review: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _ratingLabel() {
    switch (_rating) {
      case 5:
        return 'Outstanding service! 🐾';
      case 4:
        return 'Very good experience';
      case 3:
        return 'Satisfactory';
      case 2:
        return 'Could have been better';
      default:
        return 'Poor service';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Review Caregiver'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: PetColors.amberLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 44,
                    color: PetColors.amber,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'How was your session with ${widget.providerName}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: PetColors.dark,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _ratingLabel(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PetColors.amber,
                ),
              ),
              const SizedBox(height: 24),

              // 5-Star Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    iconSize: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      star <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: PetColors.amber,
                    ),
                    onPressed: () => setState(() => _rating = star),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Compliments chips
              const Text(
                'What went great?',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _compliments.map((c) {
                  final isSelected = _selectedCompliments.contains(c);
                  return FilterChip(
                    label: Text(c),
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
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedCompliments.add(c);
                        } else {
                          _selectedCompliments.remove(c);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Feedback textarea
              const Text(
                'Leave feedback for ${widget.providerName} (Optional)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Share any details about how your pet liked the caregiver...',
                ),
              ),
              const SizedBox(height: 32),

              PetCareButton(
                label: 'Submit Review',
                icon: Icons.check_circle_rounded,
                isLoading: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: PetColors.darkMuted, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
