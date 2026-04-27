import SwiftUI
import WidgetKit

private let appGroupId = "group.dialogo_interior"
private let lockScreenWidgetKind = "DialogoLockScreenWidget"
private let luzSolidWidgetKind = "DialogoLuzSmallSolidWidget"
private let purposeSolidWidgetKind = "DialogoPurposeSmallSolidWidget"
private let combinedSolidWidgetKind = "DialogoCombinedMediumSolidWidget"

struct DialogoLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: lockScreenWidgetKind, provider: LockScreenProvider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Diálogo Interior")
        .description("Lectura o versículo destacado de hoy.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

struct LockScreenEntry: TimelineEntry {
    let date: Date
    let luzTitle: String
    let luzBody: String
    let purposeText: String
}

struct LockScreenProvider: TimelineProvider {
    private let staleLuzTitle = "Luz del día"
    private let staleLuzBody = "Descubre lo que Dios te quiere decir hoy en Diálogo Interior."
    private let stalePurpose = "¿Qué propósito te guía hoy?"

    func placeholder(in context: Context) -> LockScreenEntry {
        LockScreenEntry(
            date: Date(),
            luzTitle: "Luz del día",
            luzBody: "Porque tanto amó Dios al mundo…",
            purposeText: "Amar mejor a mi prójimo."
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LockScreenEntry) -> Void) {
        completion(readEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let startOfTomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        let midnightSwitch = calendar.date(byAdding: .minute, value: 1, to: startOfTomorrow) ?? startOfTomorrow
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        let refreshAfter = min(nextHour, midnightSwitch)

        let entries = [
            readEntry(for: now),
            readEntry(for: midnightSwitch),
        ]
        completion(Timeline(entries: entries, policy: .after(refreshAfter)))
    }

    private func readEntry(for date: Date) -> LockScreenEntry {
        let suite = UserDefaults(suiteName: appGroupId)
        let lockTitle = suite?.string(forKey: "lock_title") ?? "Luz del día"
        let lockBody = suite?.string(forKey: "lock_body") ?? "Abre la app para leer el Evangelio de hoy."
        let purpose = suite?.string(forKey: "purpose") ?? ""
        let savedDate = suite?.string(forKey: "widget_date") ?? ""

        if isStale(savedDate: savedDate, comparedTo: date) {
            return LockScreenEntry(
                date: date,
                luzTitle: staleLuzTitle,
                luzBody: staleLuzBody,
                purposeText: stalePurpose
            )
        }
        let cleanPurpose = purpose.trimmingCharacters(in: .whitespacesAndNewlines)
        return LockScreenEntry(
            date: date,
            luzTitle: lockTitle,
            luzBody: lockBody,
            purposeText: cleanPurpose.isEmpty ? stalePurpose : cleanPurpose
        )
    }

    private func isStale(savedDate: String, comparedTo date: Date) -> Bool {
        if savedDate.isEmpty { return true }
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let todayKey = String(format: "%04d-%02d-%02d", year, month, day)
        return savedDate != todayKey
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
                Text(entry.luzTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.8)
                Text(entry.luzBody)
                    .font(.caption)
                    .lineLimit(4)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, -4)
        case .accessoryInline:
            Text(String("\(entry.luzTitle) — \(entry.luzBody)".prefix(80)))
                .font(.caption)
                .minimumScaleFactor(0.6)
        default:
            Text(entry.luzTitle)
        }
    }
}

struct DialogoLuzSmallSolidWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: luzSolidWidgetKind, provider: LockScreenProvider()) { entry in
            LuzSmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Luz del día (Sólido)")
        .description("Muestra la luz del Evangelio para hoy con fondo sólido.")
        .supportedFamilies([.systemSmall])
    }
}

struct DialogoPurposeSmallSolidWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: purposeSolidWidgetKind, provider: LockScreenProvider()) { entry in
            PurposeSmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Propósito del día (Sólido)")
        .description("Tu propósito de hoy en fondo sólido.")
        .supportedFamilies([.systemSmall])
    }
}

struct DialogoCombinedMediumSolidWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: combinedSolidWidgetKind, provider: LockScreenProvider()) { entry in
            CombinedMediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Luz y Propósito (Sólido)")
        .description("Luz del día y propósito del día en un solo widget con fondo sólido.")
        .supportedFamilies([.systemMedium])
    }
}

private struct LuzSmallWidgetView: View {
    let entry: LockScreenEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Luz del día")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(solidTitleColor(for: colorScheme))
            Text(entry.luzTitle)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(solidSubtitleColor(for: colorScheme))
            Text(luzContent)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(6)
                .minimumScaleFactor(0.75)
                .foregroundStyle(solidTextColor(for: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
        .dialogoSolidWidgetBackground(colorScheme: colorScheme)
    }

    private var luzContent: String {
        let trimmed = entry.luzBody.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Abre la app para leer el Evangelio de hoy." : trimmed
    }

}

private struct PurposeSmallWidgetView: View {
    let entry: LockScreenEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Propósito del día")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(solidTitleColor(for: colorScheme))
            Text(entry.purposeText)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(6)
                .minimumScaleFactor(0.75)
                .foregroundStyle(solidTextColor(for: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
        .dialogoSolidWidgetBackground(colorScheme: colorScheme)
    }
}

private struct CombinedMediumWidgetView: View {
    let entry: LockScreenEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Luz del día")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(solidTitleColor(for: colorScheme))
                Text(entry.luzTitle)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(solidSubtitleColor(for: colorScheme))
                Text(entry.luzBody)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(5)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(solidTextColor(for: colorScheme))
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.12))
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 6) {
                Text("Propósito del día")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(solidTitleColor(for: colorScheme))
                Text(entry.purposeText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(5)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(solidTextColor(for: colorScheme))
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
        .dialogoSolidWidgetBackground(colorScheme: colorScheme)
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

    @ViewBuilder
    func dialogoSolidWidgetBackground(colorScheme: ColorScheme = .light) -> some View {
        let backgroundColor = solidBackgroundColor(for: colorScheme)
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) {
                backgroundColor
            }
        } else {
            self.background(backgroundColor)
        }
    }
}

private func solidBackgroundColor(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color(red: 0.133, green: 0.110, blue: 0.094) : Color(red: 0.976, green: 0.965, blue: 0.941)
}

private func solidTitleColor(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color(red: 0.773, green: 0.627, blue: 0.349) : Color(red: 0.169, green: 0.094, blue: 0.063)
}

private func solidSubtitleColor(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color.white.opacity(0.72) : Color.black.opacity(0.65)
}

private func solidTextColor(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color.white.opacity(0.95) : Color.black.opacity(0.9)
}
