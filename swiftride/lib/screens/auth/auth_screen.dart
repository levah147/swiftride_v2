// ==================== auth_screen.dart ====================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../services/auth_service.dart';
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
  String _selectedCountryFlag = '🇳🇬';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    String rawInput = _phoneController.text.trim();

    if (rawInput.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }

    // Handle all phone formats: +234802…, 0802…, 802…
    rawInput = rawInput.replaceAll(RegExp(r'[^0-9]'), ''); // keep digits only
    if (rawInput.startsWith('0')) rawInput = rawInput.substring(1);
    if (rawInput.startsWith('234')) rawInput = rawInput.substring(3);

    if (rawInput.length < 9) {
      _showError('Please enter a valid phone number');
      return;
    }

    final phoneNumber = '$_selectedCountryCode$rawInput';

    setState(() => _isLoading = true);
    try {
      final response = await _authService.sendOtp(phoneNumber);
      setState(() => _isLoading = false);

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data?['message'] ?? 'OTP sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(phoneNumber: phoneNumber),
          ),
        );
      } else {
        _showError(response.error ?? 'Failed to send OTP');
      }
    } catch (_) {
      setState(() => _isLoading = false);
      _showError('Network error. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showCountryPickerDialog() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: ['NG', 'GH', 'US', 'GB'],
      onSelect: (country) {
        setState(() {
          _selectedCountryCode = '+${country.phoneCode}';
          _selectedCountryFlag = country.flagEmoji;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    // Transparent status bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFF2f5f76),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // App Logo Section
              SizedBox(
                height: size.height * 0.35,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SwiftRide',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your ride, your way',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Card Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sign in or create an account',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phone Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: _showCountryPickerDialog,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedCountryFlag,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedCountryCode,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                                LengthLimitingTextInputFormatter(15),
                              ],
                              style: const TextStyle(fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: '8022005557',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Continue Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),

                    const SizedBox(height: 30),

                    // Social Buttons
                    _buildSocialButton(
                      icon: Icons.g_mobiledata,
                      text: 'Continue with Google',
                      onPressed: () => _showError('Google Sign-In coming soon'),
                    ),
                    const SizedBox(height: 12),
                    _buildSocialButton(
                      icon: Icons.facebook,
                      text: 'Continue with Facebook',
                      onPressed: () => _showError('Facebook Sign-In coming soon'),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'By signing up, you agree to our Terms & Conditions and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.primary),
      label: Text(
        text,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.primary.withOpacity(0.6)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
