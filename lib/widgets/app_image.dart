import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// A smart image widget that resolves multiple image source types:
/// - Network URL (http/https) → CachedNetworkImage
/// - Local file path → Image.file
/// - Base64 encoded string → Image.memory
/// - Empty / invalid → Fallback icon
class AppImage extends StatelessWidget {
  final String imageSource;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double fallbackIconSize;
  final Color? fallbackIconColor;
  final BorderRadius? borderRadius;

  const AppImage({
    super.key,
    required this.imageSource,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackIconSize = 40,
    this.fallbackIconColor,
    this.borderRadius,
  });

  bool get _isNetworkUrl =>
      imageSource.startsWith('http://') || imageSource.startsWith('https://');

  bool get _isBase64 {
    if (imageSource.isEmpty) return false;
    if (_isNetworkUrl) return false;
    // Quick heuristic – base64 images are long and don't contain path separators.
    if (imageSource.length > 100 && !imageSource.contains('/') && !imageSource.contains('\\')) {
      try {
        base64Decode(imageSource);
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  bool get _isFilePath {
    if (imageSource.isEmpty || _isNetworkUrl || _isBase64) return false;
    if (kIsWeb) return false;
    return File(imageSource).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (imageSource.isEmpty) {
      child = _buildFallback(context);
    } else if (_isNetworkUrl) {
      child = CachedNetworkImage(
        imageUrl: imageSource,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) => _buildFallback(context),
      );
    } else if (_isBase64) {
      final Uint8List bytes = base64Decode(imageSource);
      child = Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(context),
      );
    } else if (_isFilePath) {
      child = Image.file(
        File(imageSource),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(context),
      );
    } else {
      // Try treating as network URL as last resort
      child = CachedNetworkImage(
        imageUrl: imageSource,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) => _buildFallback(context),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _buildLoadingPlaceholder() {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          fallbackIcon,
          size: fallbackIconSize,
          color: fallbackIconColor ?? Colors.grey.shade400,
        ),
      ),
    );
  }
}
