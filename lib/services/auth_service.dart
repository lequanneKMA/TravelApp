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

  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
      // Reload user để cập nhật thông tin
      await user.reload();
    }
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
            createdAt: DateTime.now(), // Thêm createdAt
          ).toFirestore());
        } else {
          // Cập nhật lastLoginAt nếu user đã tồn tại
          await _firestore.collection('users').doc(user.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return user;
    } catch (e) {
      print('Lỗi đăng nhập Google: $e');
      rethrow;
    }
  }

  Future<User?> signUpWithEmailPassword(String email, String password, String displayName) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Cập nhật display name
        await user.updateDisplayName(displayName);
        await user.reload();

        // Tạo document người dùng
        await _firestore.collection('users').doc(user.uid).set(AppUser(
          uid: user.uid,
          email: email,
          displayName: displayName,
          favoritePlaceIds: [],
          createdAt: DateTime.now(),
        ).toFirestore());
      }
      return user;
    } catch (e) {
      print('Lỗi đăng ký: $e');
      rethrow;
    }
  }

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Cập nhật lastLoginAt
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Lỗi reset password: $e');
      rethrow;
    }
  }

  // Stream để theo dõi auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}