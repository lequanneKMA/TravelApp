// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:lnmq/models/user_model.dart';
import 'package:lnmq/services/auth_service.dart';
import 'package:lnmq/services/user_service.dart';
import 'package:lnmq/services/storage_service.dart';
import 'package:lnmq/models/review_model.dart';
import 'package:lnmq/services/review_service.dart';



class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();

  late TextEditingController _displayNameController;
  File? _pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      _userService.getUserData(currentUser.uid).listen((appUser) {
        if (appUser != null) {
          if (_displayNameController.text.isEmpty || _displayNameController.text != (appUser.displayName ?? currentUser.displayName)) {
             _displayNameController.text = appUser.displayName ?? currentUser.displayName ?? '';
          }
        }
      });
      _displayNameController.text = currentUser.displayName ?? '';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    String? newPhotoUrl;
    try {
      if (_pickedImage != null) {
        newPhotoUrl = await _storageService.uploadImage(
          _pickedImage!,
          'profile_pictures/${_authService.getCurrentUser()!.uid}',
        );
      }

      await _authService.updateUserProfile(
        displayName: _displayNameController.text.trim(),
        photoUrl: newPhotoUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
      );
    } catch (e) {
      print('Lỗi khi cập nhật hồ sơ: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật hồ sơ: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = _authService.getCurrentUser();

    if (currentUser == null) {
      return const Center(child: Text('Bạn cần đăng nhập để xem hồ sơ.'));
    }

    return StreamBuilder<AppUser?>(
      stream: _userService.getUserData(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải dữ liệu hồ sơ: ${snapshot.error}'));
        }

        AppUser? appUser = snapshot.data;
        String currentDisplayName = currentUser.displayName ?? appUser?.displayName ?? 'Chưa đặt tên';
        String? currentPhotoUrl = currentUser.photoURL ?? appUser?.photoUrl;

        if (!_isLoading && _displayNameController.text.isEmpty || _displayNameController.text != currentDisplayName) {
          _displayNameController.text = currentDisplayName;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hồ sơ cá nhân', style: TextStyle(color: Colors.black87)),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blueGrey[100],
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider<Object>
                          : (currentPhotoUrl != null ? NetworkImage(currentPhotoUrl) : null),
                      child: _pickedImage == null && currentPhotoUrl == null
                          ? const Icon(Icons.person, size: 60, color: Colors.blueGrey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                        onPressed: _pickImage,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Tên hiển thị',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Cập nhật hồ sơ', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // existing methods...

  Future<void> updateUserProfile({String? displayName, String? photoUrl}) async {
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
      await user.reload();
    }
  }
}