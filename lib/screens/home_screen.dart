import '../widgets/app_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import 'admin_panel_screen.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';
import 'profile_screen.dart';
import 'notification_center_screen.dart';
import '../providers/notification_provider.dart';
import '../widgets/in_app_notification_banner.dart';
import '../services/ad_service.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _featuredController =
      PageController(viewportFraction: 0.88);
  int _featuredIndex = 0;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      provider.startListening();

      // Listen for foreground in-app notifications
      final notificationProvider = context.read<NotificationProvider>();
      _notificationSubscription = notificationProvider.inAppNotifications.listen((notification) {
        if (mounted) {
          InAppNotificationBanner.show(context, notification);
        }
      });
    });
  }

  @override
  void dispose() {
    _featuredController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discover',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Premium curated essentials',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Notification Bell Icon with Badge
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1F22).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Consumer<NotificationProvider>(
              builder: (context, notifProvider, _) {
                return _NotificationBadge(
                  count: notifProvider.unreadCount,
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: Color(0xFF1E1F22)),
                    onPressed: () {
                      Navigator.pushNamed(context, NotificationCenterScreen.routeName);
                    },
                  ),
                );
              },
            ),
          ),
          if (authProvider.isAdmin)
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1F22).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.admin_panel_settings_outlined,
                    color: Color(0xFF1E1F22)),
                onPressed: () {
                  Navigator.pushNamed(context, AdminPanelScreen.routeName);
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF1E1F22).withValues(alpha: 0.08),
          selectedIndex: 0,
          onDestinationSelected: (value) {
            if (value == 1) {
              Navigator.pushNamed(context, CartScreen.routeName);
            } else if (value == 2) {
              Navigator.pushNamed(context, ProfileScreen.routeName);
            }
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_rounded, color: Color(0xFF1E1F22)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Consumer<CartProvider>(
                builder: (context, cart, _) => _CartBadge(
                  count: cart.itemCount,
                  child: const Icon(Icons.shopping_cart_outlined,
                      color: Color(0xFF2D2E32)),
                ),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Color(0xFF2D2E32)),
              label: 'Profile',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: productProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E1F22)),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Sleek Custom Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search premium items...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.grey.shade600, size: 22),
                        suffixIcon: Icon(
                          Icons.tune_rounded,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  // Top Banner Ad for monetization
                  const Center(child: MockBannerAd()),

                  const SizedBox(height: 4),

                  // Horizontal Category List
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: productProvider.categories.length,
                      itemBuilder: (context, index) {
                        final category = productProvider.categories[index];
                        return CategoryChip(
                          title: category,
                          isSelected:
                              productProvider.selectedCategory == category,
                          onTap: () => productProvider.selectCategory(category),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Featured Heading with Badge Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Featured Collection',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1F22),
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (productProvider.featuredProducts.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star,
                                  color: Colors.amber.shade700, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${productProvider.featuredProducts.length} Premium',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (productProvider.featuredProducts.isEmpty)
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'No featured products available.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  else
                    SizedBox(
                      height: 240,
                      child: PageView.builder(
                        controller: _featuredController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: productProvider.featuredProducts.length,
                        onPageChanged: (index) =>
                            setState(() => _featuredIndex = index),
                        itemBuilder: (context, index) {
                          final product =
                              productProvider.featuredProducts[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  ProductDetailsScreen.routeName,
                                  arguments: product,
                                );
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  AppImage(
                                    imageSource: product.imageURL,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(24),
                                    fallbackIcon: Icons.image_not_supported_outlined,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withValues(alpha: 0.0),
                                          Colors.black.withValues(alpha: 0.65),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 20,
                                    right: 20,
                                    bottom: 20,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            product.category.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${product.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Animated Page Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      productProvider.featuredProducts.length,
                      (dotIndex) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _featuredIndex == dotIndex ? 18 : 6,
                        decoration: BoxDecoration(
                          color: _featuredIndex == dotIndex
                              ? const Color(0xFF1E1F22)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Top Picks Header
                  const Text(
                    'Top Picks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1F22),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (productProvider.filteredProducts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No products found in this category.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: productProvider.filteredProducts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.65,
                      ),
                      itemBuilder: (context, index) {
                        final product = productProvider.filteredProducts[index];
                        return ProductCard(
                          product: product,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              ProductDetailsScreen.routeName,
                              arguments: product,
                            );
                          },
                          onAddToCart: () {
                            final cart = context.read<CartProvider>();
                            cart.addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1E1F22),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                content: Text(
                                  '${product.name} added to cart',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }
}

class _CartBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const _CartBadge({
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const _NotificationBadge({
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
