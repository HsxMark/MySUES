import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../../models/score.dart';

class ScoreParser {
  List<Score> parse(String htmlSource) {
    if (htmlSource.isEmpty) return [];
    
    Document doc = html_parser.parse(htmlSource);
    // Usually one main table. If multiple, assume the largest one or one with relevant headers.
    List<Element> tables = doc.querySelectorAll("table");
    
    for (var table in tables) {
      List<Score> scores = _tryParseTable(table);
      if (scores.isNotEmpty) return scores;
    }
    
    return [];
  }

  List<Score> _tryParseTable(Element table) {
    List<Element> rows = table.querySelectorAll("tr");
    if (rows.length < 2) return [];

    // Identify indices
    int nameIdx = -1;
    int creditIdx = -1;
    int scoreIdx = -1;
    int gpaIdx = -1;
    int semIdx = -1;

    // Check header
    Element header = rows[0];
    List<Element> cols = header.querySelectorAll("th, td"); // Sometimes headers are td
    
    for (int i = 0; i < cols.length; i++) {
        String txt = cols[i].text.trim();
        if (txt.contains("课程名称") || txt.contains("Course")) nameIdx = i;
        else if (txt.contains("学分") || txt.contains("Credit")) creditIdx = i;
        else if (txt.contains("成绩") || txt.contains("Score")) scoreIdx = i; // Be careful of "最终成绩" vs "平时成绩"
        else if (txt.contains("绩点") || txt.contains("GPA")) gpaIdx = i;
        else if (txt.contains("学期") || txt.contains("Semester")) semIdx = i;
    }

    if (nameIdx == -1 || scoreIdx == -1) return []; // Essential columns missing

    List<Score> result = [];
    for (int i = 1; i < rows.length; i++) {
      List<Element> cells = rows[i].querySelectorAll("td");
      if (cells.length != cols.length && cells.length < 5) continue; // Mismatch or too few

      // Allow for colspans or slight variations if robust index used
      try {
        String name = _safeGet(cells, nameIdx);
        String sem = (semIdx != -1) ? _safeGet(cells, semIdx) : "";
        double credit = double.tryParse(_safeGet(cells, creditIdx)) ?? 0.0;
        double gpa = double.tryParse(_safeGet(cells, gpaIdx)) ?? 0.0;
        
        String scoreStr = _safeGet(cells, scoreIdx);
        double score = double.tryParse(scoreStr) ?? 0.0;
        // Handle "优", "良", "Pass" etc? For now 0.0 or convert custom logic
        if (score == 0.0 && scoreStr.isNotEmpty) {
           if (scoreStr.contains("优")) score = 95;
           else if (scoreStr.contains("良")) score = 85;
           else if (scoreStr.contains("中")) score = 75;
           else if (scoreStr.contains("及")) score = 65;
           else if (scoreStr.contains("不")) score = 0;
           else if (scoreStr.toLowerCase().contains("p")) score = 100; // Pass
        }

        result.add(Score(
          courseName: name,
          credit: credit,
          score: score,
          gradePoint: gpa,
          semester: sem
        ));
      } catch (e) {
        // Skip row
      }
    }
    return result;
  }

  String _safeGet(List<Element> cells, int idx) {
    if (idx < 0 || idx >= cells.length) return "";
    return cells[idx].text.trim();
  }
}
