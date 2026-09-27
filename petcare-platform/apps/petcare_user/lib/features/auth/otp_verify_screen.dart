import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/api_service.dart';
import '../../core/app_messenger.dart';
import '../../core/theme.dart';
import '../../widgets/petcare_button.dart';
import '../home/home_screen.dart';
import 'owner_profile_setup_screen.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String verificationId;
  final String phone;
  final int? resendToken;

  const OtpVerifyScreen({
    super.key,
    required this.verificationId,
    required this.phone,
    this.resendToken,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  int _secondsLeft = 60;
  Timer? _timer;
  String _currentVerificationId = '';

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _resendCode() async {
    if (_secondsLeft > 0) return;
    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phone,
        forceResendingToken: widget.resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (cred) async {
          await FirebaseAuth.instance.signInWithCredential(cred);
        },
        verificationFailed: (e) {
          showAppSnackBar(e.message ?? 'Resend failed', isError: true);
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _currentVerificationId = verificationId;
          });
          _startTimer();
          showAppSnackBar('New verification code sent', isSuccess: true);
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      showAppSnackBar('Failed to resend code: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      showAppSnackBar('Please enter the 6-digit code', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: code,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Query backend to see if this user is already registered as PET_OWNER
        final me = await UserApiService().getMe();

        if (!mounted) return;

        if (me != null && me['petOwnerProfile'] != null) {
          // Returning pet owner -> go straight to Home
          showAppSnackBar('Welcome back, ${me['name'] ?? 'Pet Owner'}!', isSuccess: true);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else {
          // New user or missing profile -> go to OwnerProfileSetupScreen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => OwnerProfileSetupScreen(phone: widget.phone),
            ),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      showAppSnackBar(e.message ?? 'Invalid verification code', isError: true);
    } catch (e) {
      showAppSnackBar('Verification error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Phone'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: PetColors.sageLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    size: 36,
                    color: PetColors.sage,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter Verification Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: PetColors.dark,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: PetColors.darkMuted, height: 1.4),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(
                      text: widget.phone,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: PetColors.dark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // OTP Code Input Field
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 10,
                  color: PetColors.dark,
                ),
                decoration: InputDecoration(
                  hintText: '••••••',
                  counterText: '',
                  hintStyle: TextStyle(
                    fontSize: 28,
                    letterSpacing: 10,
                    color: PetColors.darkLight.withOpacity(0.5),
                  ),
                ),
                onSubmitted: (_) => _verify(),
              ),

              const SizedBox(height: 28),
              PetCareButton(
                label: 'Verify & Continue',
                icon: Icons.check_rounded,
                isLoading: _loading,
                onPressed: _verify,
              ),

              const SizedBox(height: 24),
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'Resend code in ${_secondsLeft}s',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: PetColors.darkLight,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : TextButton(
                        onPressed: _loading ? null : _resendCode,
                        child: const Text(
                          'Resend SMS Code',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: PetColors.primary,
                          ),
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
