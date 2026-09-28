import 'dart:async';
import 'package:flutter/material.dart';

import 'log_service.dart';

/// A robust mock advertising service that mimics real AdMob behavior.
/// This allows visualizing the exact monetization UI/UX before
/// adding the real platform-specific Ad SDKs.
class AdService {
  AdService._();

  /// Simulates showing a full-screen interstitial ad.
  /// Typically takes 3 to 5 seconds to become dismissible.
  /// Returns a Future that completes when the ad is closed.
  static Future<void> showInterstitialAd(BuildContext context) async {
    LogService.info('AdService', 'Requesting interstitial ad...');

    // Simulate network delay to load ad
    await Future.delayed(const Duration(milliseconds: 600));

    if (!context.mounted) return;

    LogService.info('AdService', 'Showing interstitial ad');

    return showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const _InterstitialAdScreen();
      },
    );
  }
}

class _InterstitialAdScreen extends StatefulWidget {
  const _InterstitialAdScreen();

  @override
  State<_InterstitialAdScreen> createState() => _InterstitialAdScreenState();
}

class _InterstitialAdScreenState extends State<_InterstitialAdScreen> {
  int _secondsRemaining = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            // Fake Ad Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.star, size: 64, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'SPONSORED',
                    style: TextStyle(
                      color: Colors.white54,
                      letterSpacing: 2,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Try Minima Premium Today!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Get exclusive drops, early access, and free shipping on every single order.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () {
                      LogService.info('AdService', 'Interstitial Ad Clicked');
                      // Simulate ad click
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Learn More',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            // Dismiss / Timer button
            Positioned(
              top: 16,
              right: 16,
              child: _secondsRemaining > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Reward in $_secondsRemaining',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () {
                        LogService.info('AdService', 'Interstitial Ad Closed');
                        Navigator.pop(context);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simulated 320x50 standard mobile banner ad.
class MockBannerAd extends StatelessWidget {
  const MockBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 320,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ad_units, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(
            'Test Banner Ad (320x50)',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
