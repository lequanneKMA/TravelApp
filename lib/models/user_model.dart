// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser { // Đổi tên class từ User thành AppUser để tránh xung đột với firebase_auth.User
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final List<String> favoritePlaceIds; // <<< THÊM DÒNG NÀY

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.favoritePlaceIds = const [], // Khởi tạo mặc định là danh sách rỗng
  });

  // Constructor để tạo AppUser từ Firestore DocumentSnapshot
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      favoritePlaceIds: List<String>.from(data['favoritePlaceIds'] ?? []), // Đọc danh sách ID
    );
  }

  // Phương thức để chuyển AppUser thành Map<String, dynamic> để lưu vào Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'favoritePlaceIds': favoritePlaceIds,
    };
  }
}