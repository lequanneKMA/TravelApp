import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_chat_detail_screen.dart';

class AdminChatScreen extends StatelessWidget {
  const AdminChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý chat với người dùng')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tour_chats').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final chatDocs = snapshot.data!.docs;
          if (chatDocs.isEmpty) {
            return const Center(child: Text('Chưa có người dùng nào chat.'));
          }
          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chat = chatDocs[index];
              final data = chat.data() as Map<String, dynamic>;
              final userId = chat.id;

              final tourName = data['tourName'] ?? 'Không rõ tên';
              final tourId = data['tourId'] ?? '';
              final userName = data['userName'] ?? 'Người dùng';

              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(userName),
                subtitle: Text('Tour: $tourName'),
                trailing: const Icon(Icons.chat),
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
              );
            },
          );
        },
      ),
    );
  }
}