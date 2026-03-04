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
        // Android 上 FileType.custom 结合 allowedExtensions 可能会导致部分机型无响应
        // 改为 FileType.any 并在代码中校验扩展名
        type: Platform.isAndroid ? FileType.any : FileType.custom,
        allowedExtensions: Platform.isAndroid ? null : ['pdf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        
        // Android 手动检查后缀名
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
          // 成功解析，返回数据
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

  /// 使用流式处理来解析复杂的PDF文本
  List<Score> _parseTranscriptTextStream(String text) {
    List<Score> scores = [];
    
    // 1. 预处理：移除页眉页脚等干扰信息
    // 移除 "第 x 页 共 y 页", 日期, "留学生专用"
    text = text.replaceAll(RegExp(r'第\s*\d+\s*页\s*共\s*\d+\s*页'), '');
    text = text.replaceAll(RegExp(r'\d{4}年\d{2}月\d{2}日'), '');
    text = text.replaceAll(RegExp(r'留学生专用'), '');
    text = text.replaceAll(RegExp(r'学院：.*'), '');
    text = text.replaceAll(RegExp(r'姓名：.*'), '');
    
    // 2. 识别列数和学期表头
    // 查找包含 "课程" "学分" 重复出现的行，确定列数
    int columnCount = 4; // 默认为4列，常见格式
    
    // 尝试找学期定义
    // 简单策略：按顺序收集所有出现的学年学期字符串，存入列表
    // 比如：第一学年(2023.09--2024.01)
    final semesterPattern = RegExp(r'(?:第[一二三四五]学年)?\((\d{4}\.\d{2}--\d{4}\.\d{2})\)');
    List<String> detectedSemesters = [];
    
    final lines = text.split('\n');
    for (var line in lines) {
       final matches = semesterPattern.allMatches(line);
       for (var m in matches) {
           detectedSemesters.add(m.group(0)!);
       }
       
       // 检测列数
       int headerCount = '课程'.allMatches(line).length;
       if (headerCount > 1) {
           columnCount = headerCount;
       }
    }
    
    // 如果没有检测到足够的学期头，就循环使用
    if (detectedSemesters.isEmpty) detectedSemesters.add("未知学期");
    
    // 3. 流式解析课程
    // 正则匹配课程数据块: 学分(float) 学时(int) 成绩(str) 绩点(float)
    final dataBlockPattern = RegExp(r'(\d+(?:\.\d+)?)\s+(\d+)\s+([A-Z][+-]?|\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)');
    final blankPattern = RegExp(r'以下空白');
    
    // 我们需要一个游标来遍历文本
    int currentIndex = 0;
    int currentSemesterIndex = 0; // 0..columnCount-1
    
    List<String> activeSemesters = [...detectedSemesters];
    // 确保至少有 columnCount 个
    while (activeSemesters.length < columnCount) {
        activeSemesters.add(activeSemesters.lastOrNull ?? "未知学期");
    }
    
    // 查找所有数据块匹配
    final allMatches = dataBlockPattern.allMatches(text).toList();
    
    int lastMatchEnd = 0;
    
    for (int i = 0; i < allMatches.length; i++) {
      final match = allMatches[i];
      
      // 获取两个匹配之间的文本 (Gap)
      String gap = text.substring(lastMatchEnd, match.start);
      
      // 3.1 处理 Gap 中的 "以下空白" 和 换行
      // 我们在 gap 中查找 "以下空白"
      int blankStart = 0;
      while (true) {
        final blankMatch = blankPattern.firstMatch(gap.substring(blankStart));
        if (blankMatch == null) break;
        
        // 找到一个空白，跳过一个学期
        currentSemesterIndex++;
        
        // 检查这个空白后面是否紧跟换行 (意味着这一行结束，后面都是空白)
        // 绝对索引
        int relativeEnd = blankStart + blankMatch.end; // inside gap substring
        String afterBlank = gap.substring(relativeEnd);
        
        if (afterBlank.trimLeft().startsWith('\n') || afterBlank.trim().isEmpty && i < allMatches.length ) {
             // 如果是行末空白，填充剩余列直到换行
             // 怎么判断是行末？看 gap 后续是否有换行符
             if (afterBlank.contains('\n')) {
                 // 填充直到下一行起始 (idx % col == 0)
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
      
      // 清理 rawName
      String courseName = rawName.trim();
      
      // 如果包含表头 "课程 学分..."，剔除之
      if (courseName.contains("课程") && courseName.contains("学分")) {
          // 找到最后一个表头关键字的位置，取其后的内容
          int headerIdx = courseName.lastIndexOf("绩点");
          if (headerIdx != -1) {
              courseName = courseName.substring(headerIdx + 2).trim();
          }
      }
      
      // 如果名字是空的，可能是异常情况或者 parsing 错位
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
  
  // 根据当前位置和列索引找到对应的学期名
  String _findSemesterForColumn(String text, int position, int columnIndex, List<String> allSemesters, int columnCount) {
      // 截取当前位置之前的文本
      String preText = text.substring(0, position);
      
      // 查找所有 header 的位置
      final pattern = RegExp(r'(?:第[一二三四五]学年)?\((\d{4}\.\d{2}--\d{4}\.\d{2})\)');
      final matches = pattern.allMatches(preText).toList();
      
      if (matches.isEmpty) {
          return allSemesters.isNotEmpty ? allSemesters[columnIndex % allSemesters.length] : "未知学期";
      }
      
      
      int count = matches.length;
      if (count == 0) return "未知学期";
      
      // 找到这一页的起始 header index
      // 假设每页也是 columnCount 个 header
      int startIdx = (count - 1) ~/ columnCount * columnCount;
      
      // 如果 startIdx + columnIndex 存在
      if (startIdx + columnIndex < count) {
          return matches.elementAt(startIdx + columnIndex).group(0)!;
      } else {
          // Fallback
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
