import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';

class OTPScreen extends ConsumerStatefulWidget {
  final bool isSignUp;
  final String phone;
  final String name;
  final String ward;

  const OTPScreen({
    super.key,
    required this.isSignUp,
    required this.phone,
    this.name = '',
    this.ward = '',
  });

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() => _resendTimer = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _showLoading() {
    setState(() => _isLoading = true);
  }

  void _hideLoading() {
    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;

    _showLoading();

    try {
      UserCredential userCredential;
      if (kIsWeb) {
        final confirmationResult = ref.read(confirmationResultProvider);
        if (confirmationResult == null) throw 'Session expired';
        userCredential = await AuthService.verifyOTPWeb(confirmationResult, otp);
      } else {
        final verificationId = ref.read(verificationIdProvider);
        if (verificationId.isEmpty) throw 'Session expired';
        userCredential = await AuthService.verifyOTPMobile(verificationId, otp);
      }

      String uid = userCredential.user!.uid;

      if (widget.isSignUp) {
        await FirestoreService.createUser(uid, {
          'phone': widget.phone,
          'name': widget.name,
          'ward': widget.ward,
          'role': 'citizen',
          'points': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) context.go('/home');
      } else {
        DocumentSnapshot doc = await FirestoreService.getUser(uid);
        if (doc.exists) {
          if (mounted) context.go('/home');
        } else {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            _showError('பதிவு செய்யப்படவில்லை. Sign Up செய்யவும்.');
            context.go('/');
          }
        }
      }
    } catch (e) {
      _hideLoading();
      _showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final String maskedPhone = widget.phone.length > 4
        ? '+91 ******${widget.phone.substring(widget.phone.length - 4)}'
        : widget.phone;

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: const TextStyle(
          fontSize: 20, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.accentGreen),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(decoration: AppTheme.gradientAppBar),
        title: const Text('OTP சரிபார்ப்பு'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'OTP அனுப்பப்பட்டது',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        maskedPhone,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Pinput(
                        length: 6,
                        controller: _otpController,
                        autofocus: true,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            border: Border.all(color: AppTheme.primaryGreen, width: 2),
                          ),
                        ),
                        onCompleted: (_) => _verifyOtp(),
                      ),
                      const SizedBox(height: 24),
                      if (_isLoading)
                        const CircularProgressIndicator(color: AppTheme.primaryGreen)
                      else
                        Container(
                          width: double.infinity,
                          decoration: AppTheme.gradientButton,
                          child: ElevatedButton(
                            onPressed: _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('சரிபார்க்கவும்', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _resendTimer == 0
                            ? () {
                                context.pop();
                              }
                            : null,
                        child: Text(
                          _resendTimer > 0
                              ? "மீண்டும் அனுப்ப ($_resendTimer)"
                              : "OTP வரவில்லையா? மீண்டும் முயற்சிக்கவும்",
                          style: TextStyle(
                            color: _resendTimer > 0 ? Colors.grey : AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
