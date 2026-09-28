import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ecom/firebase_options.dart';
import 'package:flutter_ecom/models/mock_data.dart';
import 'package:flutter_ecom/services/product_seed_service.dart';

/// One-off script: uploads catalog products to Firestore.
///
/// Run: flutter run -t tool/seed_products.dart -d chrome
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final empty = await ProductSeedService.isEmpty();
  final uploaded = await ProductSeedService.seedProducts(force: true);

  debugPrint(
    'Firestore seed complete: $uploaded/${MockData.products.length} products '
    'written (collection was ${empty ? "empty" : "not empty"}).',
  );
}
