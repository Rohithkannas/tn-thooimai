import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedWard;
  bool _isLoading = false;

  final List<String> _wards = [
    "SVCE Campus",
    "Ward 1 - Sriperumbudur",
    "Ward 2 - Mambakkam",
    "Ward 3 - Nemam",
    "Ward 4 - Karukku",
  ];

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
    final name = _nameController.text.trim();

    if (phone.length != 10) {
      _showError('சரியான மொபைல் எண்ணை உள்ளிடவும் (10 digits)');
      return;
    }
    if (name.length < 2) {
      _showError('உங்கள் பெயரை சரியாக உள்ளிடவும்');
      return;
    }
    if (_selectedWard == null) {
      _showError('தயவுசெய்து வார்டை தேர்ந்தெடுக்கவும்');
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
            'isSignUp': true,
            'phone': phone,
            'name': name,
            'ward': _selectedWard,
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
                'isSignUp': true,
                'phone': phone,
                'name': name,
                'ward': _selectedWard,
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
        title: const Text('புதிய பயனர் (Sign Up)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : SingleChildScrollView(
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
                          'பதிவு செய்ய',
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
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            hintText: 'உங்கள் பெயர்',
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'வார்டு (Ward)',
                          ),
                          value: _selectedWard,
                          items: _wards.map((ward) {
                            return DropdownMenuItem(
                              value: ward,
                              child: Text(ward),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedWard = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
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
