import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/app_image.dart';

import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../widgets/primary_button.dart';

class ProductDetailsScreen extends StatefulWidget {
  static const routeName = '/product-details';
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _expanded = false;
  String _selectedSize = 'M';
  Color _selectedColor = const Color(0xFF2D2E32);
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.product;
    final sizes = ['S', 'M', 'L', 'XL'];
    final colors = [
      const Color(0xFF2D2E32),
      const Color(0xFF9A8C7B),
      const Color(0xFF3E5C76),
      const Color(0xFFB33939),
    ];

    final media = MediaQuery.sizeOf(context);
    final currencyProvider = context.watch<CurrencyProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // ── Scrollable Body ──
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                // Premium Full-Width Image Header
                Hero(
                  tag: 'product-image-${item.id}',
                  child: Stack(
                    children: [
                      AppImage(
                        imageSource: item.imageURL,
                        width: double.infinity,
                        height: media.height * 0.46,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.image_not_supported_outlined,
                        fallbackIconSize: 48,
                      ),
                      // Soft overlay at bottom of image
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.15),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Details Content Sheet
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category & Rating Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1F22)
                                    .withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: Color(0xFF1E1F22),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title & Price
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Color(0xFF1E1F22),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyProvider.formatPrice(item.price),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E1F22),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description Section
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1F22),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 250),
                          crossFadeState: _expanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: Text(
                            item.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                height: 1.5,
                                fontSize: 14),
                          ),
                          secondChild: Text(
                            item.description,
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                height: 1.5,
                                fontSize: 14),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _expanded = !_expanded),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _expanded ? 'Show Less' : 'Read More',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1F22),
                            ),
                          ),
                        ),
                        const Divider(height: 36),

                        // Size Selection
                        const Text(
                          'Select Size',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1F22),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: sizes.map((size) {
                            final selected = _selectedSize == size;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedSize = size),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFF1E1F22)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF1E1F22)
                                          : Colors.grey.shade300,
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      size,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : Colors.grey.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 28),

                        // Color Selection
                        const Text(
                          'Select Color',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1F22),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: colors.map((color) {
                            final selected = _selectedColor == color;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedColor = color),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 38,
                                height: 38,
                                margin: const EdgeInsets.only(right: 14),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: selected ? 3 : 0,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.4),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 28),

                        // Quantity Selector
                        const Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1F22),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity -= 1)
                                    : null,
                                icon: const Icon(Icons.remove, size: 20),
                                color: const Color(0xFF1E1F22),
                              ),
                              Container(
                                constraints: const BoxConstraints(minWidth: 32),
                                alignment: Alignment.center,
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _quantity += 1),
                                icon: const Icon(Icons.add, size: 20),
                                color: const Color(0xFF1E1F22),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Top Navigation Bar Overlay ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18),
                        onPressed: () => Navigator.pop(context),
                        color: const Color(0xFF1E1F22),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.favorite_border_rounded,
                            size: 20),
                        onPressed: () {
                          // Optional Favorite toggle
                        },
                        color: const Color(0xFF1E1F22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Action Buy Panel ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Consumer<CartProvider>(
                builder: (context, cart, _) {
                  final inCart = cart.hasProduct(item.id);
                  final inCartQty = cart.quantityFor(item.id);
                  return Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label:
                              inCart ? 'Add More ($_quantity)' : 'Add to Cart',
                          icon: Icons.shopping_cart_checkout_rounded,
                          onPressed: () {
                            final messenger = ScaffoldMessenger.of(context);
                            final before = cart.itemCount;
                            for (int i = 0; i < _quantity; i++) {
                              cart.addToCart(item);
                            }
                            final after = cart.itemCount;
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1E1F22),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                content: Text(
                                  after > before
                                      ? 'Added $_quantity item(s). In Cart: ${inCartQty + _quantity}'
                                      : 'Unable to add items right now',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (inCart) ...[
                        const SizedBox(width: 12),
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            tooltip: 'Remove from cart',
                            onPressed: () {
                              cart.removeProductCompletely(item.id);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red.shade900,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    content: const Text(
                                      'Removed from cart',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                            },
                            icon: Icon(Icons.remove_shopping_cart_outlined,
                                color: Colors.red.shade700, size: 22),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
