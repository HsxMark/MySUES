import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EggScreen extends StatelessWidget {
  const EggScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2F99),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2F99),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/sanxuanyi.svg',
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              width: 150,
            ),
            const SizedBox(height: 24),
            const Text(
              '工程、管理、设计',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
