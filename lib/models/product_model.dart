import '../services/encryption_service.dart';

class ProductModel {
  final String id;
  final String name;
  final double price;
  final String description;
  final String imageURL;
  final double rating;
  final String category;
  final bool isFeatured;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageURL,
    required this.rating,
    this.category = 'General',
    this.isFeatured = false,
  });

  Map<String, dynamic> toMapEncrypted() {
    return {
      'name': name,
      'price': price,
      'imageURL': imageURL,
      'rating': rating,
      'category': category,
      'isFeatured': isFeatured,
      'descriptionEncrypted': EncryptionService.encryptText(description),
    };
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageURL: map['imageURL'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'General',
      isFeatured: map['isFeatured'] as bool? ?? false,
      description: EncryptionService.decryptText(
          map['descriptionEncrypted'] as String? ?? ''),
    );
  }
}
