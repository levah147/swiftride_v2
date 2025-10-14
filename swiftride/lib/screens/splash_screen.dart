import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/main/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();

    // Fade-in animation for logo and text
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _lottieController = AnimationController(vsync: this);
    _fadeController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 5)); // Simulate loading
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            token == null ? const AuthScreen() : const MainNavigationScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Transparent status bar for immersive look
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1A1A1A)
          : const Color(0xFF2f5f76), // consistent brand color
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Car animation
                    Lottie.asset(
                      'assets/animations/car_animation.json',
                      controller: _lottieController,
                      width: constraints.maxWidth * 0.6,
                      height: constraints.maxHeight * 0.3,
                      onLoaded: (composition) {
                        _lottieController
                          ..duration = composition.duration
                          ..forward();
                      },
                    ),
                    SizedBox(height: constraints.maxHeight * 0.05),

                    // App name
                    Text(
                      'SwiftRide',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'Your ride, your way',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
