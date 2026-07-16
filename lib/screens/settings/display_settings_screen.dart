import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mysues/services/theme_service.dart';
import 'package:mysues/widgets/material_you.dart';
import 'package:mysues/l10n/l10n.dart';

class DisplaySettingsScreen extends StatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  State<DisplaySettingsScreen> createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends State<DisplaySettingsScreen> {
  bool _liquidGlassEnabled = false;
  bool _splashAnimationEnabled = false;
  double? _previewOpacity;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // We can get the value from ThemeService if it is initialized, or prefs
    setState(() {
      _liquidGlassEnabled = ThemeService().liquidGlassEnabled;
      _splashAnimationEnabled = ThemeService().splashAnimationEnabled;
    });
  }

  Future<void> _saveThemeMode(int index) async {
    await ThemeService().updateThemeMode(index);
    setState(() {});
  }

  Future<void> _saveLiquidGlass(bool value) async {
    await ThemeService().updateLiquidGlass(value);
    setState(() {
      _liquidGlassEnabled = value;
    });
  }

  Future<void> _saveSplashAnimation(bool value) async {
    await ThemeService().updateSplashAnimation(value);
    setState(() {
      _splashAnimationEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ThemeService().themeMode;
    final int themeModeIndex = currentMode == ThemeMode.system
        ? 0
        : (currentMode == ThemeMode.light ? 1 : 2);

    final currentFontFamily = ThemeService().fontFamily;
    final fontName = _getFontName(context, currentFontFamily);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appearanceAndDisplay)),
      body: ListView(
        children: [
          AppSectionHeader(context.l10n.appearance),
          AppCardSection(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: Text(context.l10n.darkMode),
                subtitle: Text(_getThemeModeText(context, themeModeIndex)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemePicker(themeModeIndex),
              ),
              ListTile(
                leading: const Icon(Icons.wallpaper_outlined),
                title: Text(context.l10n.setBackgroundImage),
                subtitle: Text(
                  ThemeService().backgroundImagePath != null
                      ? context.l10n.setValue
                      : context.l10n.notSet,
                ),
                trailing: ThemeService().backgroundImagePath != null
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () async {
                          await ThemeService().clearBackgroundImage();
                          setState(() {});
                        },
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => _pickBackgroundImage(),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.animation_outlined),
                title: Text(context.l10n.splashAnimation),
                subtitle: Text(
                  context.l10n.showTheSplashAnimationWhenTheAppStarts,
                ),
                value: _splashAnimationEnabled,
                onChanged: (value) => _saveSplashAnimation(value),
              ),
            ],
          ),
          if (ThemeService().backgroundImagePath != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Checkerboard-like background to show transparency
                      Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      Opacity(
                        opacity:
                            _previewOpacity ?? ThemeService().backgroundOpacity,
                        child: Image.file(
                          File(ThemeService().backgroundImagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (ThemeService().backgroundImagePath != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(context.l10n.backgroundOpacity),
                  Expanded(
                    child: Slider(
                      value:
                          _previewOpacity ?? ThemeService().backgroundOpacity,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label:
                          '${((_previewOpacity ?? ThemeService().backgroundOpacity) * 100).round()}%',
                      onChanged: (value) {
                        setState(() {
                          _previewOpacity = value;
                        });
                      },
                      onChangeEnd: (value) async {
                        await ThemeService().updateBackgroundOpacity(value);
                        setState(() {
                          _previewOpacity = null;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${((_previewOpacity ?? ThemeService().backgroundOpacity) * 100).round()}%',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          AppSectionHeader(context.l10n.font),
          AppCardSection(
            children: [
              ListTile(
                leading: const Icon(Icons.font_download_outlined),
                title: Text(context.l10n.fontStyle),
                subtitle: Text(fontName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showFontPicker(currentFontFamily),
              ),
            ],
          ),
          AppSectionHeader(context.l10n.experimentalAppearance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppNoticeBanner(
              message: context
                  .l10n
                  .experimentalAppearanceMayReduceContrastOrPerformanceOnSome,
            ),
          ),
          const SizedBox(height: 12),
          AppCardSection(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.blur_on_outlined),
                title: Text(context.l10n.liquidGlassEffectBETA),
                subtitle: Text(
                  context.l10n.addsAFrostedGlassAppearanceToTheInterface,
                ),
                value: _liquidGlassEnabled,
                onChanged: (value) => _saveLiquidGlass(value),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getThemeModeText(BuildContext context, int index) {
    switch (index) {
      case 1:
        return context.l10n.light;
      case 2:
        return context.l10n.dark;
      case 0:
      default:
        return context.l10n.languageSystem;
    }
  }

  String _getFontName(BuildContext context, String? family) {
    if (family == null) return context.l10n.systemDefault;
    if (family == 'HarmonyOS Sans') return 'HarmonyOS Sans';
    if (family == 'MiSans') return 'MiSans';
    return family;
  }

  Future<void> _pickBackgroundImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      await ThemeService().updateBackgroundImage(result.files.single.path!);
      if (mounted) setState(() {});
    }
  }

  void _showThemePicker(int currentIndex) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final labels = [
                context.l10n.languageSystem,
                context.l10n.lightMode,
                context.l10n.darkMode,
              ];
              const icons = [
                Icons.brightness_auto,
                Icons.light_mode,
                Icons.dark_mode,
              ];
              return ListTile(
                leading: Icon(icons[index]),
                title: Text(labels[index]),
                trailing: currentIndex == index
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () async {
                  await _saveThemeMode(index);
                  if (context.mounted) Navigator.pop(context);
                },
              );
            }),
          ),
        );
      },
    );
  }

  void _showFontPicker(String? currentFamily) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        // Helper to build list tiles
        Widget buildTile(String title, String? family) {
          final isSelected = currentFamily == family;
          return ListTile(
            title: Text(title),
            trailing: isSelected
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () async {
              await ThemeService().updateFontFamily(family);
              if (mounted) Navigator.pop(context);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTile(context.l10n.systemDefault, null),
              buildTile('HarmonyOS Sans', 'HarmonyOS Sans'),
              buildTile('MiSans', 'MiSans'),
            ],
          ),
        );
      },
    );
  }
}
