import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class StudentInfoParser {
  
  Map<String, String> parse(String htmlSource) {
    if (htmlSource.isEmpty) return {};
    
    Document doc = html_parser.parse(htmlSource);
    Map<String, String> info = {};

    
    
    String wholeText = doc.body?.text ?? "";
    RegExp welcomeReg = RegExp(r"欢迎您[：:]?\s*([^\(]+)\((\d{8,})\)");
    Match? match = welcomeReg.firstMatch(wholeText);
    if (match != null) {
      info['name'] = match.group(1)?.trim() ?? "";
      info['studentId'] = match.group(2)?.trim() ?? "";
    }

    
    if (info.isEmpty) {
      _tryParseInfoTable(doc, info);
    }
    
    
    if (!info.containsKey('studentId')) {
        Element? idElem = doc.getElementById('xh') ?? doc.getElementById('studentId'); 
        
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
    
    
    
    if (!info.containsKey('major')) {
        
        RegExp majorReg = RegExp(r"专业[：:]\s*([^<\s&]+)"); 
        
        
    }

    return info;
  }

  void _tryParseInfoTable(Document doc, Map<String, String> info) {
      
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
