import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditScreen extends StatefulWidget {
  final String name;
  final String studentId;
  final String defaultMajor;
  final String defaultCollege;
  final String defaultClass;

  const ProfileEditScreen({
    super.key,
    required this.name,
    required this.studentId,
    required this.defaultMajor,
    required this.defaultCollege,
    required this.defaultClass,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  File? _avatarFile;
  String? _nickname;
  late String _major;
  late String _college;
  late String _className;
  
  static const String _avatarPrefsKey = 'user_avatar_path';
  static const String _nicknamePrefsKey = 'user_nickname';
  static const String _majorPrefsKey = 'user_major';
  static const String _collegePrefsKey = 'user_college';
  static const String _classPrefsKey = 'user_class';

  @override
  void initState() {
    super.initState();
    _major = widget.defaultMajor;
    _college = widget.defaultCollege;
    _className = widget.defaultClass;
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    
    final avatarPath = prefs.getString(_avatarPrefsKey);
    if (avatarPath != null) {
      final file = File(avatarPath);
      if (await file.exists()) {
        setState(() {
          _avatarFile = file;
        });
      }
    }

    
    setState(() {
      _nickname = prefs.getString(_nicknamePrefsKey) ?? '';
    });

    
    final savedMajor = prefs.getString(_majorPrefsKey);
    if (savedMajor != null && savedMajor.isNotEmpty) {
      setState(() {
        _major = savedMajor;
      });
    }

    
    final savedCollege = prefs.getString(_collegePrefsKey);
    if (savedCollege != null && savedCollege.isNotEmpty) {
      setState(() {
        _college = savedCollege;
      });
    }

    
    final savedClass = prefs.getString(_classPrefsKey);
    if (savedClass != null && savedClass.isNotEmpty) {
      setState(() {
        _className = savedClass;
      });
    }
  }

  Future<void> _pickAndSaveAvatar() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        final File pickedFile = File(result.files.single.path!);
        
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = 'user_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File savedFile = await pickedFile.copy('${appDir.path}/$fileName');

        final prefs = await SharedPreferences.getInstance();
        final String? oldPath = prefs.getString(_avatarPrefsKey);
        if (oldPath != null) {
          final File oldFile = File(oldPath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        }
        
        await prefs.setString(_avatarPrefsKey, savedFile.path);

        setState(() {
          _avatarFile = savedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('头像上传失败: $e')),
        );
      }
    }
  }

  Future<void> _updateNickname() async {
    final TextEditingController controller = TextEditingController(text: _nickname);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改昵称'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '请输入昵称'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (newName != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nicknamePrefsKey, newName);
      setState(() {
        _nickname = newName;
      });
    }
  }

  Future<void> _updateMajor() async {
    final TextEditingController controller = TextEditingController(text: _major);
    final String? newMajor = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改专业'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '请输入专业名称'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (newMajor != null && newMajor.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_majorPrefsKey, newMajor.trim());
      setState(() {
        _major = newMajor.trim();
      });
    }
  }

  Future<void> _updateCollege() async {
    final TextEditingController controller = TextEditingController(text: _college);
    final String? newCollege = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改学院'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '请输入学院名称'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (newCollege != null && newCollege.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_collegePrefsKey, newCollege.trim());
      setState(() {
        _college = newCollege.trim();
      });
    }
  }

  Future<void> _updateClass() async {
    final TextEditingController controller = TextEditingController(text: _className);
    final String? newClass = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改班级'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '请输入班级名称'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (newClass != null && newClass.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_classPrefsKey, newClass.trim());
      setState(() {
        _className = newClass.trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildAvatarItem(),
          const Divider(),
          _buildInfoItem(label: '姓名', value: widget.name, isEditable: false),
          const Divider(),
          _buildInfoItem(label: '学号', value: widget.studentId, isEditable: false),
          const Divider(),
          _buildInfoItem(
            label: '昵称', 
            value: (_nickname == null || _nickname!.isEmpty) ? '未设置' : _nickname!,
            isEditable: true,
            onTap: _updateNickname,
          ),
          const Divider(),
          _buildInfoItem(
            label: '学院', 
            value: (_college.isEmpty) ? '未设置' : _college,
            isEditable: true,
            onTap: _updateCollege,
          ),
          const Divider(),
          _buildInfoItem(
            label: '专业', 
            value: _major,
            isEditable: true,
            onTap: _updateMajor,
          ),
          const Divider(),
          _buildInfoItem(
            label: '班级', 
            value: (_className.isEmpty) ? '未设置' : _className,
            isEditable: true,
            onTap: _updateClass,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarItem() {
    return InkWell(
      onTap: _pickAndSaveAvatar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('头像', style: TextStyle(fontSize: 16)),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                  child: _avatarFile == null
                      ? Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: SvgPicture.asset(
                            'assets/images/sues-single.svg',
                            fit: BoxFit.contain,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required String label, 
    required String value, 
    required bool isEditable,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isEditable ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isEditable ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey,
                  ),
                ),
                if (isEditable) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
