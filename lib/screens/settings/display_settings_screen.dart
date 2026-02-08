import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysues/services/theme_service.dart';

class DisplaySettingsScreen extends StatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  State<DisplaySettingsScreen> createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends State<DisplaySettingsScreen> {
  bool _liquidGlassEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _liquidGlassEnabled = prefs.getBool('liquid_glass_beta') ?? false;
    });
  }

  Future<void> _saveThemeMode(int index) async {
    await ThemeService().updateThemeMode(index);
    setState(() {});
  }

  Future<void> _saveLiquidGlass(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('liquid_glass_beta', value);
    setState(() {
      _liquidGlassEnabled = value;
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
      appBar: AppBar(
        title: const Text('界面与显示'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('外观'),
          ListTile(
            title: const Text('深色模式'),
            subtitle: Text(_getThemeModeText(themeModeIndex)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(themeModeIndex),
          ),
          const Divider(),
          _buildSectionHeader('字体'),
          ListTile(
            title: const Text('字体样式'),
            subtitle: Text(fontName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFontPicker(currentFontFamily),
          ),
          const Divider(),
          _buildSectionHeader('实验性功能'),
          SwitchListTile(
            title: const Text('液态玻璃效果 (BETA)'),
            subtitle: const Text('开启后界面将呈现磨砂玻璃质感'),
            value: _liquidGlassEnabled,
            onChanged: (value) => _saveLiquidGlass(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
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

  void _showThemePicker(int currentIndex) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('跟随系统'),
                leading: Radio<int>(
                  value: 0,
                  groupValue: currentIndex,
                  onChanged: (v) {
                    _saveThemeMode(v!);
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  _saveThemeMode(0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('浅色模式'),
                leading: Radio<int>(
                  value: 1,
                  groupValue: currentIndex,
                  onChanged: (v) {
                    _saveThemeMode(v!);
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  _saveThemeMode(1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('深色模式'),
                leading: Radio<int>(
                  value: 2,
                  groupValue: currentIndex,
                  onChanged: (v) {
                    _saveThemeMode(v!);
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  _saveThemeMode(2);
                  Navigator.pop(context);
                },
              ),
            ],
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
            trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
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
