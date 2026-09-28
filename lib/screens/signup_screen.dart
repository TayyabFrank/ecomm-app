import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/firestore_service.dart';
import '../services/event_bus.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'admin_panel_screen.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  static const routeName = '/signup';

  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final success = await auth.signUp(
      name: _nameController.text.trim(),
      email: email,
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (!success) {
      EventBus.instance
          .fire(SecurityAlertEvent('Failed registration attempt for: $email'));
      return;
    }

    EventBus.instance.fire(SecurityAlertEvent('New user registered: $email'));

    // Load the user's cart (empty for new users)
    if (auth.firebaseUser != null) {
      final cart = context.read<CartProvider>();
      await cart.loadCartForUser(auth.firebaseUser!.uid);
    }

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      auth.isAdmin ? AdminPanelScreen.routeName : HomeScreen.routeName,
      (route) => false,
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
            top: -70,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x122D2E32),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -70,
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Join now and shop in a fast, elegant experience.',
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
                                controller: _nameController,
                                hintText: 'Full Name',
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Name is required'
                                        : null,
                              ),
                              const SizedBox(height: 14),
                              CustomTextField(
                                controller: _emailController,
                                hintText: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email is required';
                                  }
                                  final emailRegex =
                                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Enter a valid email address';
                                  }
                                  if (value.toLowerCase() ==
                                      FirestoreService.adminEmail
                                          .toLowerCase()) {
                                    return 'Admin account is reserved. Please use the admin login.';
                                  }
                                  return null;
                                },
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
                                        ? 'Creating account...'
                                        : 'Create Account',
                                    onPressed:
                                        auth.isLoading ? null : _handleSignup,
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
                              Navigator.pop(context);
                            },
                            child:
                                const Text('Already have an account? Sign in'),
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
