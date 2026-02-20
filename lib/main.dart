import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mysues/services/theme_service.dart';
import 'package:mysues/services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/main_entry_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize theme service
  final themeService = ThemeService();
  await themeService.loadSettings();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(const MyApp());

  // Reschedule notifications after app is running to avoid blocking startup
  notificationService.rescheduleAll().catchError((e) {
    debugPrint('Failed to reschedule notifications: $e');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, child) {
        return MaterialApp(
          title: '我的课表',
          themeMode: ThemeService().themeMode,
          theme: ThemeData(
            fontFamily: ThemeService().fontFamily,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          ),
          darkTheme: ThemeData(
            fontFamily: ThemeService().fontFamily,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          locale: const Locale('zh', 'CN'),
          // 切换到带底部导航的主界面
          home: ThemeService().splashAnimationEnabled
              ? const SplashScreen()
              : const MainEntryScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
