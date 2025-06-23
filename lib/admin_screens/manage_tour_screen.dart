import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManageTourScreen extends StatefulWidget {
  const ManageTourScreen({super.key});

  @override
  State<ManageTourScreen> createState() => _ManageTourScreenState();
}

class _ManageTourScreenState extends State<ManageTourScreen> {
  void _showTourDialog({DocumentSnapshot? tour}) {
    final TextEditingController nameController = TextEditingController(text: tour?['name'] ?? '');
    final TextEditingController descController = TextEditingController(text: tour?['description'] ?? '');
    final TextEditingController priceController = TextEditingController(text: tour?['price']?.toString() ?? '');
    final TextEditingController itineraryController = TextEditingController(
      text: tour != null && tour['itinerary'] != null ? (tour['itinerary'] as List).join('\n') : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tour == null ? 'Thêm tour mới' : 'Sửa tour'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên tour'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Giá 1 người'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: itineraryController,
                decoration: const InputDecoration(labelText: 'Lịch trình (mỗi dòng 1 mục)'),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              final price = int.tryParse(priceController.text.trim()) ?? 0;
              final itinerary = itineraryController.text.trim().isEmpty
                  ? []
                  : itineraryController.text.trim().split('\n');
              if (name.isEmpty) return;
              final data = {
                'name': name,
                'description': desc,
                'price': price,
                'itinerary': itinerary,
              };
              if (tour == null) {
                await FirebaseFirestore.instance.collection('tours').add(data);
              } else {
                await tour.reference.update(data);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Tour')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tours').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final tours = snapshot.data!.docs;
          if (tours.isEmpty) {
            return const Center(child: Text('Chưa có tour nào.'));
          }
          return ListView.builder(
            itemCount: tours.length,
            itemBuilder: (context, index) {
              final tour = tours[index];              return ListTile(
                title: Text(tour['name'] ?? ''),
                subtitle: Text('Giá: ${tour['price'] != null ? NumberFormat('#,###', 'vi_VN').format(tour['price']) : ''} VNĐ\n${tour['description'] ?? ''}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showTourDialog(tour: tour),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await tour.reference.delete();
                      },
                    ),
                  ],
                ),
                onTap: () {
                  // Xem chi tiết hoặc sửa
                  _showTourDialog(tour: tour);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTourDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Thêm tour mới',
      ),
    );
  }
}