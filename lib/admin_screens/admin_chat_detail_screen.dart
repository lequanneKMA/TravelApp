import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String tourId;
  final String tourName;
  const AdminChatDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.tourId,
    required this.tourName,
  });

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final admin = FirebaseAuth.instance.currentUser;
  double? _amount;
  final TextEditingController _amountController = TextEditingController();
  final String bankId = 'TPB'; // Mã ngân hàng (TPBank)
  final String account = '03901436666'; // Số tài khoản
  final String accountName = 'LE NGUYEN MINH QUAN'; // Tên chủ tài khoản (IN HOA, KHÔNG DẤU)

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || admin == null) return;
    await FirebaseFirestore.instance
        .collection('tour_chats')
        .doc(widget.userId)
        .collection('messages')
        .add({
      'senderId': admin!.uid,
      'senderName': admin!.displayName ?? 'Admin',
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isAdmin': true,
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat với ${widget.userName}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // Hiển thị thông tin tour
          Container(
            width: double.infinity,
            color: Colors.blue[50],
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thông tin tour:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Tên tour: ${widget.tourName}'),
                Text('Mã tour: ${widget.tourId}'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tour_chats')
                  .doc(widget.userId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isAdmin = data['isAdmin'] == true;
                    return Align(
                      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['senderName'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isAdmin ? Colors.blue : Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(data['message'] ?? ''),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // THÊM PHẦN NÀY TRƯỚC Divider(height: 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tạo mã QR chuyển khoản:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số tiền (VNĐ)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _amount = double.tryParse(_amountController.text);
                          // Gửi tin nhắn số tiền cho user
                          if (_amount != null && _amount! > 0 && admin != null) {
                            final qrUrl =
                                'https://img.vietqr.io/image/$bankId-$account-print.png?amount=${_amount!.toInt()}&addInfo=${Uri.encodeComponent('Thanh toan tour ${widget.tourName}')}&accountName=${Uri.encodeComponent(accountName)}';

                            FirebaseFirestore.instance
                                .collection('tour_chats')
                                .doc(widget.userId)
                                .collection('messages')
                                .add({
                              'senderId': admin!.uid,
                              'senderName': admin!.displayName ?? 'Admin',
                              'message': 'Vui lòng thanh toán số tiền: ${NumberFormat('#,###', 'vi_VN').format(_amount!.toInt())} VNĐ cho tour "${widget.tourName}". Quét mã QR bên dưới để chuyển khoản.',
                              'qrUrl': qrUrl, 
                              'timestamp': FieldValue.serverTimestamp(),
                              'isAdmin': true,
                            });
                          }
                        });
                      },
                      child: const Text('Gửi QR'),
                    ),
                  ],
                ),
                if (_amount != null && _amount! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: Image.network(
                        'https://img.vietqr.io/image/$bankId-$account-print.png?amount=${_amount!.toInt()}&addInfo=${Uri.encodeComponent('Thanh toan tour ${widget.tourName}')}&accountName=${Uri.encodeComponent(accountName)}',
                        width: 200,
                        height: 200,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}