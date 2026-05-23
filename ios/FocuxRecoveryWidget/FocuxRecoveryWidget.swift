import SwiftUI
import WidgetKit

private let widgetGroupId = "group.com.focux.focuxApp"

struct RecoveryEntry: TimelineEntry {
  let date: Date
  let score: Int
  let label: String
  let hint: String
  let steps: Int
}

struct RecoveryProvider: TimelineProvider {
  func placeholder(in context: Context) -> RecoveryEntry {
    RecoveryEntry(
      date: Date(), score: 82, label: "Prontidao alta",
      hint: "Sono e recuperacao favoraveis.", steps: 6420)
  }

  func getSnapshot(in context: Context, completion: @escaping (RecoveryEntry) -> Void) {
    completion(readEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<RecoveryEntry>) -> Void) {
    let entry = readEntry()
    completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800))))
  }

  private func readEntry() -> RecoveryEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    return RecoveryEntry(
      date: Date(),
      score: data?.integer(forKey: "recovery_score") ?? 0,
      label: data?.string(forKey: "recovery_label") ?? "Conecte seu wearable",
      hint: data?.string(forKey: "recovery_hint")
        ?? "Abra o Focux para sincronizar Apple Health.",
      steps: data?.integer(forKey: "steps") ?? 0
    )
  }
}

struct FocuxRecoveryWidgetEntryView: View {
  var entry: RecoveryProvider.Entry

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color(red: 0.07, green: 0.20, blue: 0.24), Color(red: 0.05, green: 0.14, blue: 0.17)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      VStack(alignment: .leading, spacing: 6) {
        Text("FOCUX")
          .font(.caption2.weight(.bold))
          .foregroundStyle(.white.opacity(0.55))
        Text(entry.score > 0 ? "\(entry.score)%" : "--")
          .font(.system(size: 34, weight: .black, design: .rounded))
          .foregroundStyle(.white)
        Text(entry.label)
          .font(.subheadline.weight(.bold))
          .foregroundStyle(.white.opacity(0.92))
          .lineLimit(1)
        Text(entry.hint)
          .font(.caption)
          .foregroundStyle(.white.opacity(0.72))
          .lineLimit(2)
        if entry.steps > 0 {
          Text("\(entry.steps.formatted()) passos hoje")
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.55))
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .padding(14)
    }
    .widgetURL(URL(string: "focux://saude"))
  }
}

@main
struct FocuxRecoveryWidget: Widget {
  let kind: String = "FocuxRecoveryWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: RecoveryProvider()) { entry in
      FocuxRecoveryWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Focux Prontidao")
    .description("Recovery score, sono e passos do dia.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
