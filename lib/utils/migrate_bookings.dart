// // lib/utils/migrate_bookings.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:lnmq/models/booking_model.dart';

// class BookingMigration {
//   static Future<void> migrateOldBookings() async {
//     final firestore = FirebaseFirestore.instance;

//     try {
//       print('Bắt đầu di chuyển dữ liệu booking...');

//       // Lấy tất cả dữ liệu từ collection cũ
//       final oldBookingsSnapshot = await firestore.collection('booked_tours').get();
      
//       if (oldBookingsSnapshot.docs.isEmpty) {
//         print('Không có dữ liệu cũ để di chuyển');
//         return;
//       }

//       // Lấy thông tin tour để tính tổng tiền
//       final toursSnapshot = await firestore.collection('tours').get();
//       final Map<String, int> tourPrices = {};
//       for (final tour in toursSnapshot.docs) {
//         final price = tour.data()['price'] as int?;
//         if (price != null) {
//           tourPrices[tour.id] = price;
//         }
//       }

//       // Lấy thông tin user để có email và phone
//       final usersSnapshot = await firestore.collection('users').get();
//       final Map<String, Map<String, String>> userInfo = {};
//       for (final user in usersSnapshot.docs) {
//         final data = user.data();
//         userInfo[user.id] = {
//           'email': data['email'] ?? '',
//           'phoneNumber': data['phoneNumber'] ?? '',
//         };
//       }

//       final batch = firestore.batch();
//       int migrated = 0;

//       for (final doc in oldBookingsSnapshot.docs) {
//         final oldData = doc.data();
        
//         // Kiểm tra xem booking này đã được di chuyển chưa
//         final existingBooking = await firestore
//             .collection('bookings')
//             .where('userId', isEqualTo: oldData['userId'])
//             .where('tourId', isEqualTo: oldData['tourId'])
//             .where('dateStart', isEqualTo: oldData['dateStart'])
//             .get();

//         if (existingBooking.docs.isNotEmpty) {
//           print('Booking đã tồn tại, bỏ qua: ${doc.id}');
//           continue;
//         }

//         final userId = oldData['userId'] as String;
//         final tourId = oldData['tourId'] as String;
//         final numPeople = oldData['numPeople'] as int? ?? 1;
//         final tourPrice = tourPrices[tourId] ?? 0;
//         final totalPrice = tourPrice * numPeople;

//         final userEmailPhone = userInfo[userId] ?? {'email': '', 'phoneNumber': ''};

//         // Tạo booking mới
//         final newBooking = Booking(
//           id: '', // Sẽ được tự động tạo
//           userId: userId,
//           tourId: tourId,
//           tourName: oldData['tourName'] ?? 'Không rõ tên',
//           userName: 'Không rõ tên', // Sẽ cập nhật sau
//           userEmail: userEmailPhone['email']!,
//           userPhone: userEmailPhone['phoneNumber']!,
//           dateStart: oldData['dateStart'] ?? '',
//           numPeople: numPeople,
//           totalPrice: totalPrice,
//           status: BookingStatus.pending, // Mặc định là chờ xử lý
//           createdAt: (oldData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//         );

//         // Thêm vào batch
//         final newDocRef = firestore.collection('bookings').doc();
//         batch.set(newDocRef, newBooking.toFirestore());
//         migrated++;

//         print('Đã chuẩn bị di chuyển booking: ${doc.id} -> ${newDocRef.id}');
//       }

//       // Thực hiện batch write
//       if (migrated > 0) {
//         await batch.commit();
//         print('Đã di chuyển thành công $migrated bookings');
//       } else {
//         print('Không có booking nào cần di chuyển');
//       }

//     } catch (e) {
//       print('Lỗi khi di chuyển dữ liệu: $e');
//       rethrow;
//     }
//   }

//   // Method để cập nhật thông tin user name từ collection users
//   static Future<void> updateUserNamesInBookings() async {
//     final firestore = FirebaseFirestore.instance;

//     try {
//       print('Bắt đầu cập nhật tên user trong bookings...');

//       final bookingsSnapshot = await firestore.collection('bookings').get();
//       final usersSnapshot = await firestore.collection('users').get();

//       final Map<String, String> userNames = {};
//       for (final user in usersSnapshot.docs) {
//         final data = user.data();
//         userNames[user.id] = data['displayName'] ?? data['name'] ?? 'Không rõ tên';
//       }

//       final batch = firestore.batch();
//       int updated = 0;

//       for (final booking in bookingsSnapshot.docs) {
//         final data = booking.data();
//         final userId = data['userId'] as String;
//         final currentUserName = data['userName'] as String?;

//         if (userNames.containsKey(userId) && 
//             (currentUserName == null || currentUserName == 'Không rõ tên')) {
//           batch.update(booking.reference, {
//             'userName': userNames[userId],
//           });
//           updated++;
//         }
//       }

//       if (updated > 0) {
//         await batch.commit();
//         print('Đã cập nhật tên cho $updated bookings');
//       } else {
//         print('Không có booking nào cần cập nhật tên');
//       }

//     } catch (e) {
//       print('Lỗi khi cập nhật tên user: $e');
//       rethrow;
//     }
//   }

//   // Method để chạy toàn bộ migration
//   static Future<void> runFullMigration() async {
//     try {
//       await migrateOldBookings();
//       await updateUserNamesInBookings();
//       print('Migration hoàn tất!');
//     } catch (e) {
//       print('Lỗi trong quá trình migration: $e');
//       rethrow;
//     }
//   }

