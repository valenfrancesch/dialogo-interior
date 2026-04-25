import SwiftUI
import WidgetKit

private let appGroupId = "group.dialogo_interior"
private let widgetKind = "DialogoLockScreenWidget"

struct DialogoLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: LockScreenProvider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Diálogo Interior")
        .description("Lectura o versículo destacado de hoy.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular,
        ])
    }
}

struct LockScreenEntry: TimelineEntry {
    let date: Date
    let title: String
    let bodyText: String
}

struct LockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenEntry {
        LockScreenEntry(date: Date(), title: "Jn 3, 16", bodyText: "Porque tanto amó Dios al mundo…")
    }

    func getSnapshot(in context: Context, completion: @escaping (LockScreenEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenEntry>) -> Void) {
        let entry = readEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readEntry() -> LockScreenEntry {
        let suite = UserDefaults(suiteName: appGroupId)
        let title = suite?.string(forKey: "lock_title") ?? "Diálogo Interior"
        let bodyText = suite?.string(forKey: "lock_body") ?? "Abre la app para leer el Evangelio de hoy."
        return LockScreenEntry(date: Date(), title: title, bodyText: bodyText)
    }
}

struct LockScreenWidgetEntryView: View {
    var entry: LockScreenEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .dialogoWidgetBackground()
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.8)
                Text(entry.bodyText)
                    .font(.caption2)
                    .lineLimit(4)
                    .minimumScaleFactor(0.7)
            }
        case .accessoryInline:
            Text(String("\(entry.title) — \(entry.bodyText)".prefix(80)))
                .font(.caption2)
                .minimumScaleFactor(0.6)
        case .accessoryCircular:
            Text(String(entry.title.prefix(3)))
                .font(.caption2.bold())
                .minimumScaleFactor(0.5)
        default:
            Text(entry.title)
        }
    }
}

private extension View {
    @ViewBuilder
    func dialogoWidgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) {
                Color.clear
            }
        } else {
            self
        }
    }
}
