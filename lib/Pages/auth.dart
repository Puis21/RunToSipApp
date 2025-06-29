import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth{
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore fireStore = FirebaseFirestore.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChange => firebaseAuth.authStateChanges();

  Future<void> singInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password
    );
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    UserCredential cred = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password
    );
    await fireStore.collection('users').doc(cred.user!.email).set({
      'email': email,
      'fullName': fullName,
      'is_admin': false,
      'date_joined': FieldValue.serverTimestamp(), // current timestamp
      'runs_total': 0,
      '3km': 0,
      '5km': 0,
      '7km': 0,
    });
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

}