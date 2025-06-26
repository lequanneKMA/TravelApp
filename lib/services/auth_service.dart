// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:lnmq/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // ĐĂNG XUẤT HOÀN TOÀN
  Future<void> signOut() async {
    try {
      // 1. Sign out Firebase Auth
      await _firebaseAuth.signOut();
      
      // 2. Sign out Google 
      await _googleSignIn.signOut();
      
      // 3. Disconnect Google account hoàn toàn
      await _googleSignIn.disconnect();
      
      print('Successfully signed out');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // ĐĂNG NHẬP GOOGLE (KHÔNG CÓ ĐĂNG KÝ)
  Future<User?> signInWithGoogle() async {
    try {
      // Đảm bảo signed out trước khi sign in
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User hủy đăng nhập

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      User? user = userCredential.user;

      // CHỈ CẬP NHẬT THÔNG TIN, KHÔNG TẠO MỚI
      if (user != null) {
        await _updateUserLoginInfo(user);
      }

      return user;
    } catch (e) {
      print('Lỗi đăng nhập Google: $e');
      rethrow;
    }
  }

  // ĐĂNG KÝ EMAIL/PASSWORD (RIÊNG BIỆT)
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

        // TẠO USER DOCUMENT KHI ĐĂNG KÝ
        await _createUserDocument(user, displayName);
      }
      return user;
    } catch (e) {
      print('Lỗi đăng ký: $e');
      rethrow;
    }
  }

  // ĐĂNG NHẬP EMAIL/PASSWORD (KHÔNG TẠO MỚI)
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      // CHỈ CẬP NHẬT LOGIN TIME
      if (user != null) {
        await _updateUserLoginInfo(user);
      }
      return user;
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      rethrow;
    }
  }

  // HELPER: TẠO USER DOCUMENT (CHỈ KHI ĐĂNG KÝ)
  Future<void> _createUserDocument(User user, [String? displayName]) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      // CHỈ TẠO NẾU CHƯA TỒN TẠI
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set(AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: displayName ?? user.displayName ?? '',
          photoUrl: user.photoURL,
          favoritePlaceIds: [],
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        ).toFirestore());
        
        print('Created new user document for ${user.uid}');
      }
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  // HELPER: CẬP NHẬT THÔNG TIN LOGIN (KHI ĐĂNG NHẬP)
  Future<void> _updateUserLoginInfo(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists) {
        // User đã tồn tại -> chỉ cập nhật lastLoginAt
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        print('Updated login time for existing user ${user.uid}');
      } else {
        // User chưa tồn tại (trường hợp đặc biệt) -> tạo mới
        await _createUserDocument(user);
        print('Created missing user document for ${user.uid}');
      }
    } catch (e) {
      print('Error updating user login info: $e');
    }
  }

  // CẬP NHẬT PROFILE
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
      await user.reload();
    }
  }

  // RESET PASSWORD
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Lỗi reset password: $e');
      rethrow;
    }
  }

  // KIỂM TRA ADMIN
  Future<bool> isAdmin() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['role'] == 'admin' || doc.data()?['isAdmin'] == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // AUTH STATE STREAM
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}