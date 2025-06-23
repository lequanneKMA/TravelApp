// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:lnmq/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<void> signOut() async {
    final googleSignIn = GoogleSignIn();
    try {
      await googleSignIn.disconnect(); // Xóa cache tài khoản Google trên máy
    } catch (_) {
      // Có thể không cần xử lý lỗi ở đây
    }
    await googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // Người dùng hủy đăng nhập

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      User? user = userCredential.user;

      // Tạo document người dùng nếu chưa có
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set(AppUser(
            uid: user.uid,
            email: user.email!,
            displayName: user.displayName ?? '',
            photoUrl: user.photoURL,
            favoritePlaceIds: [],
          ).toFirestore());
        }
      }
      return user;
    } catch (e) {
      print('Lỗi đăng nhập Google: $e');
      rethrow;
    }
  }
}