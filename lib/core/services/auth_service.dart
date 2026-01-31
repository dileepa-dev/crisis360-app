import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

ValueNotifier<FirebaseAuthService> firebaseAuthService = ValueNotifier(FirebaseAuthService());

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register user
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Registration failed";
    }
  }

  // Login user
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Login failed";
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // // Get current user
  // User? getCurrentUser() {
  //   return _auth.currentUser;
  // }
  //
  // // Auth state changes (optional but powerful)
  // Stream<User?> authStateChanges() {
  //   return _auth.authStateChanges();
  // }
}
