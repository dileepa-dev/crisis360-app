import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crisis360app/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterController {
  String? status;
  String? errorMessage;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    required String province,
    required String district,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'province': province,
      'district': district,
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'USER',
    });
  }

  Future<void> register(
      String name,
      String email,
      String province,
      String district,
      String password,
      ) async {
    try {
      // 1️⃣ Create user in Firebase Auth
      User? user = await firebaseAuthService.value
          .signUpWithEmailAndPassword(email, password);

      if (user == null) {
        errorMessage =  "User creation failed";
      }

      // 2️⃣ Save extra data in Firestore
      await createUser(
        uid: user!.uid,
        name: name,
        email: email,
        province: province,
        district: district,
      );
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message;
      rethrow;
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    }
  }
}