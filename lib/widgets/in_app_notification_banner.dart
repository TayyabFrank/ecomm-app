import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class InAppNotificationBanner extends StatefulWidget {
  final AppNotificationModel notification;
  final VoidCallback onDismiss;

  const InAppNotificationBanner({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

  /// Instantiates and inserts an OverlayEntry containing the slide-down banner.
  static void show(BuildContext context, AppNotificationModel notification) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return InAppNotificationBanner(
          notification: notification,
          onDismiss: () {
            try {
              entry.remove();
            } catch (_) {
              // Overlay entry might have already been removed.
            }
          },
        );
      },
    );
    
    final overlayState = Overlay.of(context);
    overlayState.insert(entry);
  }

  @override
  State<InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _controller.forward();

    // Auto dismiss after 4 seconds
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (mounted && _controller.isAnimating == false) {
      _controller.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return const Color(0xFF4CAF50); // Emerald green
      case 'security':
        return const Color(0xFFF44336); // Crimson red
      case 'product':
        return const Color(0xFF9C27B0); // Deep purple
      case 'system':
      default:
        return const Color(0xFF2196F3); // Ocean blue
    }
  }

  IconData _getCategoryIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'security':
        return Icons.lock_outline_rounded;
      case 'product':
        return Icons.sell_outlined;
      case 'system':
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getCategoryColor(widget.notification.type);
    final typeIcon = _getCategoryIcon(widget.notification.type);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1F22).withValues(alpha: 0.95), // Premium dark theme overlay
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon Circle
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    
                    // Texts
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.notification.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.notification.body,
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 12,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                      onPressed: _dismiss,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
