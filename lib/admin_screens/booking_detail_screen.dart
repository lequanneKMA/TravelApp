// lib/admin_screens/booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:lnmq/models/booking_model.dart';
import 'package:lnmq/models/invoice_model.dart';
import 'package:lnmq/services/invoice_service.dart';
import 'package:lnmq/admin_screens/invoice_detail_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final InvoiceService _invoiceService = InvoiceService();

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(int.parse('0xFF${widget.booking.statusColor.substring(1)}')),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        widget.booking.statusName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đặt tour'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt),
            onPressed: () async {
              // Kiểm tra xem đã có hóa đơn chưa
              final invoice = await _invoiceService.getInvoiceByBookingId(widget.booking.id);
              if (invoice != null) {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InvoiceDetailScreen(invoice: invoice),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chưa có hóa đơn cho booking này')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin tour
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Thông tin tour',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStatusChip(),
                      ],
                    ),
                    const Divider(),
                    _buildInfoRow('Tên tour:', widget.booking.tourName),
                    _buildInfoRow('Mã tour:', widget.booking.tourId),
                    _buildInfoRow('Ngày đi:', widget.booking.dateStart),
                    _buildInfoRow('Số người:', widget.booking.numPeople.toString()),
                    _buildInfoRow('Tổng tiền:', '${widget.booking.formattedTotalPrice} VNĐ'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Thông tin khách hàng
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin khách hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow('Họ tên:', widget.booking.userName),
                    _buildInfoRow('Email:', widget.booking.userEmail),
                    _buildInfoRow('Số điện thoại:', widget.booking.userPhone.isNotEmpty 
                        ? widget.booking.userPhone 
                        : 'Chưa có'),
                    _buildInfoRow('Mã khách hàng:', widget.booking.userId),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Thông tin đặt tour
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin đặt tour',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow('Ngày đặt:', widget.booking.formattedCreatedAt),
                    if (widget.booking.updatedAt != null)
                      _buildInfoRow('Cập nhật lần cuối:', widget.booking.formattedUpdatedAt),
                    if (widget.booking.paymentMethod != null)
                      _buildInfoRow('Phương thức thanh toán:', widget.booking.paymentMethod!),
                    if (widget.booking.notes != null && widget.booking.notes!.isNotEmpty)
                      _buildInfoRow('Ghi chú khách hàng:', widget.booking.notes!),
                    if (widget.booking.adminNotes != null && widget.booking.adminNotes!.isNotEmpty)
                      _buildInfoRow('Ghi chú admin:', widget.booking.adminNotes!),
                    if (widget.booking.cancelReason != null && widget.booking.cancelReason!.isNotEmpty)
                      _buildInfoRow('Lý do hủy:', widget.booking.cancelReason!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Hóa đơn
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hóa đơn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    FutureBuilder<Invoice?>(
                      future: _invoiceService.getInvoiceByBookingId(widget.booking.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (snapshot.hasData && snapshot.data != null) {
                          final invoice = snapshot.data!;
                          return Column(
                            children: [
                              _buildInfoRow('Số hóa đơn:', invoice.invoiceNumber),
                              _buildInfoRow('Ngày xuất:', invoice.formattedIssueDate),
                              _buildInfoRow('Hạn thanh toán:', invoice.formattedDueDate),
                              _buildInfoRow('Trạng thái:', invoice.statusName),
                              if (invoice.paidDate != null)
                                _buildInfoRow('Ngày thanh toán:', invoice.formattedPaidDate),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InvoiceDetailScreen(invoice: invoice),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.receipt_long),
                                label: const Text('Xem chi tiết hóa đơn'),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              const Text('Chưa có hóa đơn cho booking này'),
                              const SizedBox(height: 16),
                              if (widget.booking.status == BookingStatus.paid ||
                                  widget.booking.status == BookingStatus.confirmed)
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await _invoiceService.createInvoiceFromBooking(widget.booking.id);
                                      setState(() {}); // Refresh the UI
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Đã tạo hóa đơn thành công!')),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Lỗi tạo hóa đơn: $e')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tạo hóa đơn'),
                                ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
