import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

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

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.length != 10) {
      _showError('சரியான மொபைல் எண்ணை உள்ளிடவும் (10 digits)');
      return;
    }

    _showLoading();

    try {
      if (kIsWeb) {
        final confirmationResult = await AuthService.sendOTPWeb(phone);
        ref.read(confirmationResultProvider.notifier).updateResult(confirmationResult);
        
        _hideLoading();
        if (mounted) {
          context.go('/otp', extra: {
            'isSignUp': false,
            'phone': phone,
          });
        }
      } else {
        await AuthService.sendOTPMobile(
          phone,
          (verificationId) {
            ref.read(verificationIdProvider.notifier).updateId(verificationId);
            _hideLoading();
            if (mounted) {
              context.go('/otp', extra: {
                'isSignUp': false,
                'phone': phone,
              });
            }
          },
          (error) {
            _hideLoading();
            _showError(error);
          },
        );
      }
    } catch (e) {
      _hideLoading();
      _showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(decoration: AppTheme.gradientAppBar),
        title: const Text('உள்நுழைய (Sign In)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'உங்கள் எண்',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixText: '+91 ',
                            labelText: 'Phone Number',
                          ),
                          maxLength: 10,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          decoration: AppTheme.gradientButton,
                          child: ElevatedButton(
                            onPressed: _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: const Text('OTP அனுப்பு'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
