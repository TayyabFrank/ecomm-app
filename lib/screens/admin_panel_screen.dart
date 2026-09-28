import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'product_editor_screen.dart';
import 'admin_orders_screen.dart';
import 'performance_dashboard_screen.dart';
import 'profile_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  static const routeName = '/admin-panel';

  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      productProvider.startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to store',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, HomeScreen.routeName);
            }
          },
        ),
        title: const Text('Admin Inventory Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.pushNamed(context, ProfileScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              context.read<CartProvider>().clearForLogout();
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  LoginScreen.routeName,
                  (route) => false,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: () {
              Navigator.pushNamed(context, ProductEditorScreen.routeName);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await productProvider.startListening();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${authProvider.appUser?.fullName ?? 'Admin'}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.blue.shade100, width: 1),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.analytics_outlined,
                        color: Colors.blue.shade800),
                  ),
                  title: Text(
                    'Sales & Customer Orders',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Track purchases, sales revenue, and manage order statuses',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                  trailing:
                      Icon(Icons.chevron_right, color: Colors.blue.shade800),
                  onTap: () {
                    Navigator.pushNamed(context, AdminOrdersScreen.routeName);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.orange.shade100, width: 1),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(Icons.bug_report_outlined,
                        color: Colors.orange.shade800),
                  ),
                  title: Text(
                    'System Logs',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'View application events, warnings, and errors',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                  trailing:
                      Icon(Icons.chevron_right, color: Colors.orange.shade800),
                  onTap: () {
                    Navigator.pushNamed(context, '/admin-logs');
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Colors.teal.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.teal.shade100, width: 1),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Icon(Icons.speed_outlined,
                        color: Colors.teal.shade800),
                  ),
                  title: Text(
                    'Performance Monitor',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade900,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Real-time FPS, memory usage, and frame times',
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontSize: 12,
                    ),
                  ),
                  trailing:
                      Icon(Icons.chevron_right, color: Colors.teal.shade800),
                  onTap: () {
                    Navigator.pushNamed(
                        context, PerformanceDashboardScreen.routeName);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.black87),
                      title: const Text('Admin Profile'),
                      subtitle: Text(
                          authProvider.appUser?.email ?? 'admin@admin.com'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.info_outline, color: Colors.black54),
                      title: const Text('View account details'),
                      onTap: () {
                        Navigator.pushNamed(context, ProfileScreen.routeName);
                      },
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text('Logout'),
                      onTap: () async {
                        context.read<CartProvider>().clearForLogout();
                        await authProvider.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            LoginScreen.routeName,
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Product Inventory',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (productProvider.error != null)
                Text(productProvider.error!,
                    style: const TextStyle(color: Colors.red)),
              if (productProvider.isLoading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator())),
              if (!productProvider.isLoading)
                Expanded(
                  child: ListView.builder(
                    itemCount: productProvider.products.length,
                    itemBuilder: (context, index) {
                      final product = productProvider.products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                              '${product.category} • ${product.isFeatured ? 'Featured' : 'Standard'}'),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    ProductEditorScreen.routeName,
                                    arguments: product,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _confirmDelete(
                                    context, productProvider, product.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, ProductProvider provider, String productId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove product'),
          content:
              const Text('Do you want to delete this product permanently?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await provider.deleteProduct(productId);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
