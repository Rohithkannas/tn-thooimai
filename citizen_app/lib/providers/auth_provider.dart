import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userDataProvider = FutureProvider.family<DocumentSnapshot?, String>((ref, uid) async {
  if (uid.isEmpty) return null;
  return await FirestoreService.getUser(uid);
});

class ConfirmationResultNotifier extends Notifier<ConfirmationResult?> {
  @override
  ConfirmationResult? build() => null;
  void updateResult(ConfirmationResult? result) => state = result;
}

final confirmationResultProvider = NotifierProvider<ConfirmationResultNotifier, ConfirmationResult?>(ConfirmationResultNotifier.new);

class VerificationIdNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateId(String id) => state = id;
}

final verificationIdProvider = NotifierProvider<VerificationIdNotifier, String>(VerificationIdNotifier.new);
