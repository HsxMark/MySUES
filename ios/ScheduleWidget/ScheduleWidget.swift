import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(),  title: "测试课表标题 | 3.5 周四", week: "第 1 周", courses: [
            CourseEntry(name: "测试课程", time: "22:30", endTime: "22:50", loc: "实训楼 王俊烨", colorIdx: 0),
            CourseEntry(name: "课程2", time: "23:00", endTime: "23:30", loc: "交通楼12 张三", colorIdx: 1)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = loadData()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    func loadData() -> SimpleEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.com.hsxmark.mysues")
        let title = sharedDefaults?.string(forKey: "title") ?? "今日无课"
        let week = sharedDefaults?.string(forKey: "week") ?? ""
        
        var courses: [CourseEntry] = []
        for i in 1...6 {
            let name = sharedDefaults?.string(forKey: "course_\(i)_name") ?? ""
            if !name.isEmpty {
                let time = sharedDefaults?.string(forKey: "course_\(i)_time") ?? ""
                let endTime = sharedDefaults?.string(forKey: "course_\(i)_endtime") ?? ""
                let loc = sharedDefaults?.string(forKey: "course_\(i)_loc") ?? ""
                courses.append(CourseEntry(name: name, time: time, endTime: endTime, loc: loc, colorIdx: (i-1) % 2))
            }
        }
        
        return SimpleEntry(date: Date(), title: title, week: week, courses: courses)
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

    var body: some View {
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
            
            if entry.courses.isEmpty {
                Spacer()
                Text("享受美好的空闲时光~")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                Spacer()
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.courses, id: \.self) { course in
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