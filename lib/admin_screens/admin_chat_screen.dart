import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_chat_detail_screen.dart';

class AdminChatScreen extends StatelessWidget {
  const AdminChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý chat & tư vấn'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tour_chats').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final chatDocs = snapshot.data!.docs;
          if (chatDocs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có người dùng nào chat hoặc tư vấn.'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chat = chatDocs[index];
              final data = chat.data() as Map<String, dynamic>;
              
              // SỬA: Parse chatId để tách riêng theo tour
              // Format: userId_tourId hoặc userId_general
              final chatId = chat.id;
              final parts = chatId.split('_');
              final userId = parts[0];
              final tourIdPart = parts.length > 1 ? parts.sublist(1).join('_') : 'general';

              final tourName = data['tourName'] ?? 'Không rõ tên';
              final tourId = data['tourId'] ?? tourIdPart;
              final userName = data['userName'] ?? 'Người dùng';

              // Kiểm tra nếu là chat tư vấn chung
              final isGeneralChat = tourId == 'general_chat' || tourId == 'general';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isGeneralChat ? Colors.green : Colors.blue,
                    child: Icon(
                      isGeneralChat ? Icons.support_agent : Icons.tour,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGeneralChat ? 'Tư vấn chung' : 'Tour: $tourName',
                        style: TextStyle(
                          color: isGeneralChat ? Colors.green[700] : Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!isGeneralChat)
                        Text(
                          'Chat ID: $chatId',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.chat_bubble,
                    color: isGeneralChat ? Colors.green : Colors.blue,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminChatDetailScreen(
                          userId: userId,
                          userName: userName,
                          tourId: tourId,
                          tourName: tourName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}