import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_messenger.dart';
import '../../core/theme.dart';
import '../../widgets/petcare_button.dart';
import '../home/home_screen.dart';
import '../pets/add_pet_screen.dart';

class OwnerProfileSetupScreen extends StatefulWidget {
  final String phone;

  const OwnerProfileSetupScreen({super.key, required this.phone});

  @override
  State<OwnerProfileSetupScreen> createState() => _OwnerProfileSetupScreenState();
}

class _OwnerProfileSetupScreenState extends State<OwnerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await UserApiService().registerPetOwner(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      );

      if (!mounted) return;
      showAppSnackBar('Welcome to PetCare, ${_nameController.text.trim()}!', isSuccess: true);

      // Offer to add pet immediately
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AddPetScreen(isFirstTime: true),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        showAppSnackBar('Failed to save profile: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile Setup'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: PetColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: PetColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tell us about yourself',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: PetColors.dark,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Service providers will see your name when you request bookings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: PetColors.darkMuted,
                  ),
                ),
                const SizedBox(height: 32),

                // Name Field
                const Text(
                  'Full Name *',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: PetColors.dark,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Rahul Sharma',
                    prefixIcon: Icon(Icons.badge_outlined, color: PetColors.darkMuted),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (val.trim().length < 2) {
                      return 'Name is too short';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email Field
                const Text(
                  'Email Address (Optional)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: PetColors.dark,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'e.g. rahul@example.com',
                    prefixIcon: Icon(Icons.email_outlined, color: PetColors.darkMuted),
                  ),
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(val.trim())) {
                        return 'Please enter a valid email address';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Phone (Readonly)
                const Text(
                  'Verified Phone',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: PetColors.dark,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: PetColors.borderSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PetColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: PetColors.success, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        widget.phone,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PetColors.dark,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),
                PetCareButton(
                  label: 'Continue to Pet Setup',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            // Can skip pet setup and go straight home
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                              (route) => false,
                            );
                          },
                    child: const Text(
                      'I will set up later',
                      style: TextStyle(color: PetColors.darkMuted, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
