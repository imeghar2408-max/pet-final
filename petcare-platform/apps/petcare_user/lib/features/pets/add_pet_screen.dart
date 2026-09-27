import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/api_service.dart';
import '../../core/app_messenger.dart';
import '../../core/theme.dart';
import '../../widgets/petcare_button.dart';
import '../home/home_screen.dart';

class AddPetScreen extends StatefulWidget {
  final bool isFirstTime;

  const AddPetScreen({super.key, this.isFirstTime = false});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _medicalController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _behaviourController = TextEditingController();
  final _specialCareController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  String _selectedSpecies = 'Dog';
  String _selectedGender = 'Male';
  String _selectedVaccinationStatus = 'Up to date';
  String? _selectedAvatarUrl;
  bool _isLoading = false;

  final List<Map<String, String>> _speciesList = [
    {'name': 'Dog', 'icon': '🐕'},
    {'name': 'Cat', 'icon': '🐈'},
    {'name': 'Rabbit', 'icon': '🐇'},
    {'name': 'Bird', 'icon': '🦜'},
    {'name': 'Other', 'icon': '🐾'},
  ];

  final List<String> _vaccinationOptions = [
    'Up to date',
    'Partially vaccinated',
    'Not vaccinated',
    'Exempt',
  ];

  // Curated clean pet avatar placeholders
  final List<String> _avatarPresets = [
    'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=200&q=80', // Dog 1
    'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&w=200&q=80', // Dog 2
    'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=200&q=80', // Cat 1
    'https://images.unsplash.com/photo-1573865526739-10659fec78a5?auto=format&fit=crop&w=200&q=80', // Cat 2
  ];

  @override
  void initState() {
    super.initState();
    _selectedAvatarUrl = _avatarPresets[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _medicalController.dispose();
    _allergiesController.dispose();
    _behaviourController.dispose();
    _specialCareController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  String _compileNotes() {
    final parts = <String>[];
    parts.add('Gender: $_selectedGender');
    parts.add('Vaccination: $_selectedVaccinationStatus');
    if (_medicalController.text.trim().isNotEmpty) {
      parts.add('Medical: ${_medicalController.text.trim()}');
    }
    if (_allergiesController.text.trim().isNotEmpty) {
      parts.add('Allergies: ${_allergiesController.text.trim()}');
    }
    if (_behaviourController.text.trim().isNotEmpty) {
      parts.add('Behaviour: ${_behaviourController.text.trim()}');
    }
    if (_specialCareController.text.trim().isNotEmpty) {
      parts.add('Special Care: ${_specialCareController.text.trim()}');
    }
    if (_emergencyContactController.text.trim().isNotEmpty) {
      parts.add('Emergency Contact: ${_emergencyContactController.text.trim()}');
    }
    return parts.join(' | ');
  }

  Future<void> _submit({bool addAnother = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final pet = await UserApiService().addPet(
        name: _nameController.text.trim(),
        species: _selectedSpecies,
        breed: _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        weightKg: double.tryParse(_weightController.text.trim()),
        notes: _compileNotes(),
        photoUrl: _selectedAvatarUrl,
      );

      if (!mounted) return;
      showAppSnackBar('${pet.name} registered successfully!', isSuccess: true);

      if (addAnother) {
        _nameController.clear();
        _breedController.clear();
        _ageController.clear();
        _weightController.clear();
        _medicalController.clear();
        _allergiesController.clear();
        _behaviourController.clear();
        _specialCareController.clear();
        _emergencyContactController.clear();
        setState(() {
          _selectedSpecies = 'Dog';
          _selectedGender = 'Male';
          _selectedVaccinationStatus = 'Up to date';
          _isLoading = false;
        });
        return;
      }

      if (widget.isFirstTime) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar('Failed to register pet: $e', isError: true);
      }
    } finally {
      if (mounted && !addAnother) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetColors.background,
      appBar: AppBar(
        title: Text(widget.isFirstTime ? 'Register Your Pet' : 'Add a Pet'),
        leading: widget.isFirstTime
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        // Enforce pet registration on first launch: no skip button!
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isFirstTime) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: PetColors.sageLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: PetColors.sage.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.shield_outlined, color: PetColors.sage, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please add your pet to browse nearby verified service providers.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: PetColors.dark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Pet Photo / Preset Avatar Selector
                const Text(
                  'Pet Photo',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _avatarPresets.map((url) {
                    final isSelected = _selectedAvatarUrl == url;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatarUrl = url),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? PetColors.dark : PetColors.border,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage(url),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                // Species selector
                const Text(
                  'Species *',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _speciesList.map((s) {
                    final isSelected = _selectedSpecies == s['name'];
                    return ChoiceChip(
                      label: Text('${s['icon']}  ${s['name']}'),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedSpecies = s['name']!);
                      },
                      selectedColor: PetColors.primaryLight,
                      labelStyle: TextStyle(
                        color: isSelected ? PetColors.dark : PetColors.darkMuted,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSelected ? PetColors.dark : PetColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Pet Name
                const Text(
                  'Pet Name *',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Bruno, Bella, Simba',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your pet\'s name';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Breed & Gender Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Breed',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _breedController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(hintText: 'e.g. Golden Retriever'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gender *',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            items: const [
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedGender = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Age and Weight Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Age (Years)',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'e.g. 3'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weight (kg)',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(hintText: 'e.g. 14.5'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Vaccination Status
                const Text(
                  'Vaccination Status *',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedVaccinationStatus,
                  items: _vaccinationOptions
                      .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedVaccinationStatus = v);
                  },
                ),
                const SizedBox(height: 18),

                // Medical Conditions & Allergies
                const Text(
                  'Medical Conditions',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _medicalController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Hip dysplasia, sensitive stomach, none',
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  'Allergies',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Chicken protein, flea bites, pollen',
                  ),
                ),
                const SizedBox(height: 18),

                // Behaviour Notes
                const Text(
                  'Behaviour Notes',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _behaviourController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. High energy, friendly with strangers, barks at motorbikes',
                  ),
                ),
                const SizedBox(height: 18),

                // Special Care Instructions
                const Text(
                  'Special Care Instructions',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _specialCareController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Needs water break every 15 mins. Use chest harness only.',
                  ),
                ),
                const SizedBox(height: 18),

                // Emergency Contact Information
                const Text(
                  'Emergency Contact (Vet / Secondary Guardian)',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: PetColors.dark),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emergencyContactController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Dr. Rajesh Rao (Vet) +91 98450 12345',
                  ),
                ),
                const SizedBox(height: 30),

                // Action Buttons
                PetCareButton(
                  label: widget.isFirstTime ? 'Save & Start Browsing' : 'Save Pet Profile',
                  icon: Icons.check_circle_rounded,
                  isLoading: _isLoading,
                  onPressed: () => _submit(addAnother: false),
                ),

                if (widget.isFirstTime) ...[
                  const SizedBox(height: 12),
                  PetCareButton(
                    label: 'Save & Add Another Pet',
                    type: PetButtonType.outline,
                    isLoading: _isLoading,
                    onPressed: () => _submit(addAnother: true),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
