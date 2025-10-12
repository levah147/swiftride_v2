
// ==================== otp_screen.dart ====================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  
  const OTPScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final AuthService _authService = AuthService();
  int _resendTimer = 60;
  bool _isVerifying = false;
  bool _canResend = false;
  
  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }
  
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
  
  void _startResendTimer() {
    setState(() {
      _canResend = false;
    });
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        _startResendTimer();
      } else if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }
  
  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Check if all fields are filled
    bool allFilled = _controllers.every((controller) => controller.text.isNotEmpty);
    if (allFilled) {
      // Remove focus to hide keyboard
      FocusScope.of(context).unfocus();
      // Auto-verify when all fields are filled
      _verifyOTP();
    }
  }
  
  void _onKeyEvent(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }
  
  Future<void> _verifyOTP() async {
    String otp = _controllers.map((controller) => controller.text).join();
    
    if (otp.length != 6) {
      _showError('Please enter complete OTP');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final response = await _authService.verifyOtp(widget.phoneNumber, otp);

      setState(() {
        _isVerifying = false;
      });

      if (response.isSuccess) {
        final data = response.data!;
        final isNewUser = data['user_created'] ?? false;
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isNewUser 
                    ? 'Account created successfully! Welcome to SwiftRide.' 
                    : 'Welcome back!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to home screen and remove all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        _showError(response.error ?? 'Invalid OTP. Please try again.');
        // Clear OTP fields on error
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      _showError('Network error. Please check your connection and try again.');
      // Clear OTP fields on error
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;
    
    setState(() {
      _resendTimer = 60;
    });
    _startResendTimer();

    try {
      final response = await _authService.sendOtp(widget.phoneNumber);

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data?['message'] ?? 'New OTP sent successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        _showError(response.error ?? 'Failed to resend OTP');
      }
    } catch (e) {
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Enter the code',
                style: AppTextStyles.heading1.copyWith(
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle with phone number
              Text(
                'A 6-digit code was sent to\n${widget.phoneNumber}',
                style: AppTextStyles.body.copyWith(
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Info text
              Text(
                'Check your terminal for the OTP',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // OTP input fields (6 digits)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return Container(
                    width: 50,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _focusNodes[index].hasFocus 
                            ? AppColors.primary 
                            : Colors.grey[600]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (event) => _onKeyEvent(event, index),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onCodeChanged(value, index),
                        onTap: () {
                          _controllers[index].selection = TextSelection.fromPosition(
                            TextPosition(offset: _controllers[index].text.length),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
              
              if (_isVerifying) ...[
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Verifying...',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Resend timer
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _resendOTP,
                        child: Text(
                          'Resend code',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : Text(
                        'Resend code in $_resendTimer seconds',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
              ),
              
              const SizedBox(height: 24),
              
              // Try different method
              Center(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Alternative verification methods coming soon'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  child: Text(
                    'Try a different method',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
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
// ==================== api_client.dart ====================