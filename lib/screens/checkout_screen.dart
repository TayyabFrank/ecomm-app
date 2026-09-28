import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_provider.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';
import '../widgets/primary_button.dart';
import '../services/ad_service.dart';
import 'home_screen.dart';
import '../services/event_bus.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';

  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isPlacingOrder = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.appUser;
    final firebaseUser = authProvider.firebaseUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Consumer2<CartProvider, CurrencyProvider>(
        builder: (context, cart, currencyProvider, _) {
          final subtotal = cart.totalPrice;
          final shipping = cart.items.isEmpty ? 0.0 : 8.0;
          final tax = subtotal * 0.05;
          final grandTotal = subtotal + shipping + tax;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Shipping Address',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Guest User',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text('221B Baker Street, London'),
                    Text(user?.email ?? 'No email associated'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Payment Method',
                child: Row(
                  children: [
                    const Icon(Icons.credit_card_outlined),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Visa **** 2048')),
                    TextButton(onPressed: () {}, child: const Text('Change')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Order Summary',
                child: Column(
                  children: [
                    _PriceRow(label: 'Subtotal', value: currencyProvider.formatPrice(subtotal)),
                    _PriceRow(label: 'Shipping', value: currencyProvider.formatPrice(shipping)),
                    _PriceRow(label: 'Tax (5%)', value: currencyProvider.formatPrice(tax)),
                    const Divider(height: 18),
                    _PriceRow(
                      label: 'Total',
                      value: currencyProvider.formatPrice(grandTotal),
                      isEmphasis: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isPlacingOrder ? 'Processing...' : 'Place Order',
                onPressed: cart.items.isEmpty || _isPlacingOrder
                    ? null
                    : () async {
                        if (firebaseUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You must be signed in to purchase'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _isPlacingOrder = true;
                        });

                        // Show Interstitial Ad before finalizing the order
                        await AdService.showInterstitialAd(context);

                        if (!context.mounted) return;

                        try {
                          final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
                          final orderItems = cart.items.map((item) {
                            return OrderItemModel(
                              productId: item.product.id,
                              name: item.product.name,
                              price: item.product.price,
                              quantity: item.quantity,
                              imageURL: item.product.imageURL,
                            );
                          }).toList();

                          final order = OrderModel(
                            id: orderId,
                            userId: firebaseUser.uid,
                            userEmail: firebaseUser.email ?? '',
                            userName: user?.fullName ?? 'Customer',
                            items: orderItems,
                            totalAmount: grandTotal,
                            status: 'Pending',
                            timestamp: DateTime.now(),
                            shippingAddress: '221B Baker Street, London',
                            paymentMethod: 'Visa **** 2048',
                          );

                          await FirestoreService.placeOrder(order);
                          EventBus.instance.fire(OrderPlacedEvent(order));

                          cart.clearCart();
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order placed successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              HomeScreen.routeName,
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error placing order: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isPlacingOrder = false;
                            });
                          }
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasis;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w500,
              fontSize: isEmphasis ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w500,
              fontSize: isEmphasis ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
