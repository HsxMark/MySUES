import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mysues/services/theme_service.dart';
import 'package:mysues/l10n/legacy_text.dart';
import 'package:mysues/widgets/material_you.dart';

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
    final fontName = _getFontName(currentFontFamily);

    return Scaffold(
      appBar: AppBar(title: const LText('界面与显示')),
      body: ListView(
        children: [
          const AppSectionHeader('外观'),
          AppCardSection(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const LText('深色模式'),
                subtitle: LText(_getThemeModeText(themeModeIndex)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemePicker(themeModeIndex),
              ),
              ListTile(
                leading: const Icon(Icons.wallpaper_outlined),
                title: const LText('设置背景图片'),
                subtitle: LText(
                  ThemeService().backgroundImagePath != null ? '已设置' : '未设置',
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
                title: const LText('开屏动画'),
                subtitle: const LText('启动应用时显示开屏动画'),
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
                  const LText('背景透明度'),
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
                    child: LText(
                      '${((_previewOpacity ?? ThemeService().backgroundOpacity) * 100).round()}%',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          const AppSectionHeader('字体'),
          AppCardSection(
            children: [
              ListTile(
                leading: const Icon(Icons.font_download_outlined),
                title: const LText('字体样式'),
                subtitle: LText(fontName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showFontPicker(currentFontFamily),
              ),
            ],
          ),
          const AppSectionHeader('实验性外观'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppNoticeBanner(
              message: '实验性外观可能降低部分页面的对比度或性能，默认 Material You 外观不受影响。',
            ),
          ),
          const SizedBox(height: 12),
          AppCardSection(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.blur_on_outlined),
                title: const LText('液态玻璃效果 (BETA)'),
                subtitle: const LText('开启后界面将呈现磨砂玻璃质感'),
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

  String _getThemeModeText(int index) {
    switch (index) {
      case 1:
        return '浅色';
      case 2:
        return '深色';
      case 0:
      default:
        return '跟随系统';
    }
  }

  String _getFontName(String? family) {
    if (family == null) return '系统默认';
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
              const labels = ['跟随系统', '浅色模式', '深色模式'];
              const icons = [
                Icons.brightness_auto,
                Icons.light_mode,
                Icons.dark_mode,
              ];
              return ListTile(
                leading: Icon(icons[index]),
                title: LText(labels[index]),
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
            title: LText(title),
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
              buildTile('系统默认', null),
              buildTile('HarmonyOS Sans', 'HarmonyOS Sans'),
              buildTile('MiSans', 'MiSans'),
            ],
          ),
        );
      },
    );
  }
}
