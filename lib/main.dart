import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/currency_provider.dart';
import 'screens/admin_panel_screen.dart';
import 'models/product_model.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/product_editor_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/admin_orders_screen.dart';
import 'screens/admin_logs_screen.dart';
import 'screens/performance_dashboard_screen.dart';
import 'providers/notification_provider.dart';
import 'screens/notification_center_screen.dart';
import 'services/product_seed_service.dart';
import 'services/log_service.dart';

void main() {
  runApp(const MyApp());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    if (await ProductSeedService.isEmpty()) {
      await ProductSeedService.seedProducts();
    }
    LogService.info('App', 'Firebase initialized successfully');
  } catch (e) {
    // Firebase not configured - app will run in offline mode
    LogService.error('App', 'Firebase not configured', error: e);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2D2E32);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: Colors.white,
      brightness: Brightness.light,
    );

    return FutureBuilder(
      future: _initializeFirebase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<ProductProvider>(
                create: (_) => ProductProvider()),
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
            ChangeNotifierProvider<CurrencyProvider>(
                create: (_) => CurrencyProvider()),
            ChangeNotifierProvider<NotificationProvider>(
                create: (_) => NotificationProvider()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Flutter E-Commerce',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: scheme,
              scaffoldBackgroundColor: const Color(0xFFF7F7F8),
              canvasColor: const Color(0xFFF7F7F8),
              cardColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: primary,
                elevation: 0,
                centerTitle: false,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: primary, width: 1),
                ),
              ),
            ),
            initialRoute: SplashScreen.routeName,
            routes: {
              SplashScreen.routeName: (_) => const SplashScreen(),
              LoginScreen.routeName: (_) => const LoginScreen(),
              SignupScreen.routeName: (_) => const SignupScreen(),
              HomeScreen.routeName: (_) => const HomeScreen(),
              AdminPanelScreen.routeName: (_) => const AdminPanelScreen(),
              CartScreen.routeName: (_) => const CartScreen(),
              CheckoutScreen.routeName: (_) => const CheckoutScreen(),
              ProfileScreen.routeName: (_) => const ProfileScreen(),
              OrderHistoryScreen.routeName: (_) => const OrderHistoryScreen(),
              AdminOrdersScreen.routeName: (_) => const AdminOrdersScreen(),
              AdminLogsScreen.routeName: (_) => const AdminLogsScreen(),
              PerformanceDashboardScreen.routeName: (_) =>
                  const PerformanceDashboardScreen(),
              NotificationCenterScreen.routeName: (_) =>
                  const NotificationCenterScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == ProductDetailsScreen.routeName) {
                final product = settings.arguments;
                if (product is! ProductModel) {
                  return null;
                }
                return MaterialPageRoute(
                  builder: (_) => ProductDetailsScreen(product: product),
                );
              }
              if (settings.name == ProductEditorScreen.routeName) {
                final product = settings.arguments;
                return MaterialPageRoute(
                  builder: (_) =>
                      ProductEditorScreen(product: product as ProductModel?),
                );
              }
              return null;
            },
          ),
        );
      },
    );
  }
}
