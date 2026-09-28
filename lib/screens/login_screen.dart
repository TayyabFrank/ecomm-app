import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'admin_panel_screen.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import '../services/event_bus.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final success = await auth.signIn(
      email: email,
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (!success) {
      EventBus.instance
          .fire(SecurityAlertEvent('Failed login attempt for: $email'));
      return;
    }

    EventBus.instance.fire(SecurityAlertEvent('Login successful for: $email'));

    // Load the user's persisted cart from Firestore
    if (auth.firebaseUser != null) {
      final cart = context.read<CartProvider>();
      await cart.loadCartForUser(auth.firebaseUser!.uid);
    }

    if (!mounted) return;

    // Single login page: admin credentials → admin panel, otherwise → store
    Navigator.pushReplacementNamed(
      context,
      auth.isAdmin ? AdminPanelScreen.routeName : HomeScreen.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x142D2E32),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x112D2E32),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 430,
                    minHeight: media.height - 48,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sign in to continue your premium shopping experience.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (auth.error == null) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      auth.error!,
                                      style: TextStyle(
                                        color: Colors.red.shade800,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      auth.error = null;
                                      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                                      auth.notifyListeners();
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CustomTextField(
                                controller: _emailController,
                                hintText: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 14),
                              CustomTextField(
                                controller: _passwordController,
                                hintText: 'Password',
                                obscureText: _obscurePassword,
                                validator: (value) {
                                  if (value == null || value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return PrimaryButton(
                                    label: auth.isLoading
                                        ? 'Signing in...'
                                        : 'Login',
                                    onPressed:
                                        auth.isLoading ? null : _handleLogin,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, SignupScreen.routeName);
                            },
                            child: const Text('Create a new account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
