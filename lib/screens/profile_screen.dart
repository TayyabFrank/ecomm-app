import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../services/log_service.dart';
import '../services/permission_service.dart';
import '../widgets/app_image.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingAvatar = false;

  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.blue.shade700),
                ),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use your device camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Icons.photo_library, color: Colors.green.shade700),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Pick an existing photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    // Request the appropriate permission first.
    bool hasPermission;
    if (source == ImageSource.camera) {
      hasPermission = await PermissionService.requestCamera();
    } else {
      hasPermission = await PermissionService.requestGallery();
    }

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Permission denied. Please grant access from device settings.'),
          ),
        );
      }
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile == null) return; // User cancelled.

      setState(() => _isUploadingAvatar = true);

      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (mounted) {
        await context.read<AuthProvider>().updateProfileImage(base64Image);
        LogService.info('ProfileScreen', 'Profile avatar updated');
      }
    } catch (e) {
      LogService.error('ProfileScreen', 'Failed to pick image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final user = authProvider.appUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Profile Card with Editable Avatar ──
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Tappable avatar
                    GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Stack(
                        children: [
                          ClipOval(
                            child: _isUploadingAvatar
                                ? Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  )
                                : (user?.profileImage.isNotEmpty == true
                                    ? AppImage(
                                        imageSource: user!.profileImage,
                                        width: 56,
                                        height: 56,
                                        fallbackIcon: Icons.person_outline,
                                      )
                                    : Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.blueGrey.shade200,
                                        child: const Icon(
                                          Icons.person_outline,
                                          size: 30,
                                          color: Colors.white,
                                        ),
                                      )),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Guest User',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'Not signed in',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        user?.role == 'admin' ? 'Admin' : 'Customer',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor:
                          user?.role == 'admin' ? Colors.blueGrey : Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Shopping History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              child: ListTile(
                leading:
                    const Icon(Icons.receipt_long, color: Color(0xFF2D2E32)),
                title: const Text('My Purchase Records'),
                subtitle: const Text('View and track your previous orders'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, OrderHistoryScreen.routeName);
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Account Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              child: ListTile(
                title: const Text('User ID'),
                subtitle: Text(authProvider.firebaseUser?.uid ?? '-'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              child: ListTile(
                title: const Text('Email'),
                subtitle: Text(user?.email ?? '-'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              child: ListTile(
                title: const Text('Full Name'),
                subtitle: Text(user?.fullName ?? '-'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Preferences',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Display Currency',
                        style: TextStyle(fontSize: 16)),
                    if (currencyProvider.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      DropdownButton<String>(
                        value: currencyProvider.selectedCurrency,
                        underline: const SizedBox(),
                        items: currencyProvider.availableCurrencies
                            .map((currency) => DropdownMenuItem(
                                  value: currency,
                                  child: Text(currency),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            currencyProvider.setCurrency(value);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            PrimaryButton(
              label: 'Logout',
              onPressed: () async {
                // Clear user's in-memory cart
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
    );
  }
}
