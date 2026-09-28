import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../services/log_service.dart';
import '../services/permission_service.dart';
import '../widgets/app_image.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class ProductEditorScreen extends StatefulWidget {
  static const routeName = '/product-editor';

  final ProductModel? product;

  const ProductEditorScreen({super.key, this.product});

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageController = TextEditingController();
  final _ratingController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isFeatured = false;

  final ImagePicker _picker = ImagePicker();
  String? _pickedBase64Image; // Holds base64 if user picks from device
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _priceController.text = product.price.toStringAsFixed(2);
      _categoryController.text = product.category;
      _imageController.text = product.imageURL;
      _ratingController.text = product.rating.toStringAsFixed(1);
      _descriptionController.text = product.description;
      _isFeatured = product.isFeatured;

      // If existing image is base64, preload it into the preview
      if (product.imageURL.isNotEmpty &&
          !product.imageURL.startsWith('http')) {
        _pickedBase64Image = product.imageURL;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _imageController.dispose();
    _ratingController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showImageSourceSheet() {
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
                'Pick Product Image',
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
      setState(() => _isPicking = true);

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile == null) return; // User cancelled.

      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        _pickedBase64Image = base64Image;
        _imageController.text = base64Image;
      });

      LogService.info('ProductEditor', 'Picked image from $source');
    } catch (e) {
      LogService.error('ProductEditor', 'Failed to pick image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  /// Returns the image source string to store. Prefers a picked base64 image;
  /// otherwise uses whatever was typed in the URL field.
  String get _resolvedImageSource {
    if (_pickedBase64Image != null && _pickedBase64Image!.isNotEmpty) {
      return _pickedBase64Image!;
    }
    return _imageController.text.trim();
  }

  /// Current preview source for the image container.
  String get _previewSource {
    if (_pickedBase64Image != null && _pickedBase64Image!.isNotEmpty) {
      return _pickedBase64Image!;
    }
    return _imageController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.read<ProductProvider>();
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Image Preview & Picker ──
                GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _isPicking
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : _previewSource.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: AppImage(
                                  imageSource: _previewSource,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  fallbackIcon: Icons.add_photo_alternate,
                                  fallbackIconSize: 50,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      size: 50, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to pick an image',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── OR: Image URL Text Field ──
                CustomTextField(
                    controller: _imageController,
                    hintText: 'Image URL (or pick above)',
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      // Valid if either a URL was typed or an image was picked
                      if ((value == null || value.isEmpty) &&
                          (_pickedBase64Image == null ||
                              _pickedBase64Image!.isEmpty)) {
                        return 'Image required – pick or enter a URL';
                      }
                      return null;
                    }),
                const SizedBox(height: 12),
                CustomTextField(
                    controller: _nameController,
                    hintText: 'Product name',
                    validator: (value) => value == null || value.isEmpty
                        ? 'Product name required'
                        : null),
                const SizedBox(height: 12),
                CustomTextField(
                    controller: _categoryController,
                    hintText: 'Category',
                    validator: (value) => value == null || value.isEmpty
                        ? 'Category required'
                        : null),
                const SizedBox(height: 12),
                CustomTextField(
                    controller: _priceController,
                    hintText: 'Price',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Price required';
                      }
                      return double.tryParse(value) == null
                          ? 'Enter a valid number'
                          : null;
                    }),
                const SizedBox(height: 12),
                CustomTextField(
                    controller: _ratingController,
                    hintText: 'Rating (0.0 - 5.0)',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final rating = double.tryParse(value ?? '');
                      if (rating == null) return 'Enter a valid rating';
                      if (rating < 0 || rating > 5) {
                        return 'Rating must be between 0 and 5';
                      }
                      return null;
                    }),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Description'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Description required'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Featured product'),
                    const Spacer(),
                    Switch(
                      value: _isFeatured,
                      onChanged: (value) =>
                          setState(() => _isFeatured = value),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: isEditing ? 'Update Product' : 'Create Product',
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final product = ProductModel(
                      id: widget.product?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text.trim(),
                      category: _categoryController.text.trim(),
                      price: double.parse(_priceController.text.trim()),
                      imageURL: _resolvedImageSource,
                      rating: double.parse(_ratingController.text.trim()),
                      description: _descriptionController.text.trim(),
                      isFeatured: _isFeatured,
                    );
                    if (isEditing) {
                      await productProvider.updateProduct(product);
                    } else {
                      await productProvider.addProduct(product);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
