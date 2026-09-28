import 'dart:async';

import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/firestore_service.dart';

class ProductProvider extends ChangeNotifier {
  final List<ProductModel> _products = [];
  StreamSubscription<List<ProductModel>>? _subscription;
  String selectedCategory = 'All';
  bool isLoading = false;
  String? error;

  List<ProductModel> get products => List.unmodifiable(_products);

  List<String> get categories {
    final categorySet = <String>{'All'};
    categorySet.addAll(_products.map((item) => item.category));
    return categorySet.toList();
  }

  List<ProductModel> get featuredProducts =>
      _products.where((product) => product.isFeatured).toList();

  List<ProductModel> get filteredProducts {
    if (selectedCategory == 'All') {
      return products;
    }
    return products
        .where((product) => product.category == selectedCategory)
        .toList();
  }

  void selectCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  Future<void> startListening() async {
    await _subscription?.cancel();
    isLoading = true;
    notifyListeners();
    _subscription = FirestoreService.productsStream().listen(
      (items) async {
        _products
          ..clear()
          ..addAll(items);
        isLoading = false;
        error = null;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> addProduct(ProductModel product) async {
    await FirestoreService.addProduct(product);
  }

  Future<void> updateProduct(ProductModel product) async {
    await FirestoreService.updateProduct(product);
  }

  Future<void> deleteProduct(String productId) async {
    await FirestoreService.deleteProduct(productId);
  }
}
