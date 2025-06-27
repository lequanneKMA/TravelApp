// // Thêm vào file utils/migrate_chat_data.dart
// import 'package:cloud_firestore/cloud_firestore.dart';

// Future<void> migrateChatData() async {
//   try {
//     final chatDocs = await FirebaseFirestore.instance
//         .collection('tour_chats')
//         .get();

//     final batch = FirebaseFirestore.instance.batch();
//     int updated = 0;

//     for (final chatDoc in chatDocs.docs) {
//       final data = chatDoc.data();
      
//       // Nếu chưa có lastMessageAt, tạo mặc định
//       if (data['lastMessageAt'] == null) {
//         // Lấy tin nhắn cuối cùng trong chat này
//         final lastMessageQuery = await FirebaseFirestore.instance
//             .collection('tour_chats')
//             .doc(chatDoc.id)
//             .collection('messages')
//             .orderBy('timestamp', descending: true)
//             .limit(1)
//             .get();

//         DateTime lastMessageTime = DateTime.now();
//         String lastMessage = '';

//         if (lastMessageQuery.docs.isNotEmpty) {
//           final lastMsg = lastMessageQuery.docs.first.data();
//           final timestamp = lastMsg['timestamp'] as Timestamp?;
//           lastMessageTime = timestamp?.toDate() ?? DateTime.now();
//           lastMessage = lastMsg['message'] ?? '';
//         }

//         // Update chat document
//         batch.update(chatDoc.reference, {
//           'lastMessageAt': Timestamp.fromDate(lastMessageTime),
//           'lastMessage': lastMessage,
//           'unreadCount': 0, // Set về 0 cho data cũ
//         });
        
//         updated++;
//       }
//     }

//     if (updated > 0) {
//       await batch.commit();
//       print('✅ Đã migrate $updated chat rooms');
//     } else {
//       print('✅ Tất cả chat rooms đã có dữ liệu đầy đủ');
//     }

//   } catch (e) {
//     print('❌ Lỗi migrate chat data: $e');
//   }
// }