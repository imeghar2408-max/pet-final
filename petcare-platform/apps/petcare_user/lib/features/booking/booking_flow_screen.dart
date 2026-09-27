import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/api_service.dart';
import '../../core/app_messenger.dart';
import '../../core/theme.dart';
import '../../widgets/petcare_button.dart';
import '../../widgets/petcare_card.dart';
import '../pets/add_pet_screen.dart';
import 'my_bookings_screen.dart';

class BookingFlowScreen extends StatefulWidget {
  final ProviderSummary provider;
  final ServiceType? initialService;

  const BookingFlowScreen({
    super.key,
    required this.provider,
    this.initialService,
  });

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  int _currentStep = 0; // 0: Service & Pet, 1: Date & Time, 2: Address & Notes, 3: Review & Submit
  late ServiceType _selectedService;
  List<Pet> _pets = [];
  Pet? _selectedPet;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2)));
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _loadingPets = true;
  bool _submitting = false;
  Booking? _createdBooking;

  @override
  void initState() {
    super.initState();
    // Default service to initialService or first offering
    if (widget.initialService != null) {
      _selectedService = widget.initialService!;
    } else if (widget.provider.servicesOffered.isNotEmpty) {
      _selectedService = widget.provider.servicesOffered.first.serviceType;
    } else {
      _selectedService = ServiceType.walking;
    }
    _loadPets();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    try {
      final pets = await UserApiService().getPets();
      if (mounted) {
        setState(() {
          _pets = pets;
          if (pets.isNotEmpty) {
            _selectedPet = pets.first;
          }
          _loadingPets = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPets = false);
    }
  }

  int get _calculatedPrice {
    final offering = widget.provider.offeringFor(_selectedService);
    return offering?.priceInr ?? 0;
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _submitBooking() async {
    if (_selectedPet == null) {
      showAppSnackBar('Please select or add a pet first', isError: true);
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      showAppSnackBar('Please enter your service address', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final booking = await UserApiService().createBooking(
        providerId: widget.provider.id,
        petId: _selectedPet!.id,
        serviceType: _selectedService,
        scheduledAt: _combinedDateTime,
        addressText: _addressController.text.trim(),
        lat: 28.6139, // Default city center coordinates
        lng: 77.2090,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _createdBooking = booking;
        _submitting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        showAppSnackBar('Could not submit booking: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_createdBooking != null) {
      return _buildSuccessConfirmation();
    }

    return Scaffold(
      backgroundColor: PetColors.background,
      appBar: AppBar(
        title: const Text('Book Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
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
              if (_currentStep < 3) ...[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of 4',
                      style: const TextStyle(fontSize: 12, color: PetColors.darkMuted),
                    ),
                    Text(
                      '₹$_calculatedPrice',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: PetColors.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: PetCareButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _canProceed()
                        ? () {
                            setState(() => _currentStep++);
                          }
                        : null,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: PetCareButton(
                    label: 'Send Booking Request (₹$_calculatedPrice)',
                    icon: Icons.send_rounded,
                    isLoading: _submitting,
                    onPressed: _submitBooking,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Step Progress Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Service & Pet'),
                _buildStepDivider(0),
                _buildStepIndicator(1, 'Date & Time'),
                _buildStepDivider(1),
                _buildStepIndicator(2, 'Location'),
                _buildStepDivider(2),
                _buildStepIndicator(3, 'Review'),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStepContent(),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    if (_currentStep == 0) {
      return _selectedPet != null;
    }
    if (_currentStep == 1) {
      return true;
    }
    if (_currentStep == 2) {
      return _addressController.text.trim().isNotEmpty;
    }
    return true;
  }

  Widget _buildStepIndicator(int step, String title) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? PetColors.success
                : isActive
                    ? PetColors.primary
                    : PetColors.borderSubtle,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone
                  ? PetColors.success
                  : isActive
                      ? PetColors.primary
                      : PetColors.border,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : PetColors.darkMuted,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int fromStep) {
    final isDone = _currentStep > fromStep;
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? PetColors.success : PetColors.border,
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildServiceAndPetStep();
      case 1:
        return _buildDateTimeStep();
      case 2:
        return _buildAddressStep();
      case 3:
      default:
        return _buildReviewStep();
    }
  }

  Widget _buildServiceAndPetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Provider Info Strip
        PetCareCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: PetColors.sageLight,
                backgroundImage: widget.provider.profilePhoto != null
                    ? NetworkImage(widget.provider.profilePhoto!)
                    : null,
                child: widget.provider.profilePhoto == null
                    ? Text(
                        widget.provider.name[0],
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
                      widget.provider.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: PetColors.dark),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: PetColors.amber),
                        const SizedBox(width: 3),
                        Text(
                          widget.provider.ratingCount > 0
                              ? widget.provider.ratingAvg.toStringAsFixed(1)
                              : 'New Provider',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PetColors.dark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Select Service
        const Text(
          'Select Service',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PetColors.dark),
        ),
        const SizedBox(height: 10),
        Column(
          children: widget.provider.servicesOffered.map((offering) {
            final isSelected = _selectedService == offering.serviceType;
            return PetCareCard(
              margin: const EdgeInsets.only(bottom: 10),
              color: isSelected ? PetColors.primaryLight : Colors.white,
              border: Border.all(
                color: isSelected ? PetColors.primary : PetColors.border,
                width: isSelected ? 1.6 : 1,
              ),
              onTap: () {
                setState(() => _selectedService = offering.serviceType);
              },
              child: Row(
                children: [
                  Radio<ServiceType>(
                    value: offering.serviceType,
                    groupValue: _selectedService,
                    activeColor: PetColors.primary,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedService = val);
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offering.serviceType.label,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? PetColors.primary : PetColors.dark,
                          ),
                        ),
                        Text(
                          '${offering.durationMin} mins session',
                          style: const TextStyle(fontSize: 12, color: PetColors.darkMuted),
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
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Select Pet
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Pet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PetColors.dark),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Pet'),
              onPressed: () async {
                final added = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const AddPetScreen()),
                );
                if (added == true) _loadPets();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_loadingPets) ...[
          const Center(child: CircularProgressIndicator()),
        ] else if (_pets.isEmpty) ...[
          PetCareCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.pets_rounded, size: 36, color: PetColors.primary),
                const SizedBox(height: 10),
                const Text(
                  'No pets registered yet',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: PetColors.dark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please add your pet before completing the booking request.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: PetColors.darkMuted),
                ),
                const SizedBox(height: 14),
                PetCareButton(
                  label: 'Add a Pet',
                  icon: Icons.add_rounded,
                  height: 44,
                  onPressed: () async {
                    final added = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const AddPetScreen()),
                    );
                    if (added == true) _loadPets();
                  },
                ),
              ],
            ),
          ),
        ] else ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _pets.map((pet) {
              final isSelected = _selectedPet?.id == pet.id;
              return ChoiceChip(
                avatar: const Icon(Icons.pets_rounded, size: 16),
                label: Text('${pet.name} (${pet.species})'),
                selected: isSelected,
                selectedColor: PetColors.primaryLight,
                labelStyle: TextStyle(
                  color: isSelected ? PetColors.primary : PetColors.dark,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected ? PetColors.primary : PetColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val) setState(() => _selectedPet = pet);
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDateTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date & Time',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PetColors.dark),
        ),
        const SizedBox(height: 6),
        const Text(
          'When would you like the service to begin?',
          style: TextStyle(fontSize: 13.5, color: PetColors.darkMuted),
        ),
        const SizedBox(height: 24),

        // Date Card
        PetCareCard(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: now,
              lastDate: now.add(const Duration(days: 30)),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PetColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: PetColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service Date', style: TextStyle(fontSize: 12, color: PetColors.darkMuted)),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PetColors.dark),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: PetColors.darkLight),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Time Card
        PetCareCard(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _selectedTime,
            );
            if (picked != null) {
              setState(() => _selectedTime = picked);
            }
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PetColors.sageLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.schedule_rounded, color: PetColors.sage, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service Time', style: TextStyle(fontSize: 12, color: PetColors.darkMuted)),
                    const SizedBox(height: 2),
                    Text(
                      _selectedTime.format(context),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PetColors.dark),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: PetColors.darkLight),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location & Instructions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PetColors.dark),
        ),
        const SizedBox(height: 6),
        const Text(
          'Provide the address where the provider should meet you and your pet.',
          style: TextStyle(fontSize: 13.5, color: PetColors.darkMuted),
        ),
        const SizedBox(height: 24),

        // Address Field
        const Text(
          'Full Service Address *',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _addressController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'e.g. Flat 402, Greenfield Apartments, Sector 14',
            prefixIcon: Icon(Icons.location_on_outlined, color: PetColors.darkMuted),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),

        // Special Instructions
        const Text(
          'Notes for Provider (Optional)',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. Ring the bell twice. Bruno gets excited when guests arrive, leash is hanging on the coat rack.',
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Booking Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PetColors.dark),
        ),
        const SizedBox(height: 6),
        const Text(
          'Please verify the details below before sending your request.',
          style: TextStyle(fontSize: 13.5, color: PetColors.darkMuted),
        ),
        const SizedBox(height: 20),

        PetCareCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _buildReviewRow(Icons.category_rounded, 'Service', _selectedService.label),
              const Divider(),
              _buildReviewRow(Icons.person_rounded, 'Provider', widget.provider.name),
              const Divider(),
              _buildReviewRow(Icons.pets_rounded, 'Pet', _selectedPet?.name ?? 'None'),
              const Divider(),
              _buildReviewRow(
                Icons.calendar_today_rounded,
                'Schedule',
                '${DateFormat('MMM d, yyyy').format(_selectedDate)} at ${_selectedTime.format(context)}',
              ),
              const Divider(),
              _buildReviewRow(Icons.location_on_rounded, 'Address', _addressController.text.trim()),
              if (_notesController.text.trim().isNotEmpty) ...[
                const Divider(),
                _buildReviewRow(Icons.notes_rounded, 'Notes', _notesController.text.trim()),
              ],
              const Divider(),
              _buildReviewRow(
                Icons.payments_rounded,
                'Total Price',
                '₹$_calculatedPrice',
                isHighlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PetColors.amberLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PetColors.amber.withOpacity(0.3)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: PetColors.amber, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payment is requested only after the service is marked complete by the provider. You can track GPS and chat throughout the session.',
                  style: TextStyle(fontSize: 12.5, color: PetColors.dark, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: isHighlight ? PetColors.primary : PetColors.darkMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              color: PetColors.darkMuted,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: isHighlight ? 16 : 14,
                fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
                color: isHighlight ? PetColors.primary : PetColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessConfirmation() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: PetColors.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 52,
                    color: PetColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking Request Sent!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: PetColors.dark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your request has been delivered to ${widget.provider.name}. Current status: REQUESTED. You will be notified once the provider responds.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: PetColors.darkMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),
              PetCareCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildReviewRow(Icons.pets_rounded, 'Pet', _selectedPet?.name ?? ''),
                    const Divider(),
                    _buildReviewRow(Icons.category_rounded, 'Service', _selectedService.label),
                    const Divider(),
                    _buildReviewRow(
                      Icons.schedule_rounded,
                      'Time',
                      DateFormat('MMM d, h:mm a').format(_createdBooking!.scheduledAt),
                    ),
                    const Divider(),
                    _buildReviewRow(Icons.payments_rounded, 'Price', '₹${_createdBooking!.priceInr}', isHighlight: true),
                  ],
                ),
              ),
              const Spacer(),
              PetCareButton(
                label: 'View in My Bookings',
                icon: Icons.list_alt_rounded,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const MyBookingsScreen(),
                    ),
                    (route) => route.isFirst,
                  );
                },
              ),
              const SizedBox(height: 12),
              PetCareButton(
                label: 'Back to Home',
                type: PetButtonType.outline,
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
