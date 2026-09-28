import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/firestore_service.dart';

import '../services/encryption_service.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'name': product.name,
      'price': product.price,
      'category': product.category,
      'imageURL': product.imageURL,
      'descriptionEncrypted': EncryptionService.encryptText(product.description),
      'rating': product.rating,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: ProductModel(
        id: map['productId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        category: map['category'] as String? ?? '',
        imageURL: map['imageURL'] as String? ?? '',
        description: EncryptionService.decryptText(
            map['descriptionEncrypted'] as String? ?? map['description'] as String? ?? ''),
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      ),
      quantity: map['quantity'] as int? ?? 1,
    );
  }
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? _userId;

  List<CartItem> get items => _items.values.toList(growable: false);

  int get itemCount =>
      _items.values.fold<int>(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.values.fold<double>(
        0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );

  bool hasProduct(String productId) => _items.containsKey(productId);

  int quantityFor(String productId) => _items[productId]?.quantity ?? 0;

  /// Called on login — loads the user's persisted cart from Firestore.
  Future<void> loadCartForUser(String userId) async {
    _userId = userId;
    _items.clear();
    try {
      final rawItems = await FirestoreService.fetchCartRaw(userId);
      for (final map in rawItems) {
        final item = CartItem.fromMap(map);
        _items[item.product.id] = item;
      }
    } catch (_) {
      // If cart doesn't exist yet that's fine — start empty
    }
    notifyListeners();
  }

  /// Called on logout — clear in-memory cart and userId reference.
  void clearForLogout() {
    _items.clear();
    _userId = null;
    notifyListeners();
  }

  void addToCart(ProductModel product) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += 1;
    } else {
      _items[product.id] = CartItem(product: product, quantity: 1);
    }
    notifyListeners();
    _saveCartToFirestore();
  }

  void increaseQuantity(String productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity += 1;
      notifyListeners();
      _saveCartToFirestore();
    }
  }

  void decreaseQuantity(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }

    final item = _items[productId]!;
    if (item.quantity > 1) {
      item.quantity -= 1;
    } else {
      _items.remove(productId);
    }
    notifyListeners();
    _saveCartToFirestore();
  }

  void removeFromCart(String productId) {
    removeProductCompletely(productId);
  }

  void removeProductCompletely(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    _items.remove(productId);
    notifyListeners();
    _saveCartToFirestore();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    _saveCartToFirestore();
  }

  /// Persists the current cart state to Firestore for the logged-in user.
  Future<void> _saveCartToFirestore() async {
    if (_userId == null) return;
    try {
      await FirestoreService.saveCart(
        _userId!,
        _items.values.toList(),
      );
    } catch (_) {
      // Silently fail — next mutation will retry
    }
  }
}
