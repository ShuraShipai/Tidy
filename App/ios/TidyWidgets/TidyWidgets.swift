import SwiftUI
import WidgetKit

private let tidyGroupID = "group.com.pinkshoe.tidy"

struct TidyStorageEntry: TimelineEntry {
  let date: Date
  let capacity: Int64
  let available: Int64
  let reviewable: Int64?
  let scannedAt: Date?

  static var empty: TidyStorageEntry {
    TidyStorageEntry(date: .now, capacity: 0, available: 0, reviewable: nil, scannedAt: nil)
  }
}

struct TidyStorageProvider: TimelineProvider {
  func placeholder(in context: Context) -> TidyStorageEntry { .empty }
  func getSnapshot(in context: Context, completion: @escaping (TidyStorageEntry) -> Void) {
    completion(read())
  }
  func getTimeline(in context: Context, completion: @escaping (Timeline<TidyStorageEntry>) -> Void) {
    completion(Timeline(entries: [read()], policy: .after(.now.addingTimeInterval(6 * 60 * 60))))
  }

  private func read() -> TidyStorageEntry {
    guard let defaults = UserDefaults(suiteName: tidyGroupID),
          let summary = defaults.dictionary(forKey: "tidy.widget.summary") else { return .empty }
    let capacity = (summary["capacityBytes"] as? NSNumber)?.int64Value ?? 0
    let available = (summary["availableBytes"] as? NSNumber)?.int64Value ?? 0
    let reviewable = (summary["reviewableBytes"] as? NSNumber)?.int64Value
    let scanTime = (summary["scannedAt"] as? NSNumber)?.doubleValue
    return TidyStorageEntry(date: Date(), capacity: capacity, available: available,
                            reviewable: reviewable,
                            scannedAt: scanTime.map { Date(timeIntervalSince1970: $0 / 1000) })
  }
}

struct TidyStorageWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: TidyStorageEntry

  private var used: Int64 { max(0, entry.capacity - entry.available) }
  private var fraction: Double? {
    guard entry.capacity > 0 else { return nil }
    return min(1, max(0, Double(used) / Double(entry.capacity)))
  }

  var body: some View {
    Group {
      if family == .systemSmall { small } else { medium }
    }
    .font(.system(size: 13, weight: .medium, design: .rounded))
    .foregroundStyle(Color(red: 0.20, green: 0.18, blue: 0.23))
    .containerBackground(for: .widget) {
      LinearGradient(colors: [Color(red: 0.97, green: 0.95, blue: 1), Color(red: 0.91, green: 0.86, blue: 0.98)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    .widgetURL(URL(string: "tidy:///home"))
  }

  private var small: some View {
    VStack(alignment: .leading, spacing: 6) {
      Label("Storage", systemImage: "externaldrive")
        .font(.system(size: 13, weight: .bold, design: .rounded))
      if entry.capacity > 0 {
        Text("\(format(used)) used").font(.system(size: 21, weight: .bold, design: .rounded)).minimumScaleFactor(0.72).lineLimit(1)
        Text("of \(format(entry.capacity))")
        Text(reviewableText).foregroundStyle(Color(red: 0.42, green: 0.20, blue: 0.72)).lineLimit(2)
      } else {
        Text("Open Tidy to update").font(.system(size: 17, weight: .bold, design: .rounded))
        Text("A current scan is needed")
      }
      Spacer(minLength: 0)
      Text(updatedText).font(.system(size: 9)).foregroundStyle(.secondary)
    }
    .padding(14)
  }

  private var medium: some View {
    HStack(spacing: 16) {
      ZStack {
        Circle().stroke(Color.white.opacity(0.75), lineWidth: 11)
        if let fraction {
          Circle().trim(from: 0, to: fraction).stroke(AngularGradient(colors: [.purple.opacity(0.55), .purple], center: .center), style: StrokeStyle(lineWidth: 11, lineCap: .round)).rotationEffect(.degrees(-90))
        }
        VStack(spacing: 1) {
          Text(entry.capacity > 0 ? format(used) : "—").font(.system(size: 18, weight: .heavy, design: .rounded))
          Text("used").font(.system(size: 10))
        }
      }
      .frame(width: 82, height: 82)
      VStack(alignment: .leading, spacing: 5) {
        Text("Storage").font(.system(size: 17, weight: .bold, design: .rounded))
        Text(entry.capacity > 0 ? "\(format(entry.available)) free of \(format(entry.capacity))" : "Open Tidy to update")
          .lineLimit(2).minimumScaleFactor(0.8)
        Text(reviewableText).foregroundStyle(Color(red: 0.42, green: 0.20, blue: 0.72)).lineLimit(2).minimumScaleFactor(0.8)
        Text(updatedText).font(.system(size: 9)).foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
    }
    .padding(16)
  }

  private var reviewableText: String {
    guard entry.capacity > 0 else { return "Scan to see reviewable items" }
    guard let reviewable = entry.reviewable else { return "Reviewable size unavailable" }
    return "\(format(reviewable)) ready to review"
  }

  private var updatedText: String {
    guard let scannedAt = entry.scannedAt else { return "No completed scan" }
    return "Scan \(scannedAt.formatted(date: .abbreviated, time: .omitted))"
  }

  private func format(_ bytes: Int64) -> String {
    let value = Double(bytes) / 1_073_741_824
    return String(format: "%.1f GB", value)
  }
}

@main
struct TidyStorageWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "com.example.tidy.storage", provider: TidyStorageProvider()) { entry in
      TidyStorageWidgetView(entry: entry)
    }
    .configurationDisplayName("Tidy Storage")
    .description("See your latest on-device storage summary.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
