import '../widgets/app_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/primary_button.dart';
import 'admin_panel_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _prepareApp();
  }

  Future<void> _prepareApp() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();
    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      // Load persisted cart for the logged-in user
      if (authProvider.firebaseUser != null) {
        final cart = context.read<CartProvider>();
        await cart.loadCartForUser(authProvider.firebaseUser!.uid);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        authProvider.isAdmin
            ? AdminPanelScreen.routeName
            : HomeScreen.routeName,
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: const AppImage(
              imageSource:
                  'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?auto=format&fit=crop&w=1200&q=80',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.68),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'MINIMA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Elevate Your\nEveryday Style',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Modern essentials with timeless aesthetics, crafted for your daily life.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Get Started',
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                          context, LoginScreen.routeName);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
