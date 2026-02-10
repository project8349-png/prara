import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> signUp(String email, String password, String name, String username) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = cred.user!;
    await _db.collection('Users').doc(user.uid).set({
      'name': name,
      'username': username,
      'email': email,
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
      'online': true,
    });
    return user;
  }

  Future<void> updatePhoto(String uid, String photoUrl) async {
    await _db.collection('Users').doc(uid).update({'photoUrl': photoUrl});
  }

  Future<User?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = cred.user!;
    await _db.collection('Users').doc(user.uid).update({'lastSeen': FieldValue.serverTimestamp(), 'online': true});
    return user;
  }

  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _db.collection('Users').doc(user.uid).update({'online': false, 'lastSeen': FieldValue.serverTimestamp()});
    }
    await _auth.signOut();
  }
}
