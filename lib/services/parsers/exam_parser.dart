import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../../models/exam.dart';

class ExamParser {
  List<Exam> parse(String htmlSource) {
      if (htmlSource.isEmpty) return [];
      
      Document doc = html_parser.parse(htmlSource);
      List<Element> tables = doc.querySelectorAll("table");
      
      for (var table in tables) {
        List<Exam> exams = _tryParseTable(table);
        if (exams.isNotEmpty) return exams;
      }
      
      return [];
    }

    List<Exam> _tryParseTable(Element table) {
      List<Element> rows = table.querySelectorAll("tr");
      if (rows.length < 2) return [];

      int nameIdx = -1;
      int timeIdx = -1;
      int locIdx = -1;
      int seatIdx = -1; // If exists

      Element header = rows[0];
      List<Element> cols = header.querySelectorAll("th, td");
      
      for (int i = 0; i < cols.length; i++) {
          String txt = cols[i].text.trim();
          if (txt.contains("课程名称") || txt.contains("Course")) nameIdx = i;
          else if (txt.contains("时间") || txt.contains("Time")) timeIdx = i;
          else if (txt.contains("地点") || txt.contains("Location") || txt.contains("Room")) locIdx = i;
          else if (txt.contains("座") || txt.contains("Seat")) seatIdx = i;
      }

      if (nameIdx == -1 || timeIdx == -1) return [];

      List<Exam> result = [];
      for (int i = 1; i < rows.length; i++) {
        List<Element> cells = rows[i].querySelectorAll("td");
        if (cells.length < 3) continue;

        String name = _safeGet(cells, nameIdx);
        String time = _safeGet(cells, timeIdx);
        String loc = _safeGet(cells, locIdx);
        String seat = (seatIdx != -1) ? _safeGet(cells, seatIdx) : "";
        
        // Append seat to location if available
        if (seat.isNotEmpty) {
           loc = "$loc (座号: $seat)";
        }
        
        // Infer status/type if not present in columns (default strings)
        String type = "考试";
        String status = _inferStatus(time);

        result.add(Exam(
          courseName: name,
          timeString: time,
          location: loc,
          type: type,
          status: status
        ));
      }
      return result;
    }

    String _safeGet(List<Element> cells, int idx) {
      if (idx < 0 || idx >= cells.length) return "";
      return cells[idx].text.trim();
    }
    
    String _inferStatus(String timeStr) {
        // Simple heuristic: compare with current time?
        // Formatting might be tricky (2024-01-01 09:00~11:00)
        // For now, leave generic or implement parsing later.
        return "未开始"; 
    }
}
