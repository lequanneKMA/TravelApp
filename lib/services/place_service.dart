// lib/services/place_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lnmq/models/place_model.dart'; // Import Place model

class PlaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _placesCollection = 'places';

  // 1. Thêm một địa điểm mới vào Firestore
  Future<void> addPlace(Place place) async {
    try {
      // Sử dụng add để Firestore tự tạo ID tài liệu
      await _firestore.collection(_placesCollection).add(place.toFirestore());
      print('Địa điểm "${place.name}" đã được thêm thành công!');
    } catch (e) {
      print('Lỗi khi thêm địa điểm: $e');
      rethrow; // Ném lại lỗi để xử lý ở UI
    }
  }

  // 2. Lấy tất cả các địa điểm từ Firestore (Real-time updates)
  Stream<List<Place>> getPlaces() {
    return _firestore.collection(_placesCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();
    });
  }

  // 3. Lấy một địa điểm theo ID
  Future<Place?> getPlaceById(String placeId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_placesCollection).doc(placeId).get();
      if (doc.exists) {
        return Place.fromFirestore(doc);
      } else {
        print('Không tìm thấy địa điểm với ID: $placeId');
        return null;
      }
    } catch (e) {
      print('Lỗi khi lấy địa điểm theo ID: $e');
      rethrow;
    }
  }

  // 4. Cập nhật thông tin của một địa điểm
  Future<void> updatePlace(Place place) async {
    try {
      await _firestore.collection(_placesCollection).doc(place.id).update(place.toFirestore());
      print('Địa điểm "${place.name}" đã được cập nhật thành công!');
    } catch (e) {
      print('Lỗi khi cập nhật địa điểm: $e');
      rethrow;
    }
  }

  // 5. Xóa một địa điểm
  Future<void> deletePlace(String placeId) async {
    try {
      await _firestore.collection(_placesCollection).doc(placeId).delete();
      print('Địa điểm với ID: $placeId đã được xóa thành công!');
    } catch (e) {
      print('Lỗi khi xóa địa điểm: $e');
      rethrow;
    }
  }


