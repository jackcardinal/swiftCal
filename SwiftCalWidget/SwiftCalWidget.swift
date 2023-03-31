//
//  SwiftCalWidget.swift
//  SwiftCalWidget
//
//  Created by Jack Cardinal on 3/22/23.
//

import WidgetKit
import SwiftUI
import CoreData

struct Provider: TimelineProvider {
    
    let viewContext = PersistenceController.shared.container.viewContext
    
    var dayFetchRequest: NSFetchRequest<Day> {
        let request = Day.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Day.date, ascending: true)]
        request.predicate = NSPredicate(format: "(date >= %@) AND (date <= %@)",
                                        Date().startOfCaledarWithPrefixDays as CVarArg,
                                        Date().endOfMonth as CVarArg)
        return request
    }
    
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), days: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> ()) {
        do {
            let days = try viewContext.fetch(dayFetchRequest)
            let entry = CalendarEntry(date: Date(), days: days)
            completion(entry)
            
        } catch {
            print("Widget failed to fetch days in snapshot")
        }
        
        
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        do {
            let days = try viewContext.fetch(dayFetchRequest)
            let entry = CalendarEntry(date: Date(), days: days)
            
            let timeline = Timeline(entries: [entry], policy: .after(.now.endOfDay))
            completion(timeline)
            
        } catch {
            print("Widget failed to fetch days in snapshot")
        }
 
    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let days: [Day]
}

struct SwiftCalWidgetEntryView : View {
    var entry: CalendarEntry
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    var body: some View {
        HStack {
            Link(destination: URL(string: "streak")!) {
                VStack {
                    Text("\(calculateStreakValue())")
                        .font(.system(size: 70, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        //.foregroundColor(streakValue > 0 ? .orange : .pink)
                    Text("Study Streak")
                        .font(.caption).bold()
                        .foregroundColor(.secondary)
                }
            }
            Link(destination: URL(string: "calendar")!) {
                VStack {
                    CalendarHeaderView(font: .caption)
                    
                    LazyVGrid(columns: columns) {
                        ForEach(entry.days) { day in
                            if day.date!.monthInt != Date().monthInt {
                                Text("")
                            } else {
                                Text(day.date!.formatted(.dateTime.day()))
                                    .foregroundColor(day.didStudy ? .orange : .secondary)
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        Circle()
                                            .foregroundColor(day.didStudy ? .orange.opacity(0.3) : .orange.opacity(0))
                                            .scaleEffect(2)
                                    }
                                    .padding(0.5)
                            }
                        }
                    }
                
                }
            }
            .padding(.leading)
        }
        .padding()
    }
    
    func calculateStreakValue() -> Int {
        guard !entry.days.isEmpty else { return 0}
        
        let nonFutureDays = entry.days.filter { $0.date!.dayInt <= Date().dayInt }
        
        var streakCount = 0
        
        for day in nonFutureDays.reversed() {
            if day.didStudy {
                streakCount += 1
            } else {
                if day.date!.dayInt != Date().dayInt {
                    break
                }
            }
        }
        
        return streakCount
        
    }
}

struct SwiftCalWidget: Widget {
    let kind: String = "SwiftCalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SwiftCalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Calendar Widget")
        .description("This shows your calendar")
    }
}

struct SwiftCalWidget_Previews: PreviewProvider {
    static var previews: some View {
        SwiftCalWidgetEntryView(entry: CalendarEntry(date: Date(), days: []))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
