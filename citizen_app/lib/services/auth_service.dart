import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // WEB FLOW
  static Future<ConfirmationResult> sendOTPWeb(String phoneNumber) async {
    try {
      ConfirmationResult confirmationResult =
          await FirebaseAuth.instance.signInWithPhoneNumber(
        '+91$phoneNumber',
      );
      return confirmationResult;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  static Future<UserCredential> verifyOTPWeb(
      ConfirmationResult confirmationResult, String otp) async {
    try {
      return await confirmationResult.confirm(otp);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // ANDROID/iOS FLOW
  static Future<void> sendOTPMobile(
    String phoneNumber,
    Function(String verificationId) onCodeSent,
    Function(String error) onError,
  ) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
        } catch (e) {
          // Ignore auto-verification errors
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(_handleAuthError(e));
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  static Future<UserCredential> verifyOTPMobile(
      String verificationId, String otp) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'தவறான தொலைபேசி எண்';
      case 'too-many-requests':
        return 'அதிக முயற்சிகள். சிறிது நேரம் கழித்து முயற்சிக்கவும்';
      case 'invalid-verification-code':
        return 'தவறான OTP. மீண்டும் முயற்சிக்கவும்';
      case 'session-expired':
        return 'OTP காலாவதியானது. மீண்டும் அனுப்பவும்';
      case 'quota-exceeded':
        return 'SMS வரம்பு மீறியது. நாளை முயற்சிக்கவும்';
      case 'network-request-failed':
        return 'இணைய பிழை. தொடர்பை சரிபார்க்கவும்';
      default:
        return 'பிழை: ${e.message ?? e.code}';
    }
  }
}
