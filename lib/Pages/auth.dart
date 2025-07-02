import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:run_to_sip_app/models/user_model.dart";
import 'package:http/http.dart' as http;

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

    final newUser = AppUserModel(
      email: email,
      fullName: fullName,
      level: 0,
      xp: 0,
      runsTotal: 0,
      km3: 0,
      km5: 0,
      km7: 0,
      noDistance: 0,
      isAdmin: false
    );

    await fireStore.collection('users').doc(cred.user!.email).set(newUser.toMap());

  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<AppUserModel?> getUserByEmail(String? email) async {
    final userDoc = await fireStore.collection('users').doc(email).get();

    if (!userDoc.exists) return null;

    return AppUserModel.fromMap(userDoc.data()!);
  }


  //Get token from backend
  Future<String?> getIdToken() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Future<http.Response?> callBackendWithAuth(String url) async {
    final idToken = await getIdToken();
    if (idToken == null) {
      print('No user logged in, cannot get ID token');
      return null;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    return response;
  }

}