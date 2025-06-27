// lib/admin_screens/manage_invoice_screen.dart
import 'package:flutter/material.dart';
import 'package:lnmq/models/invoice_model.dart';
import 'package:lnmq/services/invoice_service.dart';
import 'package:lnmq/admin_screens/invoice_detail_screen.dart';

class ManageInvoiceScreen extends StatefulWidget {
  const ManageInvoiceScreen({super.key});

  @override
  State<ManageInvoiceScreen> createState() => _ManageInvoiceScreenState();
}

class _ManageInvoiceScreenState extends State<ManageInvoiceScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String? _filterStatus;

  final List<String> _statusOptions = ['unpaid', 'paid'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
    });
  }

  Stream<List<Invoice>> _getFilteredInvoices() {
    if (_filterStatus != null) {
      return _invoiceService.getInvoicesByStatus(_filterStatus!);
    } else if (_searchTerm.isNotEmpty) {
      return _invoiceService.searchInvoices(_searchTerm);
    } else {
      return _invoiceService.getAllInvoices();
    }
  }

  void _showInvoiceDetail(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(invoice: invoice),
      ),
    );
  }

  String _getStatusName(String status) {
    switch (status) {
      case 'unpaid':
        return 'Chưa thanh toán';
      case 'paid':
        return 'Đã thanh toán';
      default:
        return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () async {
              final stats = await _invoiceService.getInvoiceStats();
              final totalRevenue = await _invoiceService.getTotalRevenueFromInvoices();
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Thống kê hóa đơn'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tổng số hóa đơn: ${stats['total']}'),
                        Text('Chưa thanh toán: ${stats['unpaid']}'),
                        Text('Đã thanh toán: ${stats['paid']}'),
                        const Divider(),
                        Text('Tổng doanh thu: ${totalRevenue.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ'),
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
                    labelText: 'Tìm kiếm (tên, email, số hóa đơn...)',
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
                      ..._statusOptions.map((status) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_getStatusName(status)),
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
          // Danh sách hóa đơn
          Expanded(
            child: StreamBuilder<List<Invoice>>(
              stream: _getFilteredInvoices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Không có hóa đơn nào'));
                }

                final invoices = snapshot.data!;
                return ListView.builder(
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(int.parse('0xFF${invoice.statusColor.substring(1)}')),
                          child: Text(
                            invoice.statusName.substring(0, 1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(invoice.invoiceNumber),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Khách hàng: ${invoice.userName}'),
                            Text('Ngày xuất: ${invoice.formattedIssueDate}'),
                            Text('Hạn thanh toán: ${invoice.formattedDueDate}'),
                            Text('Tổng tiền: ${invoice.formattedTotalAmount} VNĐ'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(int.parse('0xFF${invoice.statusColor.substring(1)}')),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                invoice.statusName,
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
                            if (invoice.status == 'unpaid')
                              const PopupMenuItem(
                                value: 'mark_paid',
                                child: Text('Đánh dấu đã thanh toán'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Xóa'),
                            ),
                          ],
                          onSelected: (value) async {
                            switch (value) {
                              case 'view':
                                _showInvoiceDetail(invoice);
                                break;
                              case 'mark_paid':
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Xác nhận thanh toán'),
                                    content: Text('Xác nhận hóa đơn ${invoice.invoiceNumber} đã được thanh toán?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Hủy'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Xác nhận'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirmed == true) {
                                  try {
                                    await _invoiceService.updateInvoiceStatus(
                                      invoice.id,
                                      'paid',
                                      paidDate: DateTime.now(),
                                      paymentMethod: 'Chuyển khoản',
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đã xác nhận thanh toán!')),
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
                              case 'delete':
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Xác nhận xóa'),
                                    content: const Text('Bạn có chắc chắn muốn xóa hóa đơn này?'),
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
                                    await _invoiceService.deleteInvoice(invoice.id);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đã xóa hóa đơn!')),
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
                        onTap: () => _showInvoiceDetail(invoice),
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
