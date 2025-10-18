import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftride/services/api_client.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/main/main_navigation_screen.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final AuthService _authService = AuthService();
  String? _token;
  bool _isInitialized = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Fade animation for the entire screen
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Slide animation for text elements
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('🚀 Splash Screen Initialization Started');
      
      // Run initialization tasks in parallel
      await Future.wait([
        _checkAuthStatus(),
        Future.delayed(
            const Duration(milliseconds: 2500)), // Minimum splash time
      ]);

      if (!mounted) return;
      
      _isInitialized = true;
      debugPrint('✅ Initialization Complete. IsLoggedIn: $_isLoggedIn');
      _navigateToNextScreen();
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
      // Even if there's an error, navigate after delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _isInitialized = true;
        _navigateToNextScreen();
      }
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      debugPrint('🔍 Checking authentication status...');
      
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('access_token');

      debugPrint('Token exists: ${_token != null && _token!.isNotEmpty}');

      // If token exists, verify it's still valid by trying to get user profile
      if (_token != null && _token!.isNotEmpty) {
        debugPrint('🔐 Token found. Verifying with backend...');
        
        try {
          final response = await _authService.getCurrentUser().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⏱️ Auth check timeout');
              return ApiResponse.error('Auth check timeout');
            },
          );
          
          _isLoggedIn = response.isSuccess;
          
          if (_isLoggedIn) {
            debugPrint('✅ Token verified. User is logged in');
          } else {
            debugPrint('❌ Token invalid: ${response.error}');
          }
        } catch (e) {
          debugPrint('❌ Error verifying token: $e');
          _isLoggedIn = false;
        }
      } else {
        _isLoggedIn = false;
        debugPrint('⚠️ No token found. User not logged in');
      }
    } catch (e) {
      debugPrint('❌ Error checking auth status: $e');
      _isLoggedIn = false;
      _token = null;
    }
  }

  void _navigateToNextScreen() {
    if (!mounted || !_isInitialized) {
      debugPrint('⚠️ Cannot navigate: mounted=$mounted, initialized=$_isInitialized');
      return;
    }

    // Add a small delay for smooth transition
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) {
        debugPrint('⚠️ Widget unmounted during navigation delay');
        return;
      }

      debugPrint('🔀 Navigating to: ${_isLoggedIn ? 'MainNavigationScreen' : 'AuthScreen'}');

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            // Use _isLoggedIn (verified with API) instead of just checking token
            return _isLoggedIn
                ? const MainNavigationScreen()
                : const AuthScreen();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return FadeTransition(
              opacity: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A2E),
              Color(0xFF0A0A0A),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxH = constraints.maxHeight;
              final maxW = constraints.maxWidth;

              // Scale sizes responsively
              final logoSize = maxH * 0.10;
              final titleFontSize = maxH * 0.065;
              final animationHeight = maxH * 0.30;
              final textFontSize = maxH * 0.022;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Brand + Logo
                  SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.directions_car_rounded,
                            color: Colors.white,
                            size: logoSize * 0.5,
                          ),
                        ),
                        SizedBox(height: maxH * 0.03),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                          ),
                          child: Text(
                            'SwiftRide',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -2,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: maxH * 0.05),

                  // Lottie Car Animation
                  Lottie.asset(
                    'assets/animations/car_animation.json',
                    width: maxW * 0.8,
                    height: animationHeight,
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                  ),

                  const Spacer(flex: 1),

                  // Bottom Text + Loader
                  SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Your ride, your way',
                          style: TextStyle(
                            fontSize: textFontSize,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: maxH * 0.015),
                        SizedBox(
                          width: maxW * 0.1,
                          height: maxW * 0.1,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}