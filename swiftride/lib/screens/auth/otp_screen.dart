// ==================== otp_screen.dart (overflow fixed) ====================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swiftride/screens/main/main_navigation_screen.dart';
import '../../services/auth_service.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (index) => FocusNode());
  final AuthService _authService = AuthService();

  bool _isVerifying = false;
  bool _canResend = false;
  int _resendTimer = 60;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startResendTimer() async {
    setState(() => _canResend = false);
    for (int i = 60; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _resendTimer = i);
    }
    setState(() => _canResend = true);
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    bool filled = _controllers.every((c) => c.text.isNotEmpty);
    if (filled) {
      FocusScope.of(context).unfocus();
      _verifyOTP();
    }
  }

  void _onKeyEvent(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _verifyOTP() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _showError('Please enter complete OTP');
      return;
    }
    setState(() => _isVerifying = true);
    try {
      final res = await _authService.verifyOtp(widget.phoneNumber, otp);
      setState(() => _isVerifying = false);
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to SwiftRide!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (_) => false,
        );
      } else {
        _showError(res.error ?? 'Invalid OTP');
        for (var c in _controllers) c.clear();
        _focusNodes[0].requestFocus();
      }
    } catch (_) {
      setState(() => _isVerifying = false);
      _showError('Network error. Please try again.');
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;
    setState(() {
      _resendTimer = 60;
    });
    _startResendTimer();
    try {
      final res = await _authService.sendOtp(widget.phoneNumber);
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data?['message'] ?? 'New OTP sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(res.error ?? 'Failed to resend OTP');
      }
    } catch (_) {
      _showError('Network error. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2f5f76);
    final backgroundColor =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F6F8);

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: FadeTransition(
        opacity: _fadeController,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 28,
              right: 28,
              top: 40,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: primaryColor),
                  ),
                ),
                const SizedBox(height: 40),

                Icon(
                  Icons.directions_car_rounded,
                  color: primaryColor,
                  size: 60,
                ),
                const SizedBox(height: 12),

                Text(
                  "SwiftRide",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.2,
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  "Enter the 6-digit code sent to\n${widget.phoneNumber}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryColor.withOpacity(0.8),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 40),

                // OTP Input Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 50,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _focusNodes[index].hasFocus
                              ? primaryColor
                              : primaryColor.withOpacity(0.4),
                          width: _focusNodes[index].hasFocus ? 2.2 : 1.2,
                        ),
                        boxShadow: _focusNodes[index].hasFocus
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.2),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (e) => _onKeyEvent(e, index),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
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
                          onChanged: (val) => _onCodeChanged(val, index),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 40),

                if (_isVerifying)
                  Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Verifying...",
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 60),

                _canResend
                    ? TextButton(
                        onPressed: _resendOTP,
                        child: Text(
                          "Resend code",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Text(
                        "Resend code in $_resendTimer s",
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.7),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
