// lib/screens/favorite_places_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lnmq/models/place_model.dart';
import 'package:lnmq/models/user_model.dart'; // Sử dụng AppUser
import 'package:lnmq/services/auth_service.dart';
import 'package:lnmq/services/place_service.dart';
import 'package:lnmq/services/user_service.dart';
import 'package:lnmq/widgets/place_card.dart';

class FavoritePlacesScreen extends StatefulWidget {
  const FavoritePlacesScreen({super.key});

  @override
  State<FavoritePlacesScreen> createState() => _FavoritePlacesScreenState();
}

class _FavoritePlacesScreenState extends State<FavoritePlacesScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final PlaceService _placeService = PlaceService(); // Để lấy chi tiết địa điểm

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(
        child: Text('Bạn cần đăng nhập để xem các địa điểm yêu thích.'),
      );
    }

    return StreamBuilder<AppUser?>(
      stream: _userService.getUserData(_currentUser!.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userSnapshot.hasError) {
          return Center(child: Text('Lỗi tải dữ liệu người dùng: ${userSnapshot.error}'));
        }
        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return const Center(child: Text('Không tìm thấy thông tin người dùng.'));
        }

        final AppUser appUser = userSnapshot.data!;
        final List<String> favoritePlaceIds = appUser.favoritePlaceIds;

        if (favoritePlaceIds.isEmpty) {
          return const Center(child: Text('Bạn chưa có địa điểm yêu thích nào.'));
        }

        return FutureBuilder<List<Place>>( // Sử dụng FutureBuilder để tải chi tiết từng địa điểm
          future: _placeService.getPlacesByIds(favoritePlaceIds), // Hàm mới cần thêm vào PlaceService
          builder: (context, placesSnapshot) {
            if (placesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (placesSnapshot.hasError) {
              return Center(child: Text('Lỗi tải địa điểm yêu thích: ${placesSnapshot.error}'));
            }
            if (!placesSnapshot.hasData || placesSnapshot.data!.isEmpty) {
              return const Center(child: Text('Không tìm thấy địa điểm yêu thích nào.'));
            }

            final List<Place> favoritePlaces = placesSnapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: favoritePlaces.length,
              itemBuilder: (context, index) {
                final place = favoritePlaces[index];
                return PlaceCard(place: place);
              },
            );
          },
        );
      },
    );
  }
}