//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI
import WidgetKit

private struct WorktimeiOSEntry: TimelineEntry {
    let date: Date
}

private struct WorktimeiOSProvider: TimelineProvider {
    func placeholder(in _: Context) -> WorktimeiOSEntry {
        WorktimeiOSEntry(date: Date())
    }

    func getSnapshot(in _: Context, completion: @escaping (WorktimeiOSEntry) -> Void) {
        completion(WorktimeiOSEntry(date: Date()))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<WorktimeiOSEntry>) -> Void) {
        let entry = WorktimeiOSEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

private struct WorktimeiOSWidgetView: View {
    let entry: WorktimeiOSEntry

    var body: some View {
        Text("Worktime")
            .font(.headline)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}

struct WorktimeiOSWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WorktimeWidgetiOS", provider: WorktimeiOSProvider()) { entry in
            WorktimeiOSWidgetView(entry: entry)
        }
        .configurationDisplayName("Worktime")
        .description("Worktime widget")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
