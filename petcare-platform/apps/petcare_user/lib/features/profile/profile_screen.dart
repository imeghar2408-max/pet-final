import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/api_service.dart';
import '../../core/app_messenger.dart';
import '../../core/theme.dart';
import '../../widgets/petcare_card.dart';
import '../auth/welcome_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../pets/my_pets_screen.dart';
import '../support/support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final data = await UserApiService().getMe();
    if (mounted) {
      setState(() {
        _user = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out of your PetCare account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: PetColors.darkMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PetColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      showAppSnackBar('Signed out successfully');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?['name'] ?? 'Pet Parent';
    final phone = _user?['phone'] ?? FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    final email = _user?['email'] as String?;

    return Scaffold(
      backgroundColor: PetColors.background,
      appBar: AppBar(
        title: const Text('Account & Settings'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PetColors.primary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Avatar & Info Card
                  PetCareCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: PetColors.primaryLight,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'P',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: PetColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: PetColors.dark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                phone,
                                style: const TextStyle(fontSize: 13, color: PetColors.darkMuted),
                              ),
                              if (email != null && email.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: const TextStyle(fontSize: 12.5, color: PetColors.darkLight),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: PetColors.sageLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Pet Owner',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: PetColors.sage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Menu Section: Pet & Bookings
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'MANAGEMENT',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: PetColors.darkLight,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  PetCareCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildMenuTile(
                          icon: Icons.pets_rounded,
                          iconColor: PetColors.primary,
                          title: 'My Pets',
                          subtitle: 'View, add, and manage your pets',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MyPetsScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildMenuTile(
                          icon: Icons.calendar_today_rounded,
                          iconColor: PetColors.sky,
                          title: 'Booking History',
                          subtitle: 'View past services, receipts, and ratings',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Menu Section: Support & Legal
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'SUPPORT & PLATFORM',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: PetColors.darkLight,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  PetCareCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildMenuTile(
                          icon: Icons.support_agent_rounded,
                          iconColor: PetColors.sage,
                          title: 'Help & Resolution Center',
                          subtitle: 'File a complaint or track existing reports',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SupportScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildMenuTile(
                          icon: Icons.shield_outlined,
                          iconColor: PetColors.amber,
                          title: 'Trust & Safety Standards',
                          subtitle: 'Learn about verified providers & background checks',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                title: const Text('PetCare Safety Commitment'),
                                content: const Text(
                                  'Every caregiver on PetCare completes government identity verification and operations screening. Every active walk is guarded by live GPS telemetry and safe-zone alerting.',
                                  style: TextStyle(height: 1.4),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Understood'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildMenuTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: PetColors.darkLight,
                          title: 'About PetCare',
                          subtitle: 'Version 1.0.0 (Production Build)',
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'PetCare User App',
                              applicationVersion: '1.0.0',
                              applicationLegalese: '© 2026 PetCare Technologies Inc.',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Out Button
                  PetCareCard(
                    padding: EdgeInsets.zero,
                    child: _buildMenuTile(
                      icon: Icons.logout_rounded,
                      iconColor: PetColors.error,
                      title: 'Sign Out',
                      titleColor: PetColors.error,
                      subtitle: 'Securely sign out of your account',
                      onTap: _confirmSignOut,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: titleColor ?? PetColors.dark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: PetColors.darkMuted),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: PetColors.darkLight,
      ),
    );
  }
}