// 6. Lấy nhiều địa điểm theo danh sách ID
  Future<List<Place>> getPlacesByIds(List<String> placeIds) async {
    if (placeIds.isEmpty) {
      return [];
    }
    try {
      // Firestore cho phép truy vấn 'whereIn' tối đa 10 ID
      // Nếu có nhiều hơn 10 ID, bạn sẽ cần chia nhỏ truy vấn hoặc xử lý khác
      // Với số lượng nhỏ, whereIn là đủ
      final QuerySnapshot snapshot = await _firestore
          .collection(_placesCollection)
          .where(FieldPath.documentId, whereIn: placeIds)
          .get();

      return snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();
    } catch (e) {
      print('Lỗi khi lấy địa điểm theo danh sách ID: $e');
      rethrow;
    }
  }
  // 7. Tìm kiếm địa điểm theo tên
  Stream<List<Place>> searchPlaces(String query) {
    if (query.isEmpty) {
      // Nếu query rỗng, trả về tất cả địa điểm (hoặc rỗng tùy ý)
      return getPlaces(); // Hoặc Stream.value([]) nếu bạn muốn rỗng
    }
    final String lowerCaseQuery = query.toLowerCase();

    return _firestore
        .collection(_placesCollection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '${query}\uf8ff')
        .orderBy('name') // Cần orderBy trên trường bạn đang filter
        .snapshots()
        .map((snapshot) {
      final List<Place> allPlaces = snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();
      return allPlaces.where((place) =>
          place.name.toLowerCase().contains(lowerCaseQuery) || // Tìm trong tên
          place.description.toLowerCase().contains(lowerCaseQuery) // Tìm trong mô tả
      ).toList();
    });
  }

}
  // Phương thức ví dụ để thêm dữ liệu mẫu (chỉ dùng cho mục đích test ban đầu)
  // NHỚ XÓA HOẶC COMMENT DÒNG GỌI HÀM NÀY TRONG main.dart SAU KHI CHẠY LẦN ĐẦU
  // Future<void> addSamplePlaces() async {
  //   QuerySnapshot existingDocs = await _firestore.collection(_placesCollection).limit(1).get();
  //   if (existingDocs.docs.isEmpty) {
  //     print('Thêm dữ liệu mẫu vào Firestore...');
  //     final List<Place> samplePlaces = [
  //       Place(
  //         id: '',
  //         name: 'Vịnh Hạ Long',
  //         description: 'Di sản Thiên nhiên Thế giới với hàng nghìn đảo đá vôi và hang động độc đáo.',
  //         imageUrls: [
  //           'https://media.istockphoto.com/id/1324391696/vi/anh/v%E1%BB%8Bnh-h%E1%BA%A1-long-v%E1%BB%8Bnh-v%E1%BB%9Bi-nh%E1%BB%AFng-ng%E1%BB%8Dn-n%C3%BAi-%C4%91%E1%BB%8Ba-l%C3%BD-l%E1%BB%9Bn-c%E1%BB%A7a-vi%E1%BB%87t-nam-v%E1%BB%9Bi-thuy%E1%BB%81n-du-l%E1%BB%8Bch-truy%E1%BB%81n-th%E1%BB%91ng.jpg?s=612x612&w=0&k=20&c=L_Y95w37j8f9VwKq6gQkL9yFv2X3P78V4Q22b_u29p0=',
  //           'https://media.istockphoto.com/id/1315668388/vi/anh/v%E1%BB%8Bnh-h%E1%BA%A1-long-%E1%BB%9F-vi%E1%BB%87t-nam.jpg?s=612x612&w=0&k=20&c=6P4qF_a6hF-fQk861tXjJ_XoB9kM0hQ_d4-wUj5l_u0=',
  //           'https://media.istockphoto.com/id/1218525091/vi/anh/v%E1%BB%8Bnh-h%E1%BA%A1-long-quang-ninh-vi%E1%BB%87t-nam.jpg?s=612x612&w=0&k=20&c=yD3Xz0uJ0m_8gT2w8N4rF9Xg3rX_4h-x8Q04d2jZ-X0='
  //         ],
  //         location: 'Quảng Ninh',
  //         latitude: 20.9100,
  //         longitude: 107.1800,
  //         rating: 4.8,
  //         reviewCount: 1500,
  //         categories: ['Thiên nhiên', 'Di sản Thế giới', 'Biển'],
  //         bestTimeToVisit: 'Tháng 4 - Tháng 10',
  //         travelTips: 'Nên đi thuyền tham quan vịnh và ghé thăm các hang động nổi tiếng.',
  //       ),
  //       Place(
  //         id: '',
  //         name: 'Phố cổ Hội An',
  //         description: 'Thành phố cổ kính với những ngôi nhà mái ngói rêu phong, đèn lồng lung linh và ẩm thực đặc sắc.',
  //         imageUrls: [
  //           'https://media.istockphoto.com/id/1400325159/vi/anh/ph%E1%BB%91-c%E1%BB%95-h%E1%BB%99i-an-v%C3%A0o-l%C3%BAc-ho%C3%A0ng-h%C3%B4n.jpg?s=612x612&w=0&k=20&c=kO_fJ8P4QW0-l-9u9J_aWzJ7L80rGj7wV4gC4r2gK9Y=',
  //           'https://media.istockphoto.com/id/528073534/vi/anh/nh%E1%BB%AFng-chi%E1%BA%BFc-%C4%91%C3%A8n-l%E1%BB%93ng-%C4%91%E1%BA%B7c-tr%C6%B0ng-c%E1%BB%A7a-h%E1%BB%99i-an-vi%E1%BB%87t-nam.jpg?s=612x612&w=0&k=20&c=tM4S4_0bM-mC42zK1zI8T6jX7L1qH50d1V0r8Q8r7j0=',
  //           'https://media.istockphoto.com/id/1179679198/vi/anh/ch%E1%BB%A3-%C4%91%C3%AAm-h%E1%BB%99i-an.jpg?s=612x612&w=0&k=20&c=Wp-W_fM5zQhYyL0N-X1yF-t7a9m-g3M5h-j8L-u02d0='
  //         ],
  //         location: 'Quảng Nam',
  //         latitude: 15.8794,
  //         longitude: 108.3360,
  //         rating: 4.7,
  //         reviewCount: 2000,
  //         categories: ['Lịch sử', 'Văn hóa', 'Ẩm thực'],
  //         bestTimeToVisit: 'Tháng 2 - Tháng 4 (mùa khô)',
  //         travelTips: 'Thuê xe đạp khám phá phố cổ, trải nghiệm ẩm thực đường phố và tham gia lớp học làm đèn lồng.',
  //       ),
  //       Place(
  //         id: '',
  //         name: 'Đà Lạt',
  //         description: 'Thành phố ngàn hoa với khí hậu mát mẻ quanh năm, kiến trúc Pháp cổ kính và nhiều cảnh quan thiên nhiên lãng mạn.',
  //         imageUrls: [
  //           'https://media.istockphoto.com/id/1057473722/vi/anh/th%C3%A0nh-ph%E1%BB%91-%C4%91%C3%A0-l%E1%BA%A1t-vi%E1%BB%87t-nam-v%C3%A0o-l%C3%BAc-ho%C3%A0ng-h%C3%B4n.jpg?s=612x612&w=0&k=20&c=tK1J4F_2n3hR2e6N_3Y8t_7aP2X8y0H_s5m6p_2z0b8=',
  //           'https://media.istockphoto.com/id/1388836592/vi/anh/nh%C3%A0-th%E1%BB%9D-con-g%C3%A0-nh%C3%A0-th%E1%BB%9D-ch%C3%ADnh-t%C3%B2a-%C4%91%C3%A0-l%E1%BA%A1t.jpg?s=612x612&w=0&k=20&c=R4F6_q2s6y0t4W2e6Y8v_5M8H_3z0B8Y0F7G0h0S0p8=',
  //           'https://media.istockphoto.com/id/1324391696/vi/anh/v%E1%BB%8Bnh-h%E1%BA%A1-long-v%E1%BB%8Bnh-v%E1%BB%9Bi-nh%E1%BB%AFng-ng%E1%BB%8Dn-n%C3%BAi-%C4%91%E1%BB%8Ba-l%C3%BD-l%E1%BB%9Bn-c%E1%BB%A7a-vi%E1%BB%87t-nam-v%C3%B4ng-%C4%91%E1%BB%8Ba-l%C3%BD-l%E1%BB%9Bn-c%E1%BB%A7a-vi%E1%BB%87t-nam-v%E1%BB%9Bi-thuy%E1%BB%81n-du-l%E1%BB%8Bch-truy%E1%BB%81n-th%E1%BB%91ng.jpg?s=612x612&w=0&k=20&c=L_Y95w37j8f9VwKq6gQkL9yFv2X3P78V4Q22b_u29p0='
  //         ],
  //         location: 'Lâm Đồng',
  //         latitude: 11.9400,
  //         longitude: 108.4400,
  //         rating: 4.6,
  //         reviewCount: 1800,
  //         categories: ['Nghỉ dưỡng', 'Thiên nhiên', 'Kiến trúc Pháp'],
  //         bestTimeToVisit: 'Tháng 11 - Tháng 3 (mùa khô, lạnh)',
  //         travelTips: 'Tham quan các địa điểm nổi tiếng như Thung lũng Tình Yêu, Hồ Xuân Hương, Nhà thờ Con Gà.',
  //       ),
  //     ];

  //     for (var place in samplePlaces) {
  //       await addPlace(place);
  //     }
  //     print('Đã thêm tất cả dữ liệu mẫu.');
  //   } else {
  //     print('Dữ liệu mẫu đã tồn tại trong Firestore. Bỏ qua việc thêm.');
  //   }
  // }
