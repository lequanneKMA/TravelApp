import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lnmq/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _usersCollection = 'users';

  // Lấy thông tin người dùng từ Firestore (Real-time updates)
  Stream<AppUser?> getUserData(String uid) {
    return _firestore.collection(_usersCollection).doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    });
  }

  // Stream<AppUser?> của user hiện tại (real-time)
  Stream<AppUser?> getCurrentUserStream() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(null);
      return getUserData(user.uid);
    });
  }

  // Cập nhật thông tin người dùng (ví dụ: thêm/xóa địa điểm yêu thích)
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update(data);
      print('User data for $uid updated successfully!');
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

  // Thêm địa điểm vào danh sách yêu thích
  Future<void> addFavoritePlace(String placeId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("Người dùng chưa đăng nhập.");
    }
    try {
      await _firestore.collection(_usersCollection).doc(currentUser.uid).update({
        'favoritePlaceIds': FieldValue.arrayUnion([placeId]),
      });
      print('Địa điểm $placeId đã được thêm vào yêu thích.');
    } catch (e) {
      print('Lỗi khi thêm địa điểm yêu thích: $e');
      rethrow;
    }
  }

  // Xóa địa điểm khỏi danh sách yêu thích
  Future<void> removeFavoritePlace(String placeId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("Người dùng chưa đăng nhập.");
    }
    try {
      await _firestore.collection(_usersCollection).doc(currentUser.uid).update({
        'favoritePlaceIds': FieldValue.arrayRemove([placeId]),
      });
      print('Địa điểm $placeId đã được xóa khỏi yêu thích.');
    } catch (e) {
      print('Lỗi khi xóa địa điểm yêu thích: $e');
      rethrow;
    }
  }

  // Kiểm tra xem địa điểm có trong danh sách yêu thích của người dùng không
  Future<bool> isPlaceFavorite(String placeId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return false;
    }
    try {
      DocumentSnapshot userDoc = await _firestore.collection(_usersCollection).doc(currentUser.uid).get();
      if (userDoc.exists) {
        AppUser appUser = AppUser.fromFirestore(userDoc);
        return appUser.favoritePlaceIds.contains(placeId);
      }
      return false;
    } catch (e) {
      print('Lỗi khi kiểm tra địa điểm yêu thích: $e');
      return false;
    }
  }
}