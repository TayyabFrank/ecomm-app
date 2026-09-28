import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import 'encryption_service.dart';
import 'log_service.dart';

class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String adminEmail = 'admin@admin.com';
  static const String adminPassword = 'admin123';

  static CollectionReference get usersRef => _firestore.collection('users');
  static CollectionReference get productsRef =>
      _firestore.collection('products');
  static CollectionReference get ordersRef => _firestore.collection('orders');

  static Future<void> saveUser(AppUser user) async {
    // Ensure only the reserved admin email can have the 'admin' role.
    final normalizedEmail = user.email.toLowerCase();
    final enforcedRole =
        (user.role == 'admin' && normalizedEmail != adminEmail.toLowerCase())
            ? 'user'
            : user.role;

    await usersRef.doc(user.uid).set({
      'email': user.email,
      'fullNameEncrypted': EncryptionService.encryptText(user.fullName),
      'role': enforcedRole,
    });
    LogService.info('FirestoreService', 'Saved user record for ${user.uid}');
  }

  static Future<AppUser> fetchUser(String uid) async {
    final snapshot = await usersRef.doc(uid).get();
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('User record not found');
    }
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      fullName: EncryptionService.decryptText(
          data['fullNameEncrypted'] as String? ?? ''),
      role: data['role'] as String? ?? 'user',
    );
  }

  static Stream<List<ProductModel>> productsStream() {
    return productsRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  static Future<void> addProduct(ProductModel product) async {
    final data = product.toMapEncrypted();
    await productsRef.doc(product.id).set(data);
    LogService.info('FirestoreService', 'Added product: ${product.name} (${product.id})');
  }

  static Future<void> updateProduct(ProductModel product) async {
    final data = product.toMapEncrypted();
    await productsRef.doc(product.id).update(data);
    LogService.info('FirestoreService', 'Updated product: ${product.name} (${product.id})');
  }

  static Future<void> deleteProduct(String productId) async {
    await productsRef.doc(productId).delete();
    LogService.info('FirestoreService', 'Deleted product: $productId');
  }

  // --- Orders Methods ---

  static Future<void> placeOrder(OrderModel order) async {
    await ordersRef.doc(order.id).set(order.toMap());
    LogService.info('FirestoreService', 'Placed order: ${order.id} for user ${order.userId}');
  }

  static Stream<List<OrderModel>> userOrdersStream(String userId) {
    return ordersRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return orders;
    });
  }

  static Stream<List<OrderModel>> allOrdersStream() {
    return ordersRef.snapshots().map((snapshot) {
      final orders = snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return orders;
    });
  }

  static Future<void> updateOrderStatus(
      String orderId, String newStatus) async {
    await ordersRef.doc(orderId).update({'status': newStatus});
    LogService.info('FirestoreService', 'Updated order $orderId status to: $newStatus');
  }

  // --- Cart Persistence Methods ---

  /// Saves the user's cart items to Firestore under users/{uid}/cart.
  static Future<void> saveCart(String userId, List<dynamic> cartItems) async {
    final cartData = cartItems.map((item) => item.toMap()).toList();
    await usersRef.doc(userId).collection('cart').doc('items').set({
      'cartItems': cartData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    LogService.info('FirestoreService', 'Saved cart for user $userId with ${cartItems.length} items');
  }

  /// Fetches the user's persisted cart from Firestore.
  /// Returns a list of maps that CartItem.fromMap can parse.
  static Future<List<Map<String, dynamic>>> fetchCartRaw(String userId) async {
    final doc =
        await usersRef.doc(userId).collection('cart').doc('items').get();
    if (!doc.exists) return [];
    final data = doc.data();
    if (data == null || data['cartItems'] == null) return [];
    return List<Map<String, dynamic>>.from(data['cartItems'] as List);
  }

  /// Updates only the user's profile image (base64 string) in Firestore.
  static Future<void> updateUserProfileImage(
      String uid, String base64Image) async {
    await usersRef.doc(uid).update({'profileImage': base64Image});
    LogService.info(
        'FirestoreService', 'Updated profile image for user $uid');
  }
}
