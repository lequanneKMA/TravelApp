// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lnmq/services/auth_service.dart' as auth_service;
import 'package:lnmq/screens/auth_screen.dart';
import 'package:lnmq/screens/add_place_screen.dart';
import 'package:lnmq/services/place_service.dart'; // <<< THÊM DÒNG NÀY
import 'package:lnmq/models/place_model.dart'; // <<< THÊM DÒNG NÀY
import 'package:lnmq/widgets/place_card.dart'; // <<< THÊM DÒNG NÀY ĐỂ SỬ DỤNG PlaceCard
import 'package:lnmq/screens/favorite_places_screen.dart';
import 'package:lnmq/screens/profile_screen.dart';
import 'package:lnmq/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final auth_service.AuthService _authService = auth_service.AuthService();
  final PlaceService _placeService = PlaceService(); // <<< KHỞI TẠO PLACE SERVICE
  int _selectedIndex = 0;

  // Nội dung cho tab Trang chủ
  Widget _homeTabContent() {
    return StreamBuilder<List<Place>>(
      stream: _placeService.getPlaces(), // Lắng nghe stream các địa điểm
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Chưa có địa điểm nào được thêm.'));
        }

        final places = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: places.length,
          itemBuilder: (context, index) {
            final place = places[index];
            return PlaceCard(place: place); // Sử dụng PlaceCard để hiển thị địa điểm
          },
        );
      },
    );
  }

  // Danh sách các màn hình tương ứng với các tab (CẬP NHẬT LẠI)
  late final List<Widget> _widgetOptions = <Widget>[
    _homeTabContent(), // Gọi hàm để lấy nội dung của tab Trang chủ
    const FavoritePlacesScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = _authService.getCurrentUser();
    String? userEmail = currentUser?.email;
    String? displayName = currentUser?.displayName ?? userEmail?.split('@')[0] ?? 'Khách';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chào mừng, ${displayName}!',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Khám phá những điều tuyệt vời của Việt Nam',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
            IconButton(
            icon: const Icon(Icons.search, color: Colors.black54),
            onPressed: () {
              // CHUYỂN HƯỚNG ĐẾN MÀN HÌNH TÌM KIẾM
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          // Giữ nguyên các IconButton khác nếu có
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black54),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng thông báo chưa có!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await _authService.signOut();
              // Navigator.of(context).pushAndRemoveUntil(
              //   MaterialPageRoute(builder: (context) => const AuthScreen()),
              //   (Route<dynamic> route) => false,
              // );
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex), // Giữ nguyên cách hiển thị tab
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Yêu thích',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddPlaceScreen(),
            ),
          ).then((_) {
            // Sau khi AddPlaceScreen đóng, làm mới dữ liệu nếu cần
            // (StreamBuilder sẽ tự động làm mới, nhưng có thể thêm setState nếu có logic phức tạp hơn)
            setState(() {});
          });
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Thêm địa điểm mới',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}