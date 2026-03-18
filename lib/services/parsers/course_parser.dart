import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'dart:convert';
import '../../models/course.dart';

class CourseParser {
  
  
  List<Course> parse(String source, int tableId) {
    if (source.isEmpty) return [];

    
    if (source.trim().startsWith('{')) {
      return _parseJson(source, tableId);
    }

    return _parseHtml(source, tableId);
  }

  
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
         
         
         
         
         
         
         final int startNodeOriginal = activity['startUnit'] ?? 1;
         final int endNodeOriginal = activity['endUnit'] ?? 1;
         final List<dynamic> weekIndexes = activity['weekIndexes'] ?? [];

         
         List<int> validWeeks = [];
         for(var w in weekIndexes) {
            if (w is int) {
                validWeeks.add(w);
            } else if (w is String) {
                final p = int.tryParse(w);
                if (p != null) validWeeks.add(p);
            }
         }

         
         List<_WeekRange> weekRanges = _convertWeeksToRanges(validWeeks);

         for (var range in weekRanges) {
           
           if (startNodeOriginal <= 5 && endNodeOriginal >= 6) {
              
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
                step: 5 - startNodeOriginal + 1,
                color: '#2196F3',
              ));
              
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
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    List<List<int>> clusters = [];
    List<int> currentCluster = [weeks[0]];
    
    for (int i = 1; i < weeks.length; i++) {
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        if (weeks[i] == weeks[i-1] + 1) {
             currentCluster.add(weeks[i]);
        } else {
             clusters.add(currentCluster);
             currentCluster = [weeks[i]];
        }
    }
    clusters.add(currentCluster);

    
    
    
    
    
    
    
    
    for (var list in clusters) {
       ranges.add(_WeekRange(list.first, list.last, 0)); 
    }
    
    return ranges;
  }

  List<Course> _parseHtml(String htmlSource, int tableId) {
    Document doc = html_parser.parse(htmlSource);

    Element? table = doc.getElementById("timetable");
    if (table == null) return [];

    List<Element> rows = table.querySelectorAll("tr");
    List<Course> rawList = [];

    
    for (int i = 1; i < rows.length; i++) {
      
      Element row = rows[i];
      int startNode = i; 
      
      List<Element> cells = row.querySelectorAll("td");
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      int dayOffset = 0;
      if (cells.length > 7) {
        dayOffset = 1;
      }

      for (int c = dayOffset; c < cells.length; c++) {
        int day = c - dayOffset + 1;
        if (day > 7) break; 

        Element cell = cells[c];
        
        
        
        
        List<Element> courseDivs = cell.querySelectorAll(".kbcontent");
        if (courseDivs.isEmpty) {
            
            
            
            if (cell.classes.contains('kbcontent')) {
                courseDivs = [cell];
            }
        }

        
        _parseCellContent(cell, day, startNode, rawList, tableId);
      }
    }

    return _mergeAdjacentCourses(rawList);
  }

  void _parseCellContent(Element cell, int day, int startNode, List<Course> list, int tableId) {
    
    
    
    
    

    
    
    
    

    
    List<Element> names = cell.querySelectorAll("font[onmouseover^='kbtc']"); 
    
    
    
    if (names.isEmpty) return;

    
    
    
    
    
    
    
    
    
    
    

    List<Element> weeks = cell.querySelectorAll("font[title='周次(节次)']");
    List<Element> rooms = cell.querySelectorAll("font[title='教室']");
    List<Element> teachers = cell.querySelectorAll("font[title='教师']");

    
    int count = names.length;
    for (int k = 0; k < count; k++) {
      String name = names[k].text.trim();
      String weekText = (k < weeks.length) ? weeks[k].text.trim() : "";
      String room = (k < rooms.length) ? rooms[k].text.trim() : "";
      String teacher = (k < teachers.length) ? teachers[k].text.trim() : "";

      
      List<int> weekRange = _parseWeeks(weekText);
      
      list.add(Course(
        courseName: name,
        day: day,
        room: room,
        teacher: teacher,
        startNode: startNode,
        step: 1, 
        startWeek: weekRange[0],
        endWeek: weekRange[1],
        type: 0, 
        color: '#2196F3', 
        tableId: tableId
      ));
    }
  }

  List<int> _parseWeeks(String weekText) {
    
    
    
    
    
    RegExp regExp = RegExp(r'\d+');
    Iterable<Match> matches = regExp.allMatches(weekText);
    if (matches.isEmpty) return [1, 16];
    
    int start = int.parse(matches.first.group(0)!);
    int end = int.parse(matches.last.group(0)!);
    
    return [start, end];
  }

  List<Course> _mergeAdjacentCourses(List<Course> rawList) {
    
    rawList.sort((a, b) {
      if (a.day != b.day) return a.day.compareTo(b.day);
      return a.startNode.compareTo(b.startNode);
    });

    List<Course> merged = [];
    
    for (var current in rawList) {
      bool handled = false;
      
      if (merged.isNotEmpty) {
        var last = merged.last;
        
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
  final int type; 
  _WeekRange(this.start, this.end, this.type);
}
