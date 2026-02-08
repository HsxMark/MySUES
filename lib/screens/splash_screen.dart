import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'main_entry_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainEntryScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if we are in dark mode
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: SvgPicture.asset(
            'assets/images/sanxuanyi.svg',
            fit: BoxFit.contain,
            colorFilter: isDark 
                ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) 
                : null,
          ),
        ),
      ),
    );
  }
}
