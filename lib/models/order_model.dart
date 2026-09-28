import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/encryption_service.dart';

class OrderItemModel {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String imageURL;

  OrderItemModel({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageURL': imageURL,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 1,
      imageURL: map['imageURL'] as String? ?? '',
    );
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final List<OrderItemModel> items;
  final double totalAmount;
  final String status;
  final DateTime timestamp;
  final String shippingAddress;
  final String paymentMethod;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.timestamp,
    required this.shippingAddress,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmailEncrypted': EncryptionService.encryptText(userEmail),
      'userNameEncrypted': EncryptionService.encryptText(userName),
      'items': items.map((x) => x.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'shippingAddressEncrypted': EncryptionService.encryptText(shippingAddress),
      'paymentMethod': paymentMethod,
    };
  }

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    final timestampField = map['timestamp'];
    DateTime parsedDate;
    if (timestampField is Timestamp) {
      parsedDate = timestampField.toDate();
    } else if (timestampField is String) {
      parsedDate = DateTime.parse(timestampField);
    } else {
      parsedDate = DateTime.now();
    }

    return OrderModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      userEmail: EncryptionService.decryptText(
          map['userEmailEncrypted'] as String? ?? map['userEmail'] as String? ?? ''),
      userName: EncryptionService.decryptText(
          map['userNameEncrypted'] as String? ?? map['userName'] as String? ?? ''),
      items: (map['items'] as List<dynamic>?)
              ?.map((x) => OrderItemModel.fromMap(x as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'Pending',
      timestamp: parsedDate,
      shippingAddress: EncryptionService.decryptText(
          map['shippingAddressEncrypted'] as String? ?? map['shippingAddress'] as String? ?? ''),
      paymentMethod: map['paymentMethod'] as String? ?? '',
    );
  }
}
