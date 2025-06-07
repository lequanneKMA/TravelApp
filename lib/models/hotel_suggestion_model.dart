// lib/models/hotel_suggestion_model.dart
class HotelSuggestion {
  final String googlePlaceId; // ID của địa điểm trên Google Places
  final String name;
  final String address;
  final double? rating;
  final String? photoReference; // Dùng để lấy URL ảnh từ Google Places
  final String? phoneNumber;
  final String? website;

  HotelSuggestion({
    required this.googlePlaceId,
    required this.name,
    required this.address,
    this.rating,
    this.photoReference,
    this.phoneNumber,
    this.website,
  });

  // Factory constructor để parse từ JSON response của Google Places API
  factory HotelSuggestion.fromJson(Map<String, dynamic> json) {
    return HotelSuggestion(
      googlePlaceId: json['place_id'],
      name: json['name'],
      address: json['vicinity'] ?? json['formatted_address'] ?? 'Địa chỉ không xác định',
      rating: (json['rating'] as num?)?.toDouble(),
      // Lấy photo_reference của ảnh đầu tiên nếu có
      photoReference: json['photos'] != null && json['photos'].isNotEmpty
          ? json['photos'][0]['photo_reference']
          : null,
      // Google Places API không trực tiếp trả về phone_number hoặc website trong Nearby Search,
      // cần gọi Place Details API để lấy. Chúng ta sẽ để trống hoặc thêm sau.
      phoneNumber: null,
      website: null,
    );
  }
}