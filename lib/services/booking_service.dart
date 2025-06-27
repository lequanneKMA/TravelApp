// lib/services/booking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lnmq/models/booking_model.dart';
import 'package:lnmq/models/user_model.dart';
import 'package:lnmq/services/invoice_service.dart';
import 'package:lnmq/utils/migrate_bookings.dart';
import 'invoice_service.dart'; // Import InvoiceService

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tạo booking mới
  Future<String> createBooking({
    required String tourId,
    required String tourName,
    required String dateStart,
    required int numPeople,
    required int totalPrice,
    String? notes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Chưa login');

    print('DEBUG createBooking - userId: ${user.uid}, tourId: $tourId'); // Debug log

    // Lấy thông tin user từ Firestore - SỬA LẠI
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    AppUser? appUser;
    if (userDoc.exists) {
      appUser = AppUser.fromFirestore(userDoc);
    }

    final booking = Booking(
      id: '', // Sẽ được set sau khi add vào Firestore
      userId: user.uid,
      tourId: tourId,
      tourName: tourName,
      userName: appUser?.displayName ?? user.displayName ?? 'Người dùng',
      userEmail: appUser?.email ?? user.email ?? '',
      userPhone: appUser?.phoneNumber ?? '',
      dateStart: dateStart,
      numPeople: numPeople,
      totalPrice: totalPrice,
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
      notes: notes,
    );

    print('DEBUG createBooking - booking data: ${booking.toFirestore()}'); // Debug log

    final docRef = await _firestore.collection('bookings').add(booking.toFirestore());
    print('DEBUG createBooking - saved with ID: ${docRef.id}'); // Debug log
    return docRef.id;
  }

  // Lấy booking theo ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting booking: $e');
      return null;
    }
  }

  // Lấy tất cả bookings của user hiện tại - SỬA LẠI để tránh lỗi index
  Stream<List<Booking>> getUserBookings() {
    final user = FirebaseAuth.instance.currentUser;
    print('DEBUG getUserBookings: user = ${user?.uid}'); // Debug log
    
    if (user == null) {
      print('DEBUG: No user logged in');
      return Stream.value([]);
    }

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .handleError((error) {
          print('DEBUG: Stream error in getUserBookings: $error');
        })
        .map((snapshot) {
          print('DEBUG: Received ${snapshot.docs.length} booking documents'); // Debug log
          try {
            final bookings = snapshot.docs.map((doc) {
              print('DEBUG: Processing booking doc ${doc.id}'); // Debug log
              return Booking.fromFirestore(doc);
            }).toList();
            // Sort trong code thay vì query để tránh lỗi index
            bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            print('DEBUG: Returning ${bookings.length} bookings'); // Debug log
            return bookings;
          } catch (e) {
            print('DEBUG: Error processing bookings: $e');
            return <Booking>[];
          }
        });
  }

  // Lấy tất cả bookings (cho admin)
  Stream<List<Booking>> getAllBookings() {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  // Lấy bookings theo trạng thái - SỬA LẠI để tránh lỗi index
  Stream<List<Booking>> getBookingsByStatus(BookingStatus status) {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: status.toString().split('.').last)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
          // Sort trong code thay vì query để tránh lỗi index
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  }

  // Cập nhật trạng thái booking
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    String? adminNotes,
    String? paymentMethod,
    String? cancelReason,
  }) async {
    final updateData = <String, dynamic>{
      'status': status.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (adminNotes != null) updateData['adminNotes'] = adminNotes;
    if (paymentMethod != null) updateData['paymentMethod'] = paymentMethod;
    if (cancelReason != null) updateData['cancelReason'] = cancelReason;

    await _firestore.collection('bookings').doc(bookingId).update(updateData);
  }

  // Xác nhận thanh toán
  Future<void> confirmPayment(
    String bookingId,
    String paymentMethod, {
    String? adminNotes,
  }) async {
    await updateBookingStatus(
      bookingId,
      BookingStatus.paid,
      paymentMethod: paymentMethod,
      adminNotes: adminNotes,
    );
  }

  // Hoàn thành booking
  Future<void> completeBooking(String bookingId, {String? adminNotes}) async {
    await updateBookingStatus(
      bookingId,
      BookingStatus.completed,
      adminNotes: adminNotes,
    );
  }

  // Xóa booking (chỉ admin)
  Future<void> deleteBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).delete();
  }

  // Tìm kiếm bookings
  Stream<List<Booking>> searchBookings(String searchTerm) {
    if (searchTerm.isEmpty) return getAllBookings();

    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .where((booking) =>
              booking.userName.toLowerCase().contains(searchTerm.toLowerCase()) ||
              booking.tourName.toLowerCase().contains(searchTerm.toLowerCase()) ||
              booking.userEmail.toLowerCase().contains(searchTerm.toLowerCase()) ||
              booking.userPhone.contains(searchTerm))
          .toList();
      return bookings;
    });
  }

  // Thống kê booking
  Future<Map<String, int>> getBookingStats() async {
    final snapshot = await _firestore.collection('bookings').get();
    final bookings = snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();

    final stats = <String, int>{
      'total': bookings.length,
      'pending': 0,
      'paid': 0,
      'completed': 0,
    };

    for (final booking in bookings) {
      final statusKey = booking.status.toString().split('.').last;
      stats[statusKey] = (stats[statusKey] ?? 0) + 1;
    }

    return stats;
  }

  // Lấy tổng doanh thu
  Future<int> getTotalRevenue() async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('status', whereIn: ['paid', 'completed'])
        .get();

    int total = 0;
    for (final doc in snapshot.docs) {
      final booking = Booking.fromFirestore(doc);
      total += booking.totalPrice;
    }

    return total;
  }

  // Lấy doanh thu theo tháng
  Future<Map<String, int>> getMonthlyRevenue(int year) async {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    final snapshot = await _firestore
        .collection('bookings')
        .where('status', whereIn: ['paid', 'completed'])
        .where('createdAt', isGreaterThanOrEqualTo: startOfYear)
        .where('createdAt', isLessThan: endOfYear)
        .get();

    final monthlyRevenue = <String, int>{};
    for (int month = 1; month <= 12; month++) {
      monthlyRevenue['$month'] = 0;
    }

    for (final doc in snapshot.docs) {
      final booking = Booking.fromFirestore(doc);
      final month = booking.createdAt.month.toString();
      monthlyRevenue[month] = (monthlyRevenue[month] ?? 0) + booking.totalPrice;
    }

    return monthlyRevenue;
  }

  // Debug method để kiểm tra connection
  Future<void> debugCheckBookings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('DEBUG: Current user: ${user?.uid}');
      
      // Kiểm tra collection bookings
      final snapshot = await _firestore.collection('bookings').get();
      print('DEBUG: Total bookings in collection: ${snapshot.docs.length}');
      
      // Kiểm tra bookings của user hiện tại
      final userBookings = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user?.uid ?? '')
          .get();
      print('DEBUG: User bookings count: ${userBookings.docs.length}');
      
      for (var doc in userBookings.docs) {
        print('DEBUG: Booking ${doc.id}: ${doc.data()}');
      }
    } catch (e) {
      print('DEBUG Error: $e');
    }
  }

  // Đồng bộ cập nhật booking và invoice khi xác nhận thanh toán
  Future<void> confirmPaymentWithInvoiceSync(
    String bookingId,
    String paymentMethod, {
    String? adminNotes,
  }) async {
    // Import InvoiceService ở đầu file
    final invoiceService = InvoiceService();
    
    // Cập nhật booking
    await updateBookingStatus(
      bookingId,
      BookingStatus.paid,
      paymentMethod: paymentMethod,
      adminNotes: adminNotes,
    );
    
    // Xử lý invoice
    try {
      final existingInvoice = await invoiceService.getInvoiceByBookingId(bookingId);
      if (existingInvoice != null) {
        // Cập nhật invoice thành paid
        await invoiceService.updateInvoiceStatus(
          existingInvoice.id,
          'paid',
          paidDate: DateTime.now(),
          paymentMethod: paymentMethod,
        );
      } else {
        // Tạo invoice mới với trạng thái paid
        final invoiceId = await invoiceService.createInvoiceFromBooking(bookingId);
        await invoiceService.updateInvoiceStatus(
          invoiceId,
          'paid',
          paidDate: DateTime.now(),
          paymentMethod: paymentMethod,
        );
      }
    } catch (e) {
      print('Error syncing invoice: $e');
    }
  }

}
