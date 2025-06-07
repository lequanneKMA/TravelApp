// lib/screens/add_place_screen.dart
import 'dart:io'; // Để làm việc với File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:lnmq/models/place_model.dart'; // Đảm bảo đúng 'lnmq'
import 'package:lnmq/services/place_service.dart'; // Đảm bảo đúng 'lnmq'
import 'package:lnmq/services/storage_service.dart'; // <<< THÊM DÒNG NÀY (Đảm bảo đúng 'lnmq')

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final PlaceService _placeService = PlaceService();
  final StorageService _storageService = StorageService(); // <<< KHỞI TẠO STORAGE SERVICE

  // Controllers cho các trường nhập liệu
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _bestTimeToVisitController = TextEditingController();
  final TextEditingController _travelTipsController = TextEditingController();
  final TextEditingController _categoriesController = TextEditingController(); // Tạm thời dùng cho String

  // Trạng thái cho hình ảnh đã chọn
  File? _pickedImageFile; // <<< BIẾN MỚI LƯU FILE ẢNH
  bool _isLoading = false; // Biến trạng thái loading

  // Hàm chọn ảnh từ Gallery hoặc Camera
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _pickedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn ảnh: $e')),
      );
    }
  }

  // Hàm hiển thị hộp thoại chọn nguồn ảnh
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Hàm gửi dữ liệu
  Future<void> _submitPlace() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String? imageUrl;
      if (_pickedImageFile != null) {
        // <<< SỬA DÒNG NÀY >>>
        imageUrl = await _storageService.uploadImage(
          _pickedImageFile!,
          'places', // CHỈ ĐỊNH ĐƯỜNG DẪN LƯU ẢNH TRONG STORAGE LÀ 'places'
        );
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi khi tải ảnh lên.')),
          );
          setState(() {
            _isLoading = false;
          });
          return; // Dừng lại nếu tải ảnh thất bại
        }
      } else {
        // Nếu không có ảnh, có thể sử dụng ảnh placeholder hoặc cảnh báo người dùng
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn một ảnh cho địa điểm.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Chuyển đổi chuỗi categories thành List<String>
      List<String> categories = _categoriesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final newPlace = Place(
        id: '', // Firestore sẽ tự tạo ID
        name: _nameController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        latitude: double.tryParse(_latitudeController.text) ?? 0.0,
        longitude: double.tryParse(_longitudeController.text) ?? 0.0,
        rating: 0.0, // Mặc định là 0, sẽ được tính toán sau này
        reviewCount: 0, // Mặc định là 0
        imageUrls: imageUrl != null ? [imageUrl] : [], // Lưu URL ảnh đã tải lên
        categories: categories,
        bestTimeToVisit: _bestTimeToVisitController.text,
        travelTips: _travelTipsController.text, category: '',
      );

      try {
        await _placeService.addPlace(newPlace);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Địa điểm đã được thêm thành công!')),
        );
        Navigator.of(context).pop(); // Quay lại màn hình trước
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _bestTimeToVisitController.dispose();
    _travelTipsController.dispose();
    _categoriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Địa điểm Mới'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Phần chọn ảnh
                    GestureDetector(
                      onTap: () => _showImageSourceActionSheet(context),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _pickedImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _pickedImageFile!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                                  SizedBox(height: 10),
                                  Text('Chọn ảnh địa điểm', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_nameController, 'Tên Địa điểm', 'Vui lòng nhập tên địa điểm'),
                    _buildTextField(_descriptionController, 'Mô tả', 'Vui lòng nhập mô tả', maxLines: 3),
                    _buildTextField(_locationController, 'Vị trí', 'Vui lòng nhập vị trí'),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(_latitudeController, 'Vĩ độ', 'Vĩ độ (ví dụ: 10.76)',
                                keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _buildTextField(_longitudeController, 'Kinh độ', 'Kinh độ (ví dụ: 106.69)',
                                keyboardType: TextInputType.number)),
                      ],
                    ),
                    _buildTextField(_categoriesController, 'Danh mục (phân cách bởi dấu phẩy)', 'Thiên nhiên, Văn hóa',
                        validator: (value) => null), // Categories có thể trống
                    _buildTextField(_bestTimeToVisitController, 'Thời điểm lý tưởng để ghé thăm', 'Mùa khô, mùa hoa...',
                        validator: (value) => null), // Optional field
                    _buildTextField(_travelTipsController, 'Mẹo du lịch', 'Mang theo mũ, kem chống nắng...',
                        validator: (value) => null, maxLines: 2), // Optional field

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _submitPlace,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Thêm Địa điểm',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập $label';
              }
              return null;
            },
      ),
    );
  }
}