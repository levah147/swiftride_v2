// ==================== auth_screen.dart ====================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  String _selectedCountryCode = '+234';
  bool _isLoading = false;
  
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    // Validate phone number
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your phone number');
      return;
    }

    // Validate phone number length (Nigerian numbers are 10 digits after country code)
    if (_phoneController.text.trim().length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }

    // Build full phone number
    String phoneNumber = _selectedCountryCode + _phoneController.text.trim();
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Call backend API to send OTP
      final response = await _authService.sendOtp(phoneNumber);

      setState(() {
        _isLoading = false;
      });

      if (response.isSuccess) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data?['message'] ?? 'OTP sent successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate to OTP screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(
                phoneNumber: phoneNumber,
              ),
            ),
          );
        }
      } else {
        _showError(response.error ?? 'Failed to send OTP');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Network error. Please check your connection and try again.');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top promotional section
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'New to SwiftRide? Enjoy up to 20% off on\nyour first ride-hailing trips!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom authentication section
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      'Enter your number',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Phone number input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // Country code dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 24,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: Colors.green,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '🇳🇬',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedCountryCode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                          
                          // Phone number field
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                              decoration: InputDecoration(
                                hintText: '8167791934',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Sign in button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Sign in',
                              style: AppTextStyles.button,
                            ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Or divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.grey[600]),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Or',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Google sign in
                    _buildSocialButton(
                      icon: Icons.g_mobiledata,
                      text: 'Sign in with Google',
                      onPressed: () {
                        _showError('Google Sign-In coming soon');
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Facebook sign in
                    _buildSocialButton(
                      icon: Icons.facebook,
                      text: 'Sign in with Facebook',
                      onPressed: () {
                        _showError('Facebook Sign-In coming soon');
                      },
                    ),
                    
                    const Spacer(),
                    
                    // Terms and conditions
                    Text(
                      'By signing up, you agree to our Terms & Conditions, acknowledge our Privacy Policy, and confirm that you\'re over 18. We may send promotions related to our services — you can unsubscribe anytime in Communication Settings under your profile.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.grey[600]!),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(text, style: AppTextStyles.button),
        ],
      ),
    );
  }
}
