import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lnmq/models/place_model.dart';
import 'package:lnmq/services/place_service.dart';
import 'package:lnmq/services/storage_service.dart';

class ManagePlaceScreen extends StatefulWidget {
  const ManagePlaceScreen({super.key});

  @override
  State<ManagePlaceScreen> createState() => _ManagePlaceScreenState();
}

class _ManagePlaceScreenState extends State<ManagePlaceScreen> {
  final PlaceService _placeService = PlaceService();
  final StorageService _storageService = StorageService();

  void _showPlaceDialog({DocumentSnapshot? place}) {
    final TextEditingController nameController = TextEditingController(text: place?['name'] ?? '');
    final TextEditingController descController = TextEditingController(text: place?['description'] ?? '');
    final TextEditingController locationController = TextEditingController(text: place?['location'] ?? '');
    final TextEditingController bestTimeController = TextEditingController(text: place?['bestTimeToVisit'] ?? '');
    final TextEditingController minPriceController = TextEditingController(
      text: place?['minPrice'] != null ? place!['minPrice'].toString() : '',
    );
    final TextEditingController maxPriceController = TextEditingController(
      text: place?['maxPrice'] != null ? place!['maxPrice'].toString() : '',
    );
    File? pickedImageFile;
    String? imageUrl = place != null && place['imageUrls'] != null && (place['imageUrls'] as List).isNotEmpty
        ? (place['imageUrls'] as List).first
        : null;

    // Sử dụng danh mục tập trung từ place_model.dart
    List<String> selectedCategories = place != null && place['categories'] != null
        ? List<String>.from(place['categories'])
        : [];

    Future<void> _pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        pickedImageFile = File(pickedFile.path);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chọn ảnh mới.')));
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(place == null ? 'Thêm địa điểm mới' : 'Sửa địa điểm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: pickedImageFile != null
                        ? Image.file(pickedImageFile!, fit: BoxFit.cover)
                        : (imageUrl != null
                            ? Image.network(imageUrl, fit: BoxFit.cover)
                            : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên địa điểm'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  maxLines: 2,
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Vị trí'),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                    child: Text('Danh mục:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: allCategories.map((cat) {
                    final isSelected = selectedCategories.contains(cat);
                    return FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedCategories.add(cat);
                          } else {
                            selectedCategories.remove(cat);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                TextField(
                  controller: bestTimeController,
                  decoration: const InputDecoration(labelText: 'Thời điểm lý tưởng'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Giá từ (VNĐ)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Đến (VNĐ)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                String? uploadImageUrl = imageUrl;
                if (pickedImageFile != null) {
                  uploadImageUrl = await _storageService.uploadImage(pickedImageFile!, 'places');
                }

                final placeData = {
                  'name': nameController.text,
                  'description': descController.text,
                  'location': locationController.text,
                  'categories': selectedCategories,
                  'bestTimeToVisit': bestTimeController.text,
                  'minPrice': int.tryParse(minPriceController.text),
                  'maxPrice': int.tryParse(maxPriceController.text),
                  'imageUrls': uploadImageUrl != null ? [uploadImageUrl] : [],
                };

                if (place == null) {
                  await FirebaseFirestore.instance.collection('places').add(placeData);
                } else {
                  await FirebaseFirestore.instance.collection('places').doc(place.id).update(placeData);
                }
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
              },
              child: Text(place == null ? 'Lưu' : 'Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePlace(String docId) async {
    await FirebaseFirestore.instance.collection('places').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý địa điểm')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('places').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Chưa có địa điểm nào.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final imageUrl = data['imageUrls'] != null && (data['imageUrls'] as List).isNotEmpty
                  ? (data['imageUrls'] as List).first
                  : null;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  leading: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(imageUrl, width: 56, height: 56, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.landscape, size: 40, color: Colors.grey),
                  title: Text(data['name'] ?? ''),
                  subtitle: Text(data['description'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () => _showPlaceDialog(place: docs[index]),
                        tooltip: 'Sửa',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deletePlace(docs[index].id),
                        tooltip: 'Xóa',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlaceDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Thêm địa điểm mới',
      ),
    );
  }
}