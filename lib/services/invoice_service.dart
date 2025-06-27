// lib/services/invoice_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lnmq/models/invoice_model.dart';
import 'package:lnmq/services/booking_service.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BookingService _bookingService = BookingService();

  // Tạo hóa đơn từ booking
  Future<String> createInvoiceFromBooking(String bookingId) async {
    final booking = await _bookingService.getBookingById(bookingId);
    if (booking == null) throw Exception('Không tìm thấy booking');

    // Tạo các item cho hóa đơn
    final items = [
      InvoiceItem(
        description: booking.tourName,
        quantity: booking.numPeople,
        unitPrice: booking.totalPrice ~/ booking.numPeople,
        totalPrice: booking.totalPrice,
      ),
    ];

    // Tạo hóa đơn
    final invoice = Invoice(
      id: '', // Sẽ được set sau khi add vào Firestore
      bookingId: bookingId,
      userId: booking.userId,
      userName: booking.userName,
      userEmail: booking.userEmail,
      userPhone: booking.userPhone,
      userAddress: '', // Có thể lấy từ user profile nếu có
      invoiceNumber: Invoice.generateInvoiceNumber(),
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 7)), // 7 ngày để thanh toán
      items: items,
      subtotal: booking.totalPrice,
      discount: 0,
      tax: 0,
      totalAmount: booking.totalPrice,
      status: 'unpaid',
      notes: 'Hóa đơn thanh toán tour du lịch',
    );

    final docRef = await _firestore.collection('invoices').add(invoice.toFirestore());
    return docRef.id;
  }

  // Lấy hóa đơn theo ID
  Future<Invoice?> getInvoiceById(String invoiceId) async {
    try {
      final doc = await _firestore.collection('invoices').doc(invoiceId).get();
      if (doc.exists) {
        return Invoice.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting invoice: $e');
      return null;
    }
  }

  // Lấy hóa đơn theo booking ID
  Future<Invoice?> getInvoiceByBookingId(String bookingId) async {
    try {
      final querySnapshot = await _firestore
          .collection('invoices')
          .where('bookingId', isEqualTo: bookingId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Invoice.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting invoice by booking ID: $e');
      return null;
    }
  }

  // Lấy tất cả hóa đơn của user (BỎ orderBy để tránh lỗi index)
  Stream<List<Invoice>> getUserInvoices(String userId) {
    return _firestore
        .collection('invoices')
        .where('userId', isEqualTo: userId)
        // BỎ .orderBy('issueDate', descending: true)
        .snapshots()
        .map((snapshot) {
      final invoices = snapshot.docs
          .map((doc) => Invoice.fromFirestore(doc))
          .toList();
      
      // Sort trong code
      invoices.sort((a, b) => b.issueDate.compareTo(a.issueDate));
      return invoices;
    });
  }

  // Lấy tất cả hóa đơn (cho admin) - GIỮ NGUYÊN vì chỉ có orderBy đơn
  Stream<List<Invoice>> getAllInvoices() {
    return _firestore
        .collection('invoices')
        .orderBy('issueDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList());
  }

  // Lấy hóa đơn theo trạng thái (BỎ orderBy để tránh lỗi index)
  Stream<List<Invoice>> getInvoicesByStatus(String status) {
    return _firestore
        .collection('invoices')
        .where('status', isEqualTo: status)
        // BỎ .orderBy('issueDate', descending: true)
        .snapshots()
        .map((snapshot) {
      final invoices = snapshot.docs
          .map((doc) => Invoice.fromFirestore(doc))
          .toList();
      
      // Sort trong code thay vì Firestore
      invoices.sort((a, b) => b.issueDate.compareTo(a.issueDate));
      return invoices;
    });
  }

  // Cập nhật trạng thái hóa đơn
  Future<void> updateInvoiceStatus(
    String invoiceId,
    String status, {
    DateTime? paidDate,
    String? paymentMethod,
    String? notes,
  }) async {
    final Map<String, dynamic> updateData = {
      'status': status,
    };

    if (paidDate != null) {
      updateData['paidDate'] = Timestamp.fromDate(paidDate);
    }
    if (paymentMethod != null) {
      updateData['paymentMethod'] = paymentMethod;
    }
    if (notes != null) {
      updateData['notes'] = notes;
    }

    await _firestore.collection('invoices').doc(invoiceId).update(updateData);
  }

  // Xóa hóa đơn (chỉ admin)
  Future<void> deleteInvoice(String invoiceId) async {
    await _firestore.collection('invoices').doc(invoiceId).delete();
  }

  // Cập nhật thông tin khách hàng trong hóa đơn
  Future<void> updateCustomerInfo(
    String invoiceId, {
    String? userName,
    String? userEmail,
    String? userPhone,
    String? userAddress,
  }) async {
    final updateData = <String, dynamic>{};

    if (userName != null) updateData['userName'] = userName;
    if (userEmail != null) updateData['userEmail'] = userEmail;
    if (userPhone != null) updateData['userPhone'] = userPhone;
    if (userAddress != null) updateData['userAddress'] = userAddress;

    if (updateData.isNotEmpty) {
      await _firestore.collection('invoices').doc(invoiceId).update(updateData);
    }
  }

  // Tìm kiếm hóa đơn (BỎ orderBy để tránh lỗi index)
  Stream<List<Invoice>> searchInvoices(String searchTerm) {
    if (searchTerm.isEmpty) return getAllInvoices();

    return _firestore
        .collection('invoices')
        // BỎ .orderBy('issueDate', descending: true)
        .snapshots()
        .map((snapshot) {
      final invoices = snapshot.docs
          .map((doc) => Invoice.fromFirestore(doc))
          .where((invoice) =>
              invoice.userName.toLowerCase().contains(searchTerm.toLowerCase()) ||
              invoice.invoiceNumber.toLowerCase().contains(searchTerm.toLowerCase()) ||
              invoice.userEmail.toLowerCase().contains(searchTerm.toLowerCase()) ||
              invoice.userPhone.contains(searchTerm))
          .toList();
      
      // Sort trong code
      invoices.sort((a, b) => b.issueDate.compareTo(a.issueDate));
      return invoices;
    });
  }

  // Thống kê hóa đơn
  Future<Map<String, int>> getInvoiceStats() async {
    final snapshot = await _firestore.collection('invoices').get();
    final invoices = snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();

    final stats = <String, int>{
      'total': invoices.length,
      'unpaid': 0,
      'paid': 0,
    };

    for (final invoice in invoices) {
      stats[invoice.status] = (stats[invoice.status] ?? 0) + 1;
    }

    return stats;
  }

  // Lấy tổng doanh thu từ hóa đơn đã thanh toán
  Future<int> getTotalRevenueFromInvoices() async {
    final snapshot = await _firestore
        .collection('invoices')
        .where('status', isEqualTo: 'paid')
        .get();

    int total = 0;
    for (final doc in snapshot.docs) {
      final invoice = Invoice.fromFirestore(doc);
      total += invoice.totalAmount;
    }

    return total;
  }

  // Lấy doanh thu theo tháng từ hóa đơn
  Future<Map<String, int>> getMonthlyRevenueFromInvoices(int year) async {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    final snapshot = await _firestore
        .collection('invoices')
        .where('status', isEqualTo: 'paid')
        .where('paidDate', isGreaterThanOrEqualTo: startOfYear)
        .where('paidDate', isLessThan: endOfYear)
        .get();

    final monthlyRevenue = <String, int>{};
    for (int month = 1; month <= 12; month++) {
      monthlyRevenue['$month'] = 0;
    }

    for (final doc in snapshot.docs) {
      final invoice = Invoice.fromFirestore(doc);
      if (invoice.paidDate != null) {
        final month = invoice.paidDate!.month.toString();
        monthlyRevenue[month] = (monthlyRevenue[month] ?? 0) + invoice.totalAmount;
      }
    }

    return monthlyRevenue;
  }

  // Tạo thông tin ngân hàng cho chuyển khoản
  String generateBankInfo({
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    String? swiftCode,
  }) {
    String bankInfo = 'Ngân hàng: $bankName\n';
    bankInfo += 'Số tài khoản: $accountNumber\n';
    bankInfo += 'Chủ tài khoản: $accountHolder';
    if (swiftCode != null) {
      bankInfo += '\nMã SWIFT: $swiftCode';
    }
    return bankInfo;
  }
}
