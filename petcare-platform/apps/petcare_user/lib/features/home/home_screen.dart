import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/theme.dart';
import '../booking/my_bookings_screen.dart';
import '../pets/my_pets_screen.dart';
import '../profile/profile_screen.dart';
import 'home_tab.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;

  const HomeScreen({super.key, this.initialTab = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    PushService.register();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(
        onNavigateToBookings: () => setState(() => _currentIndex = 1),
        onNavigateToPets: () => setState(() => _currentIndex = 2),
      ),
      const MyBookingsScreen(showBackButton: false),
      const MyPetsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: PetColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: PetColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today_rounded),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets_outlined),
              activeIcon: Icon(Icons.pets_rounded),
              label: 'My Pets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
