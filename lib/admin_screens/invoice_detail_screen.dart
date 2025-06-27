// lib/admin_screens/invoice_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:lnmq/models/invoice_model.dart';
import 'package:lnmq/services/invoice_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
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
        color: Color(int.parse('0xFF${widget.invoice.statusColor.substring(1)}')),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        widget.invoice.statusName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Text('Xác nhận hóa đơn ${widget.invoice.invoiceNumber} đã được thanh toán?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _invoiceService.updateInvoiceStatus(
                  widget.invoice.id,
                  'paid',
                  paidDate: DateTime.now(),
                  paymentMethod: 'Chuyển khoản',
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {}); // Refresh the UI
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
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hóa đơn'),
        actions: [
          if (widget.invoice.status == 'unpaid')
            IconButton(
              icon: const Icon(Icons.payment),
              onPressed: _showPaymentDialog,
              tooltip: 'Xác nhận thanh toán',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header hóa đơn
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
                          'HÓA ĐƠN',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStatusChip(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Số hóa đơn:', widget.invoice.invoiceNumber),
                    _buildInfoRow('Ngày xuất:', widget.invoice.formattedIssueDate),
                    _buildInfoRow('Hạn thanh toán:', widget.invoice.formattedDueDate),
                    if (widget.invoice.paidDate != null)
                      _buildInfoRow('Ngày thanh toán:', widget.invoice.formattedPaidDate),
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
                    _buildInfoRow('Họ tên:', widget.invoice.userName),
                    _buildInfoRow('Email:', widget.invoice.userEmail),
                    _buildInfoRow('Số điện thoại:', widget.invoice.userPhone.isNotEmpty 
                        ? widget.invoice.userPhone 
                        : 'Chưa có'),
                    _buildInfoRow('Địa chỉ:', widget.invoice.userAddress.isNotEmpty 
                        ? widget.invoice.userAddress 
                        : 'Chưa có'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Chi tiết hóa đơn
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chi tiết hóa đơn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    
                    // Header bảng
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('SL', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                          Expanded(flex: 2, child: Text('Thành tiền', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                        ],
                      ),
                    ),
                    
                    // Items
                    ...widget.invoice.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(item.description)),
                          Expanded(flex: 1, child: Text('${item.quantity}', textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('${item.formattedUnitPrice} VNĐ', textAlign: TextAlign.right)),
                          Expanded(flex: 2, child: Text('${item.formattedTotalPrice} VNĐ', textAlign: TextAlign.right)),
                        ],
                      ),
                    )),
                    
                    const Divider(),
                    
                    // Tổng kết
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tạm tính:'),
                            Text('${widget.invoice.formattedSubtotal} VNĐ'),
                          ],
                        ),
                        if (widget.invoice.discount > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Giảm giá:'),
                              Text('-${widget.invoice.formattedDiscount} VNĐ'),
                            ],
                          ),
                        if (widget.invoice.tax > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Thuế:'),
                              Text('${widget.invoice.formattedTax} VNĐ'),
                            ],
                          ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng cộng:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.invoice.formattedTotalAmount} VNĐ',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Thông tin thanh toán
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin thanh toán',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    if (widget.invoice.paymentMethod != null)
                      _buildInfoRow('Phương thức:', widget.invoice.paymentMethod!),
                    if (widget.invoice.bankInfo != null)
                      _buildInfoRow('Thông tin ngân hàng:', widget.invoice.bankInfo!),
                    if (widget.invoice.notes != null && widget.invoice.notes!.isNotEmpty)
                      _buildInfoRow('Ghi chú:', widget.invoice.notes!),
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
