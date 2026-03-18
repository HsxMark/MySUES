import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/score.dart';

class ImportPdfScreen extends StatefulWidget {
  const ImportPdfScreen({super.key});

  @override
  State<ImportPdfScreen> createState() => _ImportPdfScreenState();
}

class _ImportPdfScreenState extends State<ImportPdfScreen> {
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

        final List<Score> scores = await _extractAndParsePdf(bytes);

        if (!mounted) return;

        if (scores.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未能在PDF中找到有效的成绩数据')),
          );
        } else {
          
          Navigator.pop(context, scores);
        }
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

  Future<List<Score>> _extractAndParsePdf(List<int> bytes) async {
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    String text = PdfTextExtractor(document).extractText();
    document.dispose();

    return _parseTranscriptTextStream(text);
  }

  
  List<Score> _parseTranscriptTextStream(String text) {
    List<Score> scores = [];
    
    
    
    text = text.replaceAll(RegExp(r'第\s*\d+\s*页\s*共\s*\d+\s*页'), '');
    text = text.replaceAll(RegExp(r'\d{4}年\d{2}月\d{2}日'), '');
    text = text.replaceAll(RegExp(r'留学生专用'), '');
    text = text.replaceAll(RegExp(r'学院：.*'), '');
    text = text.replaceAll(RegExp(r'姓名：.*'), '');
    
    
    
    int columnCount = 4; 
    
    
    
    
    final semesterPattern = RegExp(r'(?:第[一二三四五]学年)?\((\d{4}\.\d{2}--\d{4}\.\d{2})\)');
    List<String> detectedSemesters = [];
    
    final lines = text.split('\n');
    for (var line in lines) {
       final matches = semesterPattern.allMatches(line);
       for (var m in matches) {
           detectedSemesters.add(m.group(0)!);
       }
       
       
       int headerCount = '课程'.allMatches(line).length;
       if (headerCount > 1) {
           columnCount = headerCount;
       }
    }
    
    
    if (detectedSemesters.isEmpty) detectedSemesters.add("未知学期");
    
    
    
    final dataBlockPattern = RegExp(r'(\d+(?:\.\d+)?)\s+(\d+)\s+([A-Z][+-]?|\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)');
    final blankPattern = RegExp(r'以下空白');
    
    
    int currentIndex = 0;
    int currentSemesterIndex = 0; 
    
    List<String> activeSemesters = [...detectedSemesters];
    
    while (activeSemesters.length < columnCount) {
        activeSemesters.add(activeSemesters.lastOrNull ?? "未知学期");
    }
    
    
    final allMatches = dataBlockPattern.allMatches(text).toList();
    
    int lastMatchEnd = 0;
    
    for (int i = 0; i < allMatches.length; i++) {
      final match = allMatches[i];
      
      
      String gap = text.substring(lastMatchEnd, match.start);
      
      
      
      int blankStart = 0;
      while (true) {
        final blankMatch = blankPattern.firstMatch(gap.substring(blankStart));
        if (blankMatch == null) break;
        
        
        currentSemesterIndex++;
        
        
        
        int relativeEnd = blankStart + blankMatch.end; 
        String afterBlank = gap.substring(relativeEnd);
        
        if (afterBlank.trimLeft().startsWith('\n') || afterBlank.trim().isEmpty && i < allMatches.length ) {
             
             
             if (afterBlank.contains('\n')) {
                 
                 while (currentSemesterIndex % columnCount != 0) {
                     currentSemesterIndex++;
                 }
             }
        }
        
        blankStart += blankMatch.end;
      }
      
      
      String rawName = gap;
      int lastBlankIndex = gap.lastIndexOf('以下空白');
      if (lastBlankIndex != -1) {
          rawName = gap.substring(lastBlankIndex + 4);
      }
      
      
      String courseName = rawName.trim();
      
      
      if (courseName.contains("课程") && courseName.contains("学分")) {
          
          int headerIdx = courseName.lastIndexOf("绩点");
          if (headerIdx != -1) {
              courseName = courseName.substring(headerIdx + 2).trim();
          }
      }
      
      
      if (courseName.isNotEmpty) {

          String semesterName = _findSemesterForColumn(text, match.start, currentSemesterIndex % columnCount, detectedSemesters, columnCount);
          
          Score score = _createScore(courseName, match, semesterName);
          scores.add(score);
      }
      
      lastMatchEnd = match.end;
      currentSemesterIndex++;
    }

    return scores;
  }
  
  
  String _findSemesterForColumn(String text, int position, int columnIndex, List<String> allSemesters, int columnCount) {
      
      String preText = text.substring(0, position);
      
      
      final pattern = RegExp(r'(?:第[一二三四五]学年)?\((\d{4}\.\d{2}--\d{4}\.\d{2})\)');
      final matches = pattern.allMatches(preText).toList();
      
      if (matches.isEmpty) {
          return allSemesters.isNotEmpty ? allSemesters[columnIndex % allSemesters.length] : "未知学期";
      }
      
      
      int count = matches.length;
      if (count == 0) return "未知学期";
      
      
      
      int startIdx = (count - 1) ~/ columnCount * columnCount;
      
      
      if (startIdx + columnIndex < count) {
          return matches.elementAt(startIdx + columnIndex).group(0)!;
      } else {
          
          return matches.last.group(0)!;
      }
  }
  
  bool _isValidCourseName(String name) {
      if (name.contains("课程") && name.contains("学分")) return false;
      if (name.trim() == "以下空白") return false;
      if (name.trim().isEmpty) return false;
      return true;
  }

  Score _createScore(String name, RegExpMatch match, String semester) {
      name = name.replaceAll("以下空白", "").trim();
      
      double credit = double.tryParse(match.group(1)!) ?? 0.0;
      double gradePoint = double.tryParse(match.group(4)!) ?? 0.0;
      
      return Score(
          courseName: name,
          credit: credit,
          gradePoint: gradePoint, 
          semester: semester,
      );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('导入成绩单'),
      ),
      body: _isLoading 
        ? Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_statusMessage ?? '处理中...'),
                ],
            ),
        )
        : Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.picture_as_pdf,
              size: 80,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 24),
            const Text(
              '请登录教务系统，选择综合服务-自助打印-中文留学成绩，将下载好的 PDF 导入',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '注意：导入会覆盖当前的所有内容且无法回退',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _pickAndProcessPdf,
              icon: const Icon(Icons.upload_file),
              label: const Text('选择文件'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
