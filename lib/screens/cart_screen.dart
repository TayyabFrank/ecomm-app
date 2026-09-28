import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/app_image.dart';

import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../widgets/primary_button.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  static const routeName = '/cart';

  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              if (cart.items.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: cart.clearCart,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                  label: const Text(
                    'Clear All',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<CartProvider, CurrencyProvider>(
        builder: (context, cart, currencyProvider, _) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1F22),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add products to explore our elegant collections.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    final lineTotal = item.quantity * item.product.price;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            AppImage(
                              imageSource: item.product.imageURL,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(16),
                              fallbackIcon: Icons.image_not_supported_outlined,
                            ),
                            const SizedBox(width: 14),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF1E1F22),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            cart.removeProductCompletely(
                                                item.product.id),
                                        child: Icon(Icons.delete_outline_rounded,
                                            color: Colors.red.shade400,
                                            size: 20),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${currencyProvider.formatPrice(item.product.price)} each',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        currencyProvider.formatPrice(lineTotal),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Color(0xFF1E1F22),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: Colors.grey.shade200),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2, vertical: 2),
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () =>
                                                  cart.decreaseQuantity(
                                                      item.product.id),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                child: Icon(Icons.remove,
                                                    size: 14,
                                                    color: Colors.grey.shade700),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6),
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () =>
                                                  cart.increaseQuantity(
                                                      item.product.id),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                child: Icon(Icons.add,
                                                    size: 14,
                                                    color: Colors.grey.shade700),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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

              // Summary Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Items (${cart.itemCount})',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currencyProvider.formatPrice(cart.totalPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: Color(0xFF1E1F22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Proceed to Checkout',
                      icon: Icons.payment_rounded,
                      onPressed: () {
                        Navigator.pushNamed(context, CheckoutScreen.routeName);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
