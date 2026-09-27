import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import 'otp_verify_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  bool _showPhoneInput = false;
  bool _isNewAccount = true;
  bool _loading = false;

  Future<void> _sendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty || rawPhone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
      return;
    }

    final phone = rawPhone.startsWith('+') ? rawPhone : '+91$rawPhone';
    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Verification failed')),
          );
        },
        codeSent: (verificationId, resendToken) {
          setState(() => _loading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerifyScreen(
                verificationId: verificationId,
                phone: phone,
                isNewAccount: _isNewAccount,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP: $e')),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProviderTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: ProviderTheme.sageLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: ProviderTheme.sageBorder),
                      ),
                      child: const Center(
                        child: Icon(Icons.pets, size: 32, color: ProviderTheme.sagePrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  const Text(
                    'Become a PetCare Provider',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: ProviderTheme.charcoal,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join India\'s leading trusted pet-care community and start earning with flexible hours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: ProviderTheme.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 28),

                  // Value Pillars
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ProviderTheme.border),
                    ),
                    child: Column(
                      children: [
                        _buildPillarRow(
                          icon: Icons.payments_outlined,
                          title: 'Earn providing pet-care services',
                          subtitle: 'Set your own pricing for dog walking, pet sitting, grooming, and more.',
                        ),
                        const Divider(height: 20, color: ProviderTheme.border),
                        _buildPillarRow(
                          icon: Icons.verified_user_outlined,
                          title: 'Get verified before accepting bookings',
                          subtitle: 'PetCare Admin reviews your ID and certifications to ensure platform trust.',
                        ),
                        const Divider(height: 20, color: ProviderTheme.border),
                        _buildPillarRow(
                          icon: Icons.tune,
                          title: 'Choose the services you provide',
                          subtitle: 'Offer walks, drop-in visits, or training based on your schedule.',
                        ),
                        const Divider(height: 20, color: ProviderTheme.border),
                        _buildPillarRow(
                          icon: Icons.location_on_outlined,
                          title: 'Private, on-demand live location',
                          subtitle: 'Your GPS location is only shared while an active service is running.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (!_showPhoneInput) ...[
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _showPhoneInput = true;
                        _isNewAccount = true;
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ProviderTheme.sagePrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Create Provider Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _showPhoneInput = true;
                        _isNewAccount = false;
                      }),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Log In to Existing Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ] else ...[
                    Text(
                      _isNewAccount ? 'Register with Mobile Number' : 'Log In with Mobile Number',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: ProviderTheme.charcoal),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter 10-digit number',
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Text('+91', style: TextStyle(fontWeight: FontWeight.w600, color: ProviderTheme.charcoal)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loading ? null : _sendOtp,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Send Verification Code'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _showPhoneInput = false),
                      child: const Text('Back', style: TextStyle(color: ProviderTheme.textMuted)),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Text(
                    'By continuing, you agree to PetCare\'s Service Terms, Verification Guidelines, and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: ProviderTheme.textSubtle, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillarRow({required IconData icon, required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: ProviderTheme.sageLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: ProviderTheme.sagePrimary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: ProviderTheme.charcoal),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: ProviderTheme.textMuted, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
