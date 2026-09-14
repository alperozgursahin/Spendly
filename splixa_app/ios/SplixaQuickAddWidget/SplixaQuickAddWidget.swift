import SwiftUI
import WidgetKit

struct SplixaQuickAddEntry: TimelineEntry {
    let date: Date
    let isPro: Bool
}

struct SplixaQuickAddProvider: TimelineProvider {
    func placeholder(in context: Context) -> SplixaQuickAddEntry {
        SplixaQuickAddEntry(date: Date(), isPro: true)
    }
    func getSnapshot(in context: Context, completion: @escaping (SplixaQuickAddEntry) -> Void) {
        completion(entry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SplixaQuickAddEntry>) -> Void) {
        completion(Timeline(entries: [entry()], policy: .never))
    }
    private func entry() -> SplixaQuickAddEntry {
        let defaults = UserDefaults(suiteName: "group.net.splixa.app")
        return SplixaQuickAddEntry(date: Date(), isPro: defaults?.bool(forKey: "is_pro") ?? false)
    }
}

struct SplixaQuickAddView: View {
    let entry: SplixaQuickAddEntry
    var body: some View {
        Link(destination: URL(string: "splixa://quick-add")!) {
            VStack(spacing: 8) {
                Text("Splixa").font(.headline).bold()
                Text(entry.isPro ? "+ Quick Add" : "Unlock with Pro").font(.caption)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

@main
struct SplixaQuickAddWidget: Widget {
    let kind = "SplixaQuickAddWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SplixaQuickAddProvider()) { entry in
            SplixaQuickAddView(entry: entry)
        }
        .configurationDisplayName("Splixa Quick Add")
        .description("Open Splixa and add an expense.")
        .supportedFamilies([.systemSmall])
    }
}
