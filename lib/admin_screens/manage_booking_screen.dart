// lib/admin_screens/manage_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:lnmq/models/booking_model.dart';
import 'package:lnmq/services/booking_service.dart';
import 'package:lnmq/services/invoice_service.dart';
import 'package:lnmq/admin_screens/booking_detail_screen.dart';

class ManageBookingScreen extends StatefulWidget {
  const ManageBookingScreen({super.key});

  @override
  State<ManageBookingScreen> createState() => _ManageBookingScreenState();
}

class _ManageBookingScreenState extends State<ManageBookingScreen> {
  final BookingService _bookingService = BookingService();
  final InvoiceService _invoiceService = InvoiceService();
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  BookingStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
    });
  }

  Stream<List<Booking>> _getFilteredBookings() {
    if (_filterStatus != null) {
      return _bookingService.getBookingsByStatus(_filterStatus!);
    } else if (_searchTerm.isNotEmpty) {
      return _bookingService.searchBookings(_searchTerm);
    } else {
      return _bookingService.getAllBookings();
    }
  }

  void _showBookingDetail(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailScreen(booking: booking),
      ),
    );
  }

  void _showStatusUpdateDialog(Booking booking) {
    BookingStatus selectedStatus = booking.status;
    final TextEditingController notesController = TextEditingController();
    final TextEditingController paymentMethodController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật trạng thái - ${booking.tourName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<BookingStatus>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                items: BookingStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(booking.copyWith(status: status).statusName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedStatus = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              if (selectedStatus == BookingStatus.paid || selectedStatus == BookingStatus.confirmed)
                TextField(
                  controller: paymentMethodController,
                  decoration: const InputDecoration(
                    labelText: 'Phương thức thanh toán',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú của admin',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _bookingService.updateBookingStatus(
                  booking.id,
                  selectedStatus,
                  adminNotes: notesController.text.trim().isEmpty 
                      ? null 
                      : notesController.text.trim(),
                  paymentMethod: paymentMethodController.text.trim().isEmpty 
                      ? null 
                      : paymentMethodController.text.trim(),
                );

                // Tạo hóa đơn nếu trạng thái chuyển thành paid
                if (selectedStatus == BookingStatus.paid) {
                  try {
                    await _invoiceService.createInvoiceFromBooking(booking.id);
                  } catch (e) {
                    print('Error creating invoice: $e');
                  }
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật trạng thái thành công!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đặt tour'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () async {
              final stats = await _bookingService.getBookingStats();
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Thống kê đặt tour'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tổng số booking: ${stats['total']}'),
                        Text('Chờ xử lý: ${stats['pending']}'),
                        Text('Đã thanh toán: ${stats['paid']}'),
                        Text('Đã xác nhận: ${stats['confirmed']}'),
                        Text('Đã hủy: ${stats['canceled']}'),
                        Text('Đã hoàn thành: ${stats['completed']}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm và filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Tìm kiếm (tên, email, tour...)',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: _filterStatus == null,
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...BookingStatus.values.map((status) {
                        final statusName = Booking(
                          id: '',
                          userId: '',
                          tourId: '',
                          tourName: '',
                          userName: '',
                          userEmail: '',
                          userPhone: '',
                          dateStart: '',
                          numPeople: 1,
                          totalPrice: 0,
                          status: status,
                          createdAt: DateTime.now(),
                        ).statusName;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(statusName),
                            selected: _filterStatus == status,
                            onSelected: (selected) {
                              setState(() {
                                _filterStatus = selected ? status : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Danh sách bookings
          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: _getFilteredBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Không có booking nào'));
                }

                final bookings = snapshot.data!;
                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(int.parse('0xFF${booking.statusColor.substring(1)}')),
                          child: Text(
                            booking.statusName.substring(0, 1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(booking.tourName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Khách hàng: ${booking.userName}'),
                            Text('Ngày đi: ${booking.dateStart}'),
                            Text('Số người: ${booking.numPeople}'),
                            Text('Tổng tiền: ${booking.formattedTotalPrice} VNĐ'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(int.parse('0xFF${booking.statusColor.substring(1)}')),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                booking.statusName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('Xem chi tiết'),
                            ),
                            const PopupMenuItem(
                              value: 'update',
                              child: Text('Cập nhật trạng thái'),
                            ),
                            if (booking.status == BookingStatus.pending)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Xóa'),
                              ),
                          ],
                          onSelected: (value) async {
                            switch (value) {
                              case 'view':
                                _showBookingDetail(booking);
                                break;
                              case 'update':
                                _showStatusUpdateDialog(booking);
                                break;
                              case 'delete':
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Xác nhận xóa'),
                                    content: const Text('Bạn có chắc chắn muốn xóa booking này?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Hủy'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  try {
                                    await _bookingService.deleteBooking(booking.id);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đã xóa booking thành công!')),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Lỗi: $e')),
                                      );
                                    }
                                  }
                                }
                                break;
                            }
                          },
                        ),
                        onTap: () => _showBookingDetail(booking),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
