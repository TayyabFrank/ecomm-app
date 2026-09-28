import '../models/mock_data.dart';
import 'firestore_service.dart';

/// Seeds the Firestore `products` collection from [MockData].
class ProductSeedService {
  ProductSeedService._();

  /// Uploads all catalog products. Skips docs that already exist unless [force] is true.
  static Future<int> seedProducts({bool force = false}) async {
    var uploaded = 0;
    for (final product in MockData.products) {
      final doc = await FirestoreService.productsRef.doc(product.id).get();
      if (!force && doc.exists) continue;
      await FirestoreService.addProduct(product);
      uploaded++;
    }
    return uploaded;
  }

  static Future<bool> isEmpty() async {
    final snapshot = await FirestoreService.productsRef.limit(1).get();
    return snapshot.docs.isEmpty;
  }
}
