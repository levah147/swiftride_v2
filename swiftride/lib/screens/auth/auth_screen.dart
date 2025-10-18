import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../constants/app_dimensions.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedCountryCode = '+234';
  String _selectedCountryFlag = '🇳🇬';
  String _selectedCountryIso = 'NG';
  bool _isLoading = false;

  // Rate limiting
  DateTime? _lastOtpRequest;
  int _otpRequestCount = 0;
  static const int _maxOtpRequestsPerHour = 5;
  static const Duration _rateLimitWindow = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    _setSystemUIOverlay();
  }

  void _setSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // Rate limiting check
  bool _canRequestOtp() {
    if (_lastOtpRequest == null) return true;

    final timeSinceLastRequest = DateTime.now().difference(_lastOtpRequest!);

    // Reset counter after rate limit window
    if (timeSinceLastRequest > _rateLimitWindow) {
      _otpRequestCount = 0;
      return true;
    }

    // Check if exceeded max requests
    if (_otpRequestCount >= _maxOtpRequestsPerHour) {
      final remainingTime = _rateLimitWindow - timeSinceLastRequest;
      final minutes = remainingTime.inMinutes;
      _showError('Too many requests. Please try again in $minutes minutes.');
      return false;
    }

    // Require minimum 30 seconds between requests
    if (timeSinceLastRequest.inSeconds < 30) {
      _showError('Please wait 30 seconds before requesting another OTP.');
      return false;
    }

    return true;
  }

    String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove spaces, dashes, parentheses, etc.
    String digits = value.replaceAll(RegExp(r'[^0-9+]'), '');

    // Normalize Nigerian numbers
    if (_selectedCountryIso == 'NG') {
      // Acceptable formats:
      // +234XXXXXXXXXX, 234XXXXXXXXXX, 0XXXXXXXXXX, or just XXXXXXXXXX

      // Handle +234 or 234
      if (digits.startsWith('+234')) {
        digits = digits.substring(4);
      } else if (digits.startsWith('234')) {
        digits = digits.substring(3);
      } else if (digits.startsWith('0')) {
        digits = digits.substring(1);
      }

      // Now we should have 10 digits left
      if (digits.length != 10) {
        return 'Please enter a valid 10-digit Nigerian number';
      }

      // Valid prefixes in Nigeria (you can extend this list if needed)
      final validPrefixes = [
        '701', '703', '704', '705', '706', '707', '708', '709',
        '802', '803', '804', '805', '806', '807', '808', '809',
        '810', '811', '812', '813', '814', '815', '816', '817',
        '818', '819', '909', '908', '901', '902', '903', '904',
        '905', '906', '907', '915', '913', '912', '911', '917',
      ];

      final prefix = digits.substring(0, 3);

      if (!validPrefixes.contains(prefix)) {
        return 'Please enter a valid Nigerian mobile number';
      }
    } else {
      // For other countries, just basic check
      if (digits.length < 8) {
        return 'Please enter a valid phone number';
      }
    }

    return null;
  }


  String _sanitizePhoneNumber(String input) {
    // Remove all non-digit characters
    String digits = input.replaceAll(RegExp(r'[^0-9]'), '');

    // Remove leading 0
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // Remove country code if included
    String countryDigits = _selectedCountryCode.replaceAll('+', '');
    if (digits.startsWith(countryDigits)) {
      digits = digits.substring(countryDigits.length);
    }

    return digits;
  }

  Future<void> _sendOtp() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check rate limiting
    if (!_canRequestOtp()) {
      return;
    }

    final sanitized = _sanitizePhoneNumber(_phoneController.text.trim());
    final phoneNumber = '$_selectedCountryCode$sanitized';

    setState(() => _isLoading = true);

    try {
      final response = await _authService.sendOtp(phoneNumber);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (response.isSuccess) {
        // Update rate limiting
        _lastOtpRequest = DateTime.now();
        _otpRequestCount++;

        _showSuccess(response.data?['message'] ?? 'OTP sent successfully');

        // Navigate to OTP screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              phoneNumber: phoneNumber,
            ),
          ),
        );
      } else {
        _showError(response.error ?? 'Failed to send OTP. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Network error. Please check your connection and try again.');
      debugPrint('OTP send error: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
      ),
    );
  }

  void _showCountryPickerDialog() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: ['NG', 'GH', 'KE', 'ZA', 'US', 'GB'],
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        backgroundColor: AppColors.surface,
        textStyle: AppTextStyles.body,
        searchTextStyle: AppTextStyles.body,
        inputDecoration: InputDecoration(
          hintText: 'Search country',
          hintStyle: AppTextStyles.inputHint,
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.backgroundSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onSelect: (country) {
        setState(() {
          _selectedCountryCode = '+${country.phoneCode}';
          _selectedCountryFlag = country.flagEmoji;
          _selectedCountryIso = country.countryCode;
        });
        // Revalidate on country change
        if (_phoneController.text.isNotEmpty) {
          _formKey.currentState?.validate();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       resizeToAvoidBottomInset: true, //
      body: Container(
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
        child: SafeArea(
           child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Column(
            children: [
              // App Logo Section
              Expanded(
                flex: 4,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with gradient background
                      Container(
                        width: 80,
                        height: 80,
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
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Brand name with gradient
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                        child: const Text(
                          'SwiftRide',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Your ride, your way',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Card Section
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Sign in or create an account',
                            style: AppTextStyles.heading2,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "We'll send you a code to verify your number",
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 32),

                          // Phone Input
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: AppTextStyles.inputText,
                            validator: _validatePhoneNumber,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            decoration: InputDecoration(
                              hintText: '8167791934',
                              hintStyle: AppTextStyles.inputHint,
                              filled: true,
                              fillColor: AppColors.backgroundSecondary,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: InkWell(
                                onTap: _showCountryPickerDialog,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _selectedCountryFlag,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedCountryCode,
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Continue Button
                          SizedBox(
                            height: AppDimensions.buttonHeightLarge,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.primary.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMedium,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Continue',
                                      style: AppTextStyles.button,
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Divider
                          const Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: AppColors.divider,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'Or continue with',
                                  style: AppTextStyles.caption,
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: AppColors.divider,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Social Buttons
                          _buildSocialButton(
                            iconPath: 'assets/icons/google.png',
                            text: 'Continue with Google',
                            onPressed: () =>
                                _showError('Google Sign-In coming soon'),
                          ),

                          const SizedBox(height: 12),

                          _buildSocialButton(
                            iconPath: 'assets/icons/facebook.png',
                            text: 'Continue with Facebook',
                            onPressed: () =>
                                _showError('Facebook Sign-In coming soon'),
                          ),

                          const SizedBox(height: 32),

                          // Terms & Privacy
                          Text.rich(
                            TextSpan(
                              text: 'By signing up, you agree to our ',
                              style: AppTextStyles.caption,
                              children: [
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      )
      ),)
    );
  }

  Widget _buildSocialButton({
    required String iconPath,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: AppDimensions.buttonHeightMedium,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: AppColors.border,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // If you have icon assets, use Image.asset
            // Otherwise use Icon with color
            Icon(
              text.contains('Google') ? Icons.g_mobiledata : Icons.facebook,
              color: AppColors.textPrimary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: AppTextStyles.button.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
