import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysues/services/theme_service.dart';

class DisplaySettingsScreen extends StatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  State<DisplaySettingsScreen> createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends State<DisplaySettingsScreen> {
  // ThemeMode: 0 = System, 1 = Light, 2 = Dark
  // Now managed by ThemeService
  
  bool _liquidGlassEnabled = false;
  String _fontSelection = '默认';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _liquidGlassEnabled = prefs.getBool('liquid_glass_beta') ?? false;
      _fontSelection = prefs.getString('app_font') ?? '默认';
    });
  }

  Future<void> _saveThemeMode(int index) async {
    await ThemeService().updateThemeMode(index);
    // No need to setState regarding theme here, as global theme change will trigger rebuild of app
    // However, to update the UI on this screen immediately if it doesn't rebuild automatically:
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
            subtitle: Text(_fontSelection),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showFontPicker,
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

  void _showFontPicker() {
    // Mock font picker
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('默认'),
                onTap: () {
                  setState(() => _fontSelection = '默认');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('圆体 (Mock)'),
                onTap: () {
                  setState(() => _fontSelection = '圆体');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
