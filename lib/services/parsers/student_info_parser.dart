import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class StudentInfoParser {
  // Returns a map with 'name', 'studentId', 'major' if found
  Map<String, String> parse(String htmlSource) {
    if (htmlSource.isEmpty) return {};
    
    Document doc = html_parser.parse(htmlSource);
    Map<String, String> info = {};

    // Strategy 1: Look for "欢迎您" or "Welcome" text usually in top bar
    // Text often looks like "欢迎您：张三(012345678)"
    String wholeText = doc.body?.text ?? "";
    RegExp welcomeReg = RegExp(r"欢迎您[：:]?\s*([^\(]+)\((\d{8,})\)");
    Match? match = welcomeReg.firstMatch(wholeText);
    if (match != null) {
      info['name'] = match.group(1)?.trim() ?? "";
      info['studentId'] = match.group(2)?.trim() ?? "";
    }

    // Strategy 2: Look for input fields or table cells with labels
    if (info.isEmpty) {
      _tryParseInfoTable(doc, info);
    }
    
    // Strategy 3: Try getting from specific element ids often used
    if (!info.containsKey('studentId')) {
        Element? idElem = doc.getElementById('xh') ?? doc.getElementById('studentId'); 
        // sometimes labels are just text
        if (idElem != null) {
            if (idElem.localName == 'input') {
                info['studentId'] = idElem.attributes['value'] ?? "";
            } else {
                info['studentId'] = idElem.text.trim();
            }
        }
    }
    
    if (!info.containsKey('name')) {
        Element? nameElem = doc.getElementById('xm') ?? doc.getElementById('name');
        if (nameElem != null) {
             if (nameElem.localName == 'input') {
                info['name'] = nameElem.attributes['value'] ?? "";
            } else {
                info['name'] = nameElem.text.trim();
            }
        }
    }
    
    // Try to find Major
    // Labels: 专业, Major
    if (!info.containsKey('major')) {
        // Simple search for "专业：" followed by text
        RegExp majorReg = RegExp(r"专业[：:]\s*([^<\s&]+)"); 
        // This is weak against HTML structure. 
        // Let's rely on table parsing for major.
    }

    return info;
  }

  void _tryParseInfoTable(Document doc, Map<String, String> info) {
      // Look for tds containing "学号" and get the next td
      List<Element> cells = doc.querySelectorAll("td, th");
      for (int i = 0; i < cells.length; i++) {
          String text = cells[i].text.trim();
          if (text == "学号" || text == "Student ID") {
              if (i + 1 < cells.length) {
                  info['studentId'] = cells[i+1].text.trim();
              }
          } else if (text == "姓名" || text == "Name") {
              if (i + 1 < cells.length) {
                  info['name'] = cells[i+1].text.trim();
              }
          } else if (text == "专业" || text == "Major") {
              if (i + 1 < cells.length) {
                  info['major'] = cells[i+1].text.trim();
              }
          } else if (text == "院系" || text == "College") {
               if (i + 1 < cells.length) {
                  info['college'] = cells[i+1].text.trim();
              }
          }
      }
  }
}
