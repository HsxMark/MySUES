import 'dart:async';

import 'package:flutter/material.dart';
import 'main_entry_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _dayAsset = 'assets/videos/splash-day.gif';
  static const String _nightAsset = 'assets/videos/splash-night.gif';
  static const Duration _dayDuration = Duration(milliseconds: 2336);
  static const Duration _nightDuration = Duration(milliseconds: 2002);

  late String _asset;
  late Duration _animationDuration;
  Timer? _navigationTimer;
  bool _initialized = false;
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    _asset = isDark ? _nightAsset : _dayAsset;
    _animationDuration = isDark ? _nightDuration : _dayDuration;

    precacheImage(AssetImage(_asset), context);
    _navigationTimer = Timer(_animationDuration, _navigateToMain);
  }

  void _navigateToMain() {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainEntryScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double kWidthFactor = 0.40;
    const double kHeightFactor = 0.40;
    final screenSize = MediaQuery.sizeOf(context);
    final double animationW = screenSize.width * kWidthFactor;
    final double animationH = screenSize.height * kHeightFactor;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: SizedBox(
          width: animationW,
          height: animationH,
          child: Image.asset(
            _asset,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _navigateToMain();
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
