import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/services/locale_service.dart';
import 'package:mysues/services/theme_service.dart';
import 'package:mysues/services/notification_service.dart';
import 'package:mysues/theme/app_theme.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mysues/services/widget_service.dart';
import 'screens/splash_screen.dart';
import 'screens/main_entry_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await LocaleService().loadSettings();
    await WidgetService.updateWidget();
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  Workmanager().registerPeriodicTask(
    "widgetUpdateTask",
    "updateWidget",
    frequency: const Duration(minutes: 15),
  );

  // Also update widget on app launch
  WidgetService.updateWidget();

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.loadSettings();

  final localeService = LocaleService();
  await localeService.loadSettings();

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
      animation: Listenable.merge([ThemeService(), LocaleService()]),
      builder: (context, child) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          themeMode: ThemeService().themeMode,
          theme: AppTheme.light(ThemeService().fontFamily),
          darkTheme: AppTheme.dark(ThemeService().fontFamily),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: LocaleService().localeOverride,
          localeResolutionCallback: (locale, supportedLocales) =>
              LocaleService.resolveLocale(locale ?? const Locale('en')),
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
