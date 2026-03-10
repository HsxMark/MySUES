import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'main_entry_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String asset = isDark
        ? 'assets/videos/splash-night.mp4'
        : 'assets/videos/splash-day.mp4';

    _controller = VideoPlayerController.asset(asset)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
      });

    _controller.addListener(() {
      if (!mounted) return;
      if (_controller.value.isInitialized &&
          !_controller.value.isPlaying &&
          _controller.value.position >= _controller.value.duration) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainEntryScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double kWidthFactor  = 0.40;
    const double kHeightFactor = 0.40;
    final screenSize = MediaQuery.sizeOf(context);
    final double videoW = screenSize.width  * kWidthFactor;
    final double videoH = screenSize.height * kHeightFactor;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: _controller.value.isInitialized
          ? Center(
              child: SizedBox(
                width: videoW,
                height: videoH,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
