import 'product_model.dart';

/// Source catalog used only to seed Firestore — the app reads products from the database.
class MockData {
  static const List<String> categories = [
    'All',
    'Sneakers',
    'Jackets',
    'Watches',
    'Bags',
    'Accessories',
  ];

  static const List<ProductModel> products = [
    ProductModel(
      id: 'p1',
      name: 'Air Motion Sneakers',
      price: 129.99,
      description:
          'A lightweight sneaker with premium cushioning and breathable knit upper for all-day comfort.',
      imageURL: 'https://picsum.photos/id/21/800/1000',
      rating: 4.8,
      category: 'Sneakers',
      isFeatured: true,
    ),
    ProductModel(
      id: 'p2',
      name: 'Minimal Leather Jacket',
      price: 249.00,
      description:
          'Tailored silhouette jacket crafted from soft leather with a clean matte finish.',
      imageURL: 'https://picsum.photos/id/1062/800/1000',
      rating: 4.7,
      category: 'Jackets',
      isFeatured: true,
    ),
    ProductModel(
      id: 'p3',
      name: 'Urban Chronograph Watch',
      price: 179.50,
      description:
          'Modern chronograph with stainless steel case, sapphire-coated crystal, and interchangeable strap.',
      imageURL: 'https://picsum.photos/id/175/800/1000',
      rating: 4.6,
      category: 'Watches',
      isFeatured: true,
    ),
    ProductModel(
      id: 'p4',
      name: 'Canvas Daypack',
      price: 89.99,
      description:
          'Spacious everyday backpack with smart compartments and water-resistant canvas exterior.',
      imageURL: 'https://picsum.photos/id/180/800/1000',
      rating: 4.5,
      category: 'Bags',
      isFeatured: false,
    ),
    ProductModel(
      id: 'p5',
      name: 'Performance Running Tee',
      price: 39.99,
      description:
          'Sweat-wicking and ultra-soft running t-shirt designed for comfort during intense workouts.',
      imageURL: 'https://picsum.photos/id/29/800/1000',
      rating: 4.4,
      category: 'Accessories',
      isFeatured: false,
    ),
    ProductModel(
      id: 'p6',
      name: 'Classic Suede Loafers',
      price: 149.00,
      description:
          'Refined suede loafers with cushioned insoles and timeless profile suitable for smart casual outfits.',
      imageURL: 'https://picsum.photos/id/26/800/1000',
      rating: 4.7,
      category: 'Sneakers',
      isFeatured: false,
    ),
  ];
}
