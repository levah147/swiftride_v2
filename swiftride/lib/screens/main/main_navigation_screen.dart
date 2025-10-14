// ==================== main_navigation_screen.dart ====================
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../main/home_screen.dart';
import '../rides/rides_screen.dart';
import '../account/account_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      HomeScreen(onNavigate: _handleNavigation),
      RidesScreen(onNavigate: _handleNavigation),
      AccountScreen(onNavigate: _handleNavigation),
    ];
  }

  void _handleNavigation(String action, {Map<String, dynamic>? data}) {
    switch (action) {
      case 'destination_selection':
        Navigator.of(context).pushNamed(AppRoutes.destinationSelection);
        break;

      case 'schedule_ride':
        // For now, route to destination selection; scheduling can be handled via arguments later
        Navigator.of(context).pushNamed(AppRoutes.destinationSelection);
        break;

      case 'logout':
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/auth',
          (route) => false,
        );
        break;

      default:
        break;
    }
  }

  void _onNavbarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        elevation: 0.5,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[600],
        onTap: _onNavbarTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Rides',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}