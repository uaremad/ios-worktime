//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI
import WidgetKit

private struct WorktimeMacEntry: TimelineEntry {
    let date: Date
}

private struct WorktimeMacProvider: TimelineProvider {
    func placeholder(in _: Context) -> WorktimeMacEntry {
        WorktimeMacEntry(date: Date())
    }

    func getSnapshot(in _: Context, completion: @escaping (WorktimeMacEntry) -> Void) {
        completion(WorktimeMacEntry(date: Date()))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<WorktimeMacEntry>) -> Void) {
        let entry = WorktimeMacEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

private struct WorktimeMacWidgetView: View {
    let entry: WorktimeMacEntry

    var body: some View {
        Text("Worktime")
            .font(.headline)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}

struct WorktimeMacWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WorktimeWidgetMac", provider: WorktimeMacProvider()) { entry in
            WorktimeMacWidgetView(entry: entry)
        }
        .configurationDisplayName("Worktime")
        .description("Worktime widget")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
