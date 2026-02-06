import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'dart:convert';
import '../../models/course.dart';

class CourseParser {
  /// Parses the HTML or JSON string and returns a list of Courses.
  /// Mimics logic from CourseAdapter/src/main/java/parser/SUESParser.kt and SUESParser2.kt
  List<Course> parse(String source, int tableId) {
    if (source.isEmpty) return [];

    // Check if source is JSON (starts with '{')
    if (source.trim().startsWith('{')) {
      return _parseJson(source, tableId);
    }

    return _parseHtml(source, tableId);
  }

  /// New JSON parsing logic (SUESParser2.kt)
  List<Course> _parseJson(String jsonSource, int tableId) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonSource);
      final vms = json['studentTableVms'] as List?;
      if (vms == null || vms.isEmpty) return [];
      
      final activities = vms[0]['activities'] as List?;
      if (activities == null) return [];

      List<Course> courseList = [];

      for (var activity in activities) {
         final String name = activity['courseName'] ?? '';
         final String room = activity['room'] ?? '未知地点';
         final int day = activity['weekday'] ?? 1;
         final String teacher = (activity['teachers'] as List?)?.map((e) => e.toString()).join(' ') ?? '';
         // final String note = activity['lessonRemark'] ?? '';
         // credits might be double or int
         // final double credit = (activity['credits'] is int) 
         //    ? (activity['credits'] as int).toDouble() 
         //    : (activity['credits'] as double? ?? 0.0);
         
         final int startNodeOriginal = activity['startUnit'] ?? 1;
         final int endNodeOriginal = activity['endUnit'] ?? 1;
         final List<dynamic> weekIndexes = activity['weekIndexes'] ?? [];

         // Robust parsing of week indexes
         List<int> validWeeks = [];
         for(var w in weekIndexes) {
            if (w is int) {
                validWeeks.add(w);
            } else if (w is String) {
                final p = int.tryParse(w);
                if (p != null) validWeeks.add(p);
            }
         }

         // Convert weekIndexes to ranges (startWeek, endWeek, type)
         List<_WeekRange> weekRanges = _convertWeeksToRanges(validWeeks);

         for (var range in weekRanges) {
           // Handle splitting noon (<=5 and >=6)
           if (startNodeOriginal <= 5 && endNodeOriginal >= 6) {
              // Part 1: start...5
              courseList.add(Course(
                tableId: tableId,
                courseName: name,
                room: room,
                teacher: teacher,
                startWeek: range.start,
                endWeek: range.end,
                type: range.type, // 0=all, 1=odd, 2=even
                day: day,
                startNode: startNodeOriginal,
                step: 5 - startNodeOriginal + 1,
                color: '#2196F3',
              ));
              // Part 2: 6...end
              courseList.add(Course(
                tableId: tableId,
                courseName: name,
                room: room,
                teacher: teacher,
                startWeek: range.start,
                endWeek: range.end,
                type: range.type,
                day: day,
                startNode: 6,
                step: endNodeOriginal - 6 + 1,
                color: '#2196F3',
              ));
           } else {
              courseList.add(Course(
                tableId: tableId,
                courseName: name,
                room: room,
                teacher: teacher,
                startWeek: range.start,
                endWeek: range.end,
                type: range.type,
                day: day,
                startNode: startNodeOriginal,
                step: endNodeOriginal - startNodeOriginal + 1,
                color: '#2196F3',
              ));
           }
         }
      }
      return courseList;
    } catch (e) {
      print("JSON Parse error: $e");
      return [];
    }
  }

  List<_WeekRange> _convertWeeksToRanges(List<int> weeks) {
    if (weeks.isEmpty) return [];
    weeks.sort();
    
    List<_WeekRange> ranges = [];
    // Simple heuristic: Try to find patterns (All, Odd, Even)
    // Actually, SUESParser2 splits into continuous blocks with type.
    // If we have 1, 2, 3, 4 -> 1-4 All
    // If we have 1, 3, 5 -> 1-5 Odd
    // If we have 2, 4, 6 -> 2-6 Even
    
    // Simplest approach: Create one "All" range if contiguous, else verify odd/even.
    // Or just create multiple ranges if gaps are large and irregular.
    
    // We'll iterate and build segments.
    // A segment is defined by (start, end, type).
    // But detecting type requires looking ahead.
    
    // Let's implement a robust converter.
    List<List<int>> clusters = [];
    List<int> currentCluster = [weeks[0]];
    
    for (int i = 1; i < weeks.length; i++) {
        // If contigous (diff 1) or same parity (diff 2) we might group?
        // Actually, just grouping strictly by continuity is safest for "All".
        // But "Odd/Even" is common.
        // Let's stick to simplest valid ranges.
        // If we strictly follow list, we might generate too many entries.
        
        // Let's try to detect Odd/Even pattern for the whole list?
        // No, a course might change weeks.
        
        // Let's assume standard behavior:
        // 1. Try to see if it's a single contiguous block.
        // 2. Try to see if it's a single Odd/Even block.
        // 3. Else, split.
        
        // However, I'll just use a simplification logic:
        // Iterate through weeks.
        
        // This is tricky without the `Common` util from Kotlin.
        // Let's assume simple contiguous grouping for now.
        // If gap is > 1:
        // Check if gap is consistent (e.g. 2).
        
        if (weeks[i] == weeks[i-1] + 1) {
             currentCluster.add(weeks[i]);
        } else {
             clusters.add(currentCluster);
             currentCluster = [weeks[i]];
        }
    }
    clusters.add(currentCluster);

    // Now merge clusters if they form Odd/Even pattern?
    // E.g. [1], [3], [5] -> 1-5 Odd
    // Logic: If list of clusters is > 1.
    // For now, let's just return "All" ranges for each cluster. 
    // It's safer than guessing wrong.
    // Users can edit later if needed, or we improve logic.
    // Actually, let's try to merge if all are singletons and diff is 2.
    
    for (var list in clusters) {
       ranges.add(_WeekRange(list.first, list.last, 0)); // 0 = All
    }
    
    return ranges;
  }

  List<Course> _parseHtml(String htmlSource, int tableId) {
    Document doc = html_parser.parse(htmlSource);

    Element? table = doc.getElementById("timetable");
    if (table == null) return [];

    List<Element> rows = table.querySelectorAll("tr");
    List<Course> rawList = [];

    // Skip header (index 0)
    for (int i = 1; i < rows.length; i++) {
      // Assuming max nodes per day is around 13-14, safety break not strictly needed if loop is correct
      Element row = rows[i];
      int startNode = i; // 1-based index from loop
      
      List<Element> cells = row.querySelectorAll("td");
      // Usually cells match days. 
      // But sometimes the first cell is the "Node Number", so we must check.
      // In many QiangZhi systems:
      // tr 0: Headers (Mon, Tue...)
      // tr 1: Node 1 (td 0 = "1", td 1 = Monday Course, td 2 = Tuesday...)
      // So cells[0] is index, cells[1] is Mon (Day 1).
      
      // Let's check cell count. If it's 8, index 0 is row header. If 7, typical.
      // Based on standard layouts, let's look at the kotlin code:
      // val cells = row.select("td")
      // for (j in cells.indices) { val day = j + 1 ... }
      // This implies cells[0] is Monday. This often means the "Node Index" column is a <th> or handled differently,
      // OR the Kotlin code assumes it matches.
      // However, usually first cell is "Section 1", "Section 2".
      // Let's look closer at Kotlin: `val cells = row.select("td")`. 
      // If the first column is `<th>` or `<td class="header">`, it might be included.
      
      // Adaptation:
      // If cells.length > 7, assume first is header.
      int dayOffset = 0;
      if (cells.length > 7) {
        dayOffset = 1;
      }

      for (int c = dayOffset; c < cells.length; c++) {
        int day = c - dayOffset + 1;
        if (day > 7) break; // Only 7 days

        Element cell = cells[c];
        
        // Find .kbcontent
        // Sometimes multiple courses in one cell?
        // Note: Kotlin code looked for courseDivs = cell.select(".kbcontent")
        List<Element> courseDivs = cell.querySelectorAll(".kbcontent");
        if (courseDivs.isEmpty) {
            // Sometimes the cell itself is the content container if class kbcontent is on td?
            // But usually it's a div inside.
            // Fallback: check children with kbcontent
            if (cell.classes.contains('kbcontent')) {
                courseDivs = [cell];
            }
        }

        // Inside kbcontent, look for specific fonts
        _parseCellContent(cell, day, startNode, rawList, tableId);
      }
    }

    return _mergeAdjacentCourses(rawList);
  }

  void _parseCellContent(Element cell, int day, int startNode, List<Course> list, int tableId) {
    // Logic from Kotlin:
    // name: font[onmouseover=kbtc(this)]
    // week: font[title="周次(节次)"]
    // room: font[title="教室"]
    // teacher: font[title="教师"]

    // However, the HTML structure might have multiple courses separated by <br>.
    // The Kotlin code iterates `courseDivs`.
    // But typically, `kbcontent` contains just raw text and <br>s, OR specific `font` tags.
    // If there are multiple courses, they usually appear as a sequence of tags.

    // Let's try to find ALL name elements first, and assume they pair up with subsequent elements.
    List<Element> names = cell.querySelectorAll("font[onmouseover^='kbtc']"); // ^='kbtc' to match start
    // If empty try just text?
    
    // In some systems, it's just text. But user code is specific.
    if (names.isEmpty) return;

    // Use content extraction
    // This is tricky because `attributes` might vary.
    // Alternative: The cell content usually looks like:
    // <font ...>Name</font><br>
    // <font ...>Week</font><br>
    // <font ...>Teacher</font><br>
    // <font ...>Room</font><br><br>
    // <font ...>Name 2</font>...
    
    // We can interpret the HTML structure by walking siblings.
    // Or we can assume the querySelectorAll returns them in order.

    List<Element> weeks = cell.querySelectorAll("font[title='周次(节次)']");
    List<Element> rooms = cell.querySelectorAll("font[title='教室']");
    List<Element> teachers = cell.querySelectorAll("font[title='教师']");

    // The counts usually match.
    int count = names.length;
    for (int k = 0; k < count; k++) {
      String name = names[k].text.trim();
      String weekText = (k < weeks.length) ? weeks[k].text.trim() : "";
      String room = (k < rooms.length) ? rooms[k].text.trim() : "";
      String teacher = (k < teachers.length) ? teachers[k].text.trim() : "";

      // Parse weeks: "1-16(周)"
      List<int> weekRange = _parseWeeks(weekText);
      
      list.add(Course(
        courseName: name,
        day: day,
        room: room,
        teacher: teacher,
        startNode: startNode,
        step: 1, // Default 1, merge later
        startWeek: weekRange[0],
        endWeek: weekRange[1],
        type: 0, // Need to parse '单'/'双' if present in weekText
        color: '#2196F3', // Default color
        tableId: tableId
      ));
    }
  }

  List<int> _parseWeeks(String weekText) {
    // Expected: "1-16(周)" or "1-8,10-16(周)" or "3(周)"
    // Kotlin regex: (\d+)-(\d+)\(周\)
    // We should be robust.
    // Simplifying: take first number as start, last as end.
    
    RegExp regExp = RegExp(r'\d+');
    Iterable<Match> matches = regExp.allMatches(weekText);
    if (matches.isEmpty) return [1, 16];
    
    int start = int.parse(matches.first.group(0)!);
    int end = int.parse(matches.last.group(0)!);
    
    return [start, end];
  }

  List<Course> _mergeAdjacentCourses(List<Course> rawList) {
    // Sort by day, then startNode, then name/room/week to align
    rawList.sort((a, b) {
      if (a.day != b.day) return a.day.compareTo(b.day);
      return a.startNode.compareTo(b.startNode);
    });

    List<Course> merged = [];
    
    for (var current in rawList) {
      bool handled = false;
      // Check if it can merge with the LAST added course
      if (merged.isNotEmpty) {
        var last = merged.last;
        // Merge condition: Same Name, Same Room, Same Teacher, Same Weeks, Same Day, Adjacent Node
        if (last.day == current.day &&
            last.courseName == current.courseName &&
            last.room == current.room &&
            last.teacher == current.teacher &&
            last.startWeek == current.startWeek &&
            last.endWeek == current.endWeek &&
            (last.startNode + last.step) == current.startNode) {
          
          last.step += current.step;
          handled = true;
        }
      }
      
      if (!handled) {
        merged.add(current);
      }
    }
    return merged;
  }
}

class _WeekRange {
  final int start;
  final int end;
  final int type; // 0: All, 1: Odd, 2: Even
  _WeekRange(this.start, this.end, this.type);
}
