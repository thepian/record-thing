/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A bundle of widgets for the ThepiaApp app.
*/

import WidgetKit
import SwiftUI

@main
struct ThepiaAppWidgets: WidgetBundle {
    var body: some Widget {
        // Add widgets here
        EmptyWidget()
    }
}

struct EmptyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.thepia.empty", provider: EmptyProvider()) { entry in
            Text("No Widgets")
        }
        .configurationDisplayName("Thepia Widgets")
        .description("No widgets available yet.")
    }
}

struct EmptyProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entries = [SimpleEntry(date: Date())]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}
}
