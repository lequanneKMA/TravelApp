// lib/services/google_places_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lnmq/models/hotel_suggestion_model.dart';

class GooglePlacesService {
  // <<< THAY THẾ 'YOUR_GOOGLE_PLACES_API_KEY' BẰNG API KEY CỦA BẠN >>>
  // NẾU LÀ DỰ ÁN THỰC TẾ, HÃY DÙNG CÁC CÁCH BẢO MẬT API KEY HƠN (ví dụ: environment variables)
  static const String _apiKey = 'AIzaSyAJ4fSfKRsRrfN8kRDKqgWVqC7Z_yozZps'; 

  // Hàm tìm kiếm khách sạn gần một tọa độ cụ thể
  Future<List<HotelSuggestion>> searchNearbyHotels(double latitude, double longitude) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=5000&type=lodging&key=$_apiKey'; // radius=5000m (5km)

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          List<HotelSuggestion> hotels = [];
          for (var item in data['results']) {
            hotels.add(HotelSuggestion.fromJson(item));
          }
          return hotels;
        } else {
          print('Google Places API Error: ${data['status']} - ${data['error_message']}');
          return [];
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error searching nearby hotels: $e');
      return [];
    }
  }

  // Hàm lấy URL ảnh từ photo_reference
  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=$maxWidth&photoreference=$photoReference&key=$_apiKey';
  }

  // Hàm tạo URL tìm kiếm trên Google Maps/Booking/Agoda
  // Chúng ta sẽ dùng Google Maps search by place ID để đơn giản và chính xác
  String getGoogleMapsSearchUrl(String placeId, String hotelName) {
    // Tìm kiếm trên Google Maps bằng Place ID sẽ chính xác hơn
    return 'https://www.google.com/maps/search/?api=1&query=$hotelName&query_place_id=$placeId';
    // Hoặc bạn có thể dùng link tìm kiếm chung chung nếu không muốn dùng Place ID:
    // return 'https://www.google.com/search?q=${Uri.encodeComponent(hotelName + ' ' + address)}';
  }

  String getBookingComSearchUrl(String hotelName) {
    return 'https://www.booking.com/searchresults.html?ss=${Uri.encodeComponent(hotelName)}';
  }

  String getAgodaSearchUrl(String hotelName) {
    return 'https://www.agoda.com/search?asq=${Uri.encodeComponent(hotelName)}';
  }
}