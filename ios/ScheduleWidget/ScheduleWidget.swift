import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(),  title: "3.12 周四", week: "第 1 周", courses: [
            CourseEntry(name: "测试课程", time: "22:30", endTime: "22:50", loc: "实训楼 王俊烨", colorIdx: 0),
            CourseEntry(name: "课程2", time: "23:00", endTime: "23:30", loc: "交通楼12 张三", colorIdx: 1)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.hsxmark.mysues")
        let title = sharedDefaults?.string(forKey: "title") ?? "今日无课"
        let week = sharedDefaults?.string(forKey: "week") ?? ""
        let updateDateStr = sharedDefaults?.string(forKey: "updateDate") ?? ""
        
        let allCourses = loadAllCourses(from: sharedDefaults)
        
        let now = Date()
        let calendar = Calendar.current
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: now)
        
        // Build timeline entries: one for now, and one after each course ends
        var entries: [SimpleEntry] = []
        
        if !updateDateStr.isEmpty && updateDateStr != todayStr {
            entries.append(SimpleEntry(date: now, title: "请打开APP更新课表", week: "", courses: []))
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
            return
        }
        
        // Collect unique end-time dates (today) for courses that haven't ended yet
        var refreshDates: [Date] = [now]
        for course in allCourses {
            if let endDate = todayDate(from: course.endTime, calendar: calendar), endDate > now {
                refreshDates.append(endDate)
            }
        }
        refreshDates.sort()
        // Remove duplicates
        refreshDates = refreshDates.reduce(into: []) { result, date in
            if result.last != date { result.append(date) }
        }
        
        for date in refreshDates {
            let remaining = allCourses.filter { course in
                guard let endDate = todayDate(from: course.endTime, calendar: calendar) else {
                    return true // Can't determine end time, keep it
                }
                return endDate > date
            }
            let reindexed = remaining.enumerated().map { (idx, c) in
                CourseEntry(name: c.name, time: c.time, endTime: c.endTime, loc: c.loc, colorIdx: idx % 2)
            }
            entries.append(SimpleEntry(date: date, title: title, week: week, courses: reindexed))
        }
        
        // After all courses end, show empty state
        if let lastEnd = allCourses.compactMap({ todayDate(from: $0.endTime, calendar: calendar) }).max(), lastEnd > now {
            entries.append(SimpleEntry(date: lastEnd, title: title, week: week, courses: []))
        }
        
        if entries.isEmpty {
            entries.append(SimpleEntry(date: now, title: title, week: week, courses: []))
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    func loadAllCourses(from sharedDefaults: UserDefaults?) -> [CourseEntry] {
        var courses: [CourseEntry] = []
        for i in 1...8 {
            let name = sharedDefaults?.string(forKey: "course_\(i)_name") ?? ""
            if !name.isEmpty {
                let time = sharedDefaults?.string(forKey: "course_\(i)_time") ?? ""
                let endTime = sharedDefaults?.string(forKey: "course_\(i)_endtime") ?? ""
                let loc = sharedDefaults?.string(forKey: "course_\(i)_loc") ?? ""
                courses.append(CourseEntry(name: name, time: time, endTime: endTime, loc: loc, colorIdx: (i-1) % 2))
            }
        }
        return courses
    }
    
    func todayDate(from timeStr: String, calendar: Calendar) -> Date? {
        guard !timeStr.isEmpty else { return nil }
        let parts = timeStr.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date())
    }
    
    func loadData() -> SimpleEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.com.hsxmark.mysues")
        let title = sharedDefaults?.string(forKey: "title") ?? "今日无课"
        let week = sharedDefaults?.string(forKey: "week") ?? ""
        let updateDateStr = sharedDefaults?.string(forKey: "updateDate") ?? ""
        
        let now = Date()
        let calendar = Calendar.current
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: now)
        
        if !updateDateStr.isEmpty && updateDateStr != todayStr {
            return SimpleEntry(date: now, title: "请打开APP更新课表", week: "", courses: [])
        }
        
        let allCourses = loadAllCourses(from: sharedDefaults)
        let remaining = allCourses.filter { course in
            guard let endDate = todayDate(from: course.endTime, calendar: calendar) else { return true }
            return endDate > now
        }
        let reindexed = remaining.enumerated().map { (idx, c) in
            CourseEntry(name: c.name, time: c.time, endTime: c.endTime, loc: c.loc, colorIdx: idx % 2)
        }
        
        return SimpleEntry(date: now, title: title, week: week, courses: reindexed)
    }
}

struct CourseEntry: Hashable {
    let name: String
    let time: String
    let endTime: String
    let loc: String
    let colorIdx: Int
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let title: String
    let week: String
    let courses: [CourseEntry]
}

struct ScheduleWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        let maxCourses = family == .systemLarge ? 6 : 2
        let visibleCourses = Array(entry.courses.prefix(maxCourses))
        
        VStack(spacing: 0) {
            HStack {
                Text(entry.title)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Spacer()
                Text(entry.week)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 12)
            
            if visibleCourses.isEmpty {
                Spacer()
                Text("享受美好的空闲时光~")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                Spacer()
            } else {
                VStack(spacing: 8) {
                    ForEach(visibleCourses, id: \.self) { course in
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(course.colorIdx == 0 ? Color(red: 46/255, green: 204/255, blue: 113/255) : Color(red: 243/255, green: 156/255, blue: 18/255))
                                .frame(width: 3)
                                .cornerRadius(1.5)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(course.name)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(course.time)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                }
                                HStack {
                                    Text(course.loc)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(red: 170/255, green: 170/255, blue: 170/255))
                                    Spacer()
                                    Text(course.endTime)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(red: 170/255, green: 170/255, blue: 170/255))
                                }
                            }
                        }
                        .frame(height: 38)
                    }
                }
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground(Color(red: 28/255, green: 28/255, blue: 30/255))
    }
}

extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(color, for: .widget)
        } else {
            self.background(color)
        }
    }
}

struct ScheduleWidget: Widget {
    let kind: String = "ScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ScheduleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("课表小组件")
        .description("快速查看今日课表，让你不再错过任何一节课。")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}