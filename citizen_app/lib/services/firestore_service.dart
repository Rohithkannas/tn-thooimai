import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static Future<void> createUser(String uid, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(data);
  }

  static Future<DocumentSnapshot> getUser(String uid) async {
    return await FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  static Future<void> updatePoints(String uid, int points) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'points': FieldValue.increment(points)});
  }
}
