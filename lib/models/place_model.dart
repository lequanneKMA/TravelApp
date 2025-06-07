// lib/models/place_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String name;
  final String description;
  final List<String> imageUrls;
  final String location;
  final double latitude;
  final double longitude;
  final double rating;
  final String category;
  final int reviewCount;
  final List<String> categories;
  final String bestTimeToVisit;
  final String travelTips;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrls,
    required this.location,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.categories = const [],
    this.bestTimeToVisit = '',
    this.travelTips = '',
  });

  factory Place.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Place(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      category: data['category'] ?? 'Khác',
      location: data['location'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: (data['reviewCount'] ?? 0).toInt(),
      categories: List<String>.from(data['categories'] ?? []),
      bestTimeToVisit: data['bestTimeToVisit'] ?? '',
      travelTips: data['travelTips'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrls': imageUrls,
      'location': location,
      'latitude': latitude,
      'category': category,
      'longitude': longitude,
      'rating': rating,
      'reviewCount': reviewCount,
      'categories': categories,
      'bestTimeToVisit': bestTimeToVisit,
      'travelTips': travelTips,
    };
  }

  @override
  String toString() {
    return 'Place(id: $id, name: $name, location: $location, rating: $rating)';
  }
}