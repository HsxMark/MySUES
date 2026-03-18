import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/course.dart';

class ImportClassPdfScreen extends StatefulWidget {
  const ImportClassPdfScreen({super.key});

  @override
  State<ImportClassPdfScreen> createState() => _ImportClassPdfScreenState();
}

class _ImportClassPdfScreenState extends State<ImportClassPdfScreen> {
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _pickAndProcessPdf() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在选择文件...';
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: Platform.isAndroid ? FileType.any : FileType.custom,
        allowedExtensions: Platform.isAndroid ? null : ['pdf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        
        if (Platform.isAndroid && !file.path.toLowerCase().endsWith('.pdf')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('请选择 PDF 文件')),
            );
          }
          return;
        }

        setState(() {
          _statusMessage = '正在读取文件...';
        });

        final List<int> bytes = await file.readAsBytes();
        
        setState(() {
          _statusMessage = '正在解析内容...';
        });

        
        final List<Course> courses = await _extractAndParsePdf(bytes);

        if (!mounted) return;

        if (courses.isEmpty) {
           
           
           
           
        }
        
        Navigator.pop(context, courses);

      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
      }
    }
  }

  Future<List<Course>> _extractAndParsePdf(List<int> bytes) async {
    
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入课表 PDF'),
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage ?? '处理中...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf, size: 80, color: Colors.redAccent),
                  const SizedBox(height: 20),
                  const Text(
                    '请选择教务系统导出的课表PDF文件',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '注意，当前功能极不稳定，可能无法正确解析 PDF 文件。', 
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  FilledButton.icon(
                    onPressed: _pickAndProcessPdf,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('选择文件'),
                  ),
                ],
              ),
      ),
    );
  }
}
