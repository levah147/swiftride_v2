import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/driver_service.dart';
import '../main/home_screen.dart';
import '../rides/rides_screen.dart';
import '../account/account_screen.dart';
import '../drivers/driver_earnings_screen.dart';
import '../drivers/driver_rides_screen.dart';
import '../drivers/driver_profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final DriverService _driverService = DriverService();
  
  int _currentIndex = 0;
  late List<Widget> _screens;
  bool _isDriver = false;
  bool _isApproved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final response = await _driverService.getDriverStatus();
      
      if (!mounted) return;
      
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        // Check if user is a driver
        if (data.containsKey('is_driver') && data['is_driver'] == false) {
          // User is not a driver
          setState(() {
            _isDriver = false;
            _isApproved = false;
            _isLoading = false;
            _initializeRiderScreens();
          });
          return;
        }
        
        // User is a driver - check if approved
        if (data.containsKey('status')) {
          final status = data['status'] as String;
          final isApproved = status.toLowerCase() == 'approved';
          
          setState(() {
            _isDriver = true;
            _isApproved = isApproved;
            _isLoading = false;
            _initializeDriverScreens();
          });
          
          // Show approval notification if just approved
          if (isApproved) {
            _showApprovalModal();
          }
        }
      } else {
        setState(() {
          _isDriver = false;
          _isApproved = false;
          _isLoading = false;
          _initializeRiderScreens();
        });
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
      setState(() {
        _isDriver = false;
        _isApproved = false;
        _isLoading = false;
        _initializeRiderScreens();
      });
    }
  }

  void _initializeRiderScreens() {
    _screens = [
      HomeScreen(onNavigate: _handleNavigation),
      RidesScreen(onNavigate: _handleNavigation),
      AccountScreen(onNavigate: _handleNavigation),
    ];
  }

  void _initializeDriverScreens() {
    _screens = [
      const DriverEarningsScreen(),
      const DriverRidesScreen(),
      DriverProfileScreen(onNavigate: _handleNavigation),
    ];
    _currentIndex = 0;
  }

  void _showApprovalModal() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Congratulations! 🎉',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'You\'ve been approved as a driver!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You can now accept ride requests and start earning',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Driver Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _handleNavigation(String action, {Map<String, dynamic>? data}) {
    switch (action) {
      case 'destination_selection':
        Navigator.of(context).pushNamed(AppRoutes.destinationSelection);
        break;

      case 'schedule_ride':
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0066FF)),
          ),
        ),
      );
    }

    // Rider Navigation
    if (!_isDriver) {
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

    // Driver Navigation
    if (_isDriver && _isApproved) {
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
              icon: Icon(Icons.trending_up),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car),
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

    // Driver Pending Approval - Show Account Screen
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: 2, // Always show account screen
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        elevation: 0.5,
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {
          if (index == 2) {
            setState(() => _currentIndex = 2);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
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