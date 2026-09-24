import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysues/l10n/l10n.dart';
import 'package:mysues/models/student_info.dart';
import 'package:mysues/services/local_image_store.dart';
import 'package:mysues/utils/profile_preference_keys.dart';

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
  String? _gradeOverride;

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

    // Load Avatar
    final avatarFile = await LocalImageStore.avatar.load();
    if (mounted) {
      setState(() {
        _avatarFile = avatarFile;
      });
    }

    // Load Nickname
    setState(() {
      _nickname = prefs.getString(_nicknamePrefsKey) ?? '';
    });

    // Load Major (Priority: Prefs > Default/Calculated)
    final savedMajor = prefs.getString(_majorPrefsKey);
    if (savedMajor != null && savedMajor.isNotEmpty) {
      setState(() {
        _major = savedMajor;
      });
    }

    // Load College
    final savedCollege = prefs.getString(_collegePrefsKey);
    if (savedCollege != null && savedCollege.isNotEmpty) {
      setState(() {
        _college = savedCollege;
      });
    }

    // Load Class
    final savedClass = prefs.getString(_classPrefsKey);
    if (savedClass != null && savedClass.isNotEmpty) {
      setState(() {
        _className = savedClass;
      });
    }

    setState(() {
      _gradeOverride = prefs.getString(
        ProfilePreferenceKeys.gradeOverride(widget.studentId),
      );
    });
  }

  Future<void> _pickAndSaveAvatar() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      final pickedPath = result?.files.single.path;
      if (pickedPath != null) {
        final savedFile = await LocalImageStore.avatar.save(pickedPath);
        if (!mounted) return;
        setState(() {
          _avatarFile = savedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.avatarUploadFailedWithError('$e')),
          ),
        );
      }
    }
  }

  Future<void> _updateNickname() async {
    final TextEditingController controller = TextEditingController(
      text: _nickname,
    );
    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.changeNickname),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: context.l10n.enterANickname),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(context.l10n.save),
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
    final TextEditingController controller = TextEditingController(
      text: _major,
    );
    final String? newMajor = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.changeMajor),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: context.l10n.enterAMajor),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(context.l10n.save),
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
    final TextEditingController controller = TextEditingController(
      text: _college,
    );
    final String? newCollege = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.changeCollege),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: context.l10n.enterACollege),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(context.l10n.save),
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
    final TextEditingController controller = TextEditingController(
      text: _className,
    );
    final String? newClass = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.changeClass),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: context.l10n.enterAClassName),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(context.l10n.save),
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

  String _gradeLabel(String grade) {
    switch (grade) {
      case '1':
        return context.l10n.firstYear;
      case '2':
        return context.l10n.secondYear;
      case '3':
        return context.l10n.thirdYear;
      case '4':
        return context.l10n.fourthYear;
      default:
        return context.l10n.graduatedOrUnknown;
    }
  }

  Future<void> _updateGrade() async {
    final automaticGrade = StudentInfoHelper.calculateGradeNumber(
      widget.studentId,
    ).toString();
    final selectedGrade = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.changeYear),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'automatic'),
            child: Text(
              context.l10n.automaticYear(_gradeLabel(automaticGrade)),
            ),
          ),
          for (final grade in const ['1', '2', '3', '4', 'graduated'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, grade),
              child: Text(_gradeLabel(grade)),
            ),
        ],
      ),
    );

    if (selectedGrade == null) return;

    final prefs = await SharedPreferences.getInstance();
    final gradeOverrideKey = ProfilePreferenceKeys.gradeOverride(
      widget.studentId,
    );
    if (selectedGrade == 'automatic') {
      await prefs.remove(gradeOverrideKey);
      if (!mounted) return;
      setState(() => _gradeOverride = null);
    } else {
      await prefs.setString(gradeOverrideKey, selectedGrade);
      if (!mounted) return;
      setState(() => _gradeOverride = selectedGrade);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profile3), centerTitle: true),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildAvatarItem(),
          const Divider(),
          _buildInfoItem(
            label: context.l10n.name,
            value: widget.name,
            isEditable: false,
          ),
          const Divider(),
          _buildInfoItem(
            label: context.l10n.studentID,
            value: widget.studentId,
            isEditable: false,
          ),
          const Divider(),
          _buildInfoItem(
            label: context.l10n.nickname,
            value: (_nickname == null || _nickname!.isEmpty)
                ? context.l10n.notSet
                : _nickname!,
            isEditable: true,
            onTap: _updateNickname,
          ),
          const Divider(),
          _buildInfoItem(
            label: context.l10n.college,
            value: (_college.isEmpty) ? context.l10n.notSet : _college,
            isEditable: true,
            onTap: _updateCollege,
          ),
          const Divider(),
          _buildInfoItem(
            label: context.l10n.major,
            value: _major,
            isEditable: true,
            onTap: _updateMajor,
          ),
          const Divider(),
          _buildInfoItem(
            label: context.l10n.classLabel,
            value: (_className.isEmpty) ? context.l10n.notSet : _className,
            isEditable: true,
            onTap: _updateClass,
          ),
          const Divider(),
          _buildInfoItem(
            label: context.l10n.year,
            value: _gradeOverride == null
                ? context.l10n.automaticYear(
                    _gradeLabel(
                      StudentInfoHelper.calculateGradeNumber(
                        widget.studentId,
                      ).toString(),
                    ),
                  )
                : _gradeLabel(_gradeOverride!),
            isEditable: true,
            onTap: _updateGrade,
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
            Text(context.l10n.avatar, style: TextStyle(fontSize: 16)),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  backgroundImage: _avatarFile != null
                      ? FileImage(_avatarFile!)
                      : null,
                  child: _avatarFile == null
                      ? Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: SvgPicture.asset(
                            'assets/images/sanxuanyi.svg',
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
                    color: isEditable
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey,
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
