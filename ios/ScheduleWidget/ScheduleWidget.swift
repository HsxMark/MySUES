import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(),  title: "3.12 周四", week: "第 1 周", courses: [
            CourseEntry(name: "测试课程1", time: "08:15", endTime: "09:55", loc: "塔卫II 布拉施", colorIdx: 0, colorHex: "#2ECC71"),
            CourseEntry(name: "测试课程2", time: "13:20", endTime: "14:40", loc: "欧绍恩 布拉施", colorIdx: 1, colorHex: "#F39C12")
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.hsxmark.mysues")
        let now = Date()
        let calendar = Calendar.current
        let nextMidnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        let scheduleDay = loadScheduleDay(from: sharedDefaults, for: now)

        if hasScheduleCache(in: sharedDefaults), scheduleDay == nil {
            let entry = SimpleEntry(date: now, title: "请打开APP更新课表", week: "", courses: [])
            completion(Timeline(entries: [entry], policy: .atEnd))
            return
        }

        let title = scheduleDay?.title ?? sharedDefaults?.string(forKey: "title") ?? "今日无课"
        let week = scheduleDay?.week ?? sharedDefaults?.string(forKey: "week") ?? ""
        let allCourses = scheduleDay?.courses ?? loadAllCourses(from: sharedDefaults)

        // Build timeline entries: one for now, and one after each course ends
        var entries: [SimpleEntry] = []

        // Collect unique end-time dates (today) for courses that haven't ended yet
        var refreshDates: [Date] = [now]
        for course in allCourses {
            if let endDate = date(from: course.endTime, on: now, calendar: calendar), endDate > now {
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
                guard let endDate = self.date(from: course.endTime, on: date, calendar: calendar) else {
                    return true // Can't determine end time, keep it
                }
                return endDate > date
            }
            let reindexed = remaining.enumerated().map { (idx, c) in
                CourseEntry(name: c.name, time: c.time, endTime: c.endTime, loc: c.loc, colorIdx: idx % 2, colorHex: c.colorHex)
            }
            entries.append(SimpleEntry(date: date, title: title, week: week, courses: reindexed))
        }
        
        // After all courses end, show empty state
        if let lastEnd = allCourses.compactMap({ date(from: $0.endTime, on: now, calendar: calendar) }).max(), lastEnd > now {
            entries.append(SimpleEntry(date: lastEnd, title: title, week: week, courses: []))
        }
        
        if entries.isEmpty {
            entries.append(SimpleEntry(date: now, title: title, week: week, courses: []))
        }
        
        let timeline = Timeline(entries: entries, policy: .after(nextMidnight))
        completion(timeline)
    }

    func hasScheduleCache(in sharedDefaults: UserDefaults?) -> Bool {
        guard let raw = sharedDefaults?.string(forKey: "schedule_days_v1"),
              let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let days = json["days"] as? [[String: Any]] else {
            return false
        }
        return !days.isEmpty
    }

    func loadScheduleDay(from sharedDefaults: UserDefaults?, for date: Date) -> ScheduleDay? {
        guard let raw = sharedDefaults?.string(forKey: "schedule_days_v1"),
              let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let days = json["days"] as? [[String: Any]] else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let targetDate = formatter.string(from: date)

        guard let day = days.first(where: { $0["date"] as? String == targetDate }) else {
            return nil
        }

        let coursesJson = day["courses"] as? [[String: Any]] ?? []
        let courses = coursesJson.enumerated().compactMap { (idx, rawCourse) -> CourseEntry? in
            guard let name = rawCourse["name"] as? String, !name.isEmpty else {
                return nil
            }
            return CourseEntry(
                name: name,
                time: rawCourse["time"] as? String ?? "",
                endTime: rawCourse["endTime"] as? String ?? "",
                loc: rawCourse["loc"] as? String ?? "",
                colorIdx: idx % 2,
                colorHex: rawCourse["color"] as? String
            )
        }

        return ScheduleDay(
            title: day["title"] as? String ?? "今日无课",
            week: day["week"] as? String ?? "",
            courses: courses
        )
    }
    
    func loadAllCourses(from sharedDefaults: UserDefaults?) -> [CourseEntry] {
        var courses: [CourseEntry] = []
        for i in 1...8 {
            let name = sharedDefaults?.string(forKey: "course_\(i)_name") ?? ""
            if !name.isEmpty {
                let time = sharedDefaults?.string(forKey: "course_\(i)_time") ?? ""
                let endTime = sharedDefaults?.string(forKey: "course_\(i)_endtime") ?? ""
                let loc = sharedDefaults?.string(forKey: "course_\(i)_loc") ?? ""
                let colorHex = sharedDefaults?.string(forKey: "course_\(i)_color")
                courses.append(CourseEntry(name: name, time: time, endTime: endTime, loc: loc, colorIdx: (i-1) % 2, colorHex: colorHex))
            }
        }
        return courses
    }
    
    func date(from timeStr: String, on date: Date, calendar: Calendar) -> Date? {
        guard !timeStr.isEmpty else { return nil }
        let parts = timeStr.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
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
            guard let endDate = date(from: course.endTime, on: now, calendar: calendar) else { return true }
            return endDate > now
        }
        let reindexed = remaining.enumerated().map { (idx, c) in
            CourseEntry(name: c.name, time: c.time, endTime: c.endTime, loc: c.loc, colorIdx: idx % 2, colorHex: c.colorHex)
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
    let colorHex: String?
}

struct ScheduleDay {
    let title: String
    let week: String
    let courses: [CourseEntry]
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

    private func courseBarColor(for course: CourseEntry) -> Color {
        if let parsed = parseHexColor(course.colorHex) {
            return parsed
        }
        return fallbackBarColor(for: course.colorIdx)
    }

    private func fallbackBarColor(for index: Int) -> Color {
        index == 0
            ? Color(red: 46/255, green: 204/255, blue: 113/255)
            : Color(red: 243/255, green: 156/255, blue: 18/255)
    }

    private func parseHexColor(_ rawHex: String?) -> Color? {
        guard var hex = rawHex?.trimmingCharacters(in: .whitespacesAndNewlines), !hex.isEmpty else {
            return nil
        }

        if hex.hasPrefix("#") {
            hex.removeFirst()
        }

        guard (hex.count == 6 || hex.count == 8), let value = UInt64(hex, radix: 16) else {
            return nil
        }

        let alpha: Double
        let red: Double
        let green: Double
        let blue: Double

        if hex.count == 8 {
            alpha = Double((value >> 24) & 0xFF) / 255.0
            red = Double((value >> 16) & 0xFF) / 255.0
            green = Double((value >> 8) & 0xFF) / 255.0
            blue = Double(value & 0xFF) / 255.0
        } else {
            alpha = 1.0
            red = Double((value >> 16) & 0xFF) / 255.0
            green = Double((value >> 8) & 0xFF) / 255.0
            blue = Double(value & 0xFF) / 255.0
        }

        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }

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
                                .fill(courseBarColor(for: course))
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