//   // Method để xóa toàn bộ bookings (để test)
//   static Future<void> clearAllBookings() async {
//     final firestore = FirebaseFirestore.instance;
//     try {
//       print('Bắt đầu xóa toàn bộ bookings...');
//       final snapshot = await firestore.collection('bookings').get();
//       final batch = firestore.batch();
      
//       for (final doc in snapshot.docs) {
//         batch.delete(doc.reference);
//       }
      
//       await batch.commit();
//       print('Đã xóa ${snapshot.docs.length} bookings');
//     } catch (e) {
//       print('Lỗi khi xóa bookings: $e');
//       rethrow;
//     }
//   }

//   // Method để tạo bookings mẫu cho test
//   static Future<void> createSampleBookings(String userId) async {
//     final firestore = FirebaseFirestore.instance;
//     try {
//       print('Tạo bookings mẫu cho user: $userId');
      
//       final batch = firestore.batch();
//       final now = DateTime.now();
      
//       // Tạo 3 bookings mẫu với các trạng thái khác nhau
//       final sampleBookings = [
//         {
//           'userId': userId,
//           'tourId': 'sample_tour_1',
//           'tourName': 'Tour Đà Lạt 3N2Đ',
//           'userName': 'Test User',
//           'userEmail': 'test@example.com',
//           'userPhone': '0123456789',
//           'dateStart': '15/12/2024',
//           'numPeople': 2,
//           'totalPrice': 3000000,
//           'status': 'pending',
//           'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
//           'notes': 'Booking mẫu 1',
//         },
//         {
//           'userId': userId,
//           'tourId': 'sample_tour_2',
//           'tourName': 'Tour Hạ Long Bay 2N1Đ',
//           'userName': 'Test User',
//           'userEmail': 'test@example.com',
//           'userPhone': '0123456789',
//           'dateStart': '20/12/2024',
//           'numPeople': 4,
//           'totalPrice': 4000000,
//           'status': 'paid',
//           'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 12))),
//           'notes': 'Booking mẫu 2',
//         },
//         {
//           'userId': userId,
//           'tourId': 'sample_tour_3',
//           'tourName': 'Tour Sapa 4N3Đ',
//           'userName': 'Test User',
//           'userEmail': 'test@example.com',
//           'userPhone': '0123456789',
//           'dateStart': '25/12/2024',
//           'numPeople': 3,
//           'totalPrice': 6000000,
//           'status': 'paid',
//           'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
//           'notes': 'Booking mẫu 3',
//         },
//       ];
      
//       for (final booking in sampleBookings) {
//         final docRef = firestore.collection('bookings').doc();
//         batch.set(docRef, booking);
//       }
      
//       await batch.commit();
//       print('Đã tạo ${sampleBookings.length} bookings mẫu');
//     } catch (e) {
//       print('Lỗi khi tạo bookings mẫu: $e');
//       rethrow;
//     }
//   }

//   // Method để kiểm tra và sửa lỗi dữ liệu
//   static Future<void> validateAndFixBookings() async {
//     final firestore = FirebaseFirestore.instance;
//     try {
//       print('Kiểm tra và sửa lỗi dữ liệu bookings...');
      
//       final snapshot = await firestore.collection('bookings').get();
//       final batch = firestore.batch();
//       int fixed = 0;
      
//       for (final doc in snapshot.docs) {
//         final data = doc.data();
//         bool needsUpdate = false;
//         final updates = <String, dynamic>{};
        
//         // Kiểm tra các trường bắt buộc
//         if (data['userId'] == null || data['userId'] == '') {
//           print('Booking ${doc.id} thiếu userId');
//           continue; // Skip vì không thể fix
//         }
        
//         if (data['tourId'] == null || data['tourId'] == '') {
//           updates['tourId'] = 'unknown_tour';
//           needsUpdate = true;
//         }
        
//         if (data['tourName'] == null || data['tourName'] == '') {
//           updates['tourName'] = 'Tên tour không rõ';
//           needsUpdate = true;
//         }
        
//         if (data['userName'] == null || data['userName'] == '') {
//           updates['userName'] = 'Người dùng';
//           needsUpdate = true;
//         }
        
//         if (data['userEmail'] == null) {
//           updates['userEmail'] = '';
//           needsUpdate = true;
//         }
        
//         if (data['userPhone'] == null) {
//           updates['userPhone'] = '';
//           needsUpdate = true;
//         }
        
//         if (data['dateStart'] == null || data['dateStart'] == '') {
//           updates['dateStart'] = '01/01/2025';
//           needsUpdate = true;
//         }
        
//         if (data['numPeople'] == null) {
//           updates['numPeople'] = 1;
//           needsUpdate = true;
//         }
        
//         if (data['totalPrice'] == null) {
//           updates['totalPrice'] = 0;
//           needsUpdate = true;
//         }
        
//         if (data['status'] == null || data['status'] == '') {
//           updates['status'] = 'pending';
//           needsUpdate = true;
//         }
        
//         if (data['createdAt'] == null) {
//           updates['createdAt'] = Timestamp.now();
//           needsUpdate = true;
//         }
        
//         if (needsUpdate) {
//           batch.update(doc.reference, updates);
//           fixed++;
//           print('Fixing booking ${doc.id}: $updates');
//         }
//       }
      
//       if (fixed > 0) {
//         await batch.commit();
//         print('Đã sửa $fixed bookings');
//       } else {
//         print('Tất cả bookings đều hợp lệ');
//       }
      
//     } catch (e) {
//       print('Lỗi khi kiểm tra bookings: $e');
//       rethrow;
//     }
//   }
// }
