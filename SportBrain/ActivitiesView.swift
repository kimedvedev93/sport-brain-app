import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        NavigationStack {
            List {
                if let acts = store.data?.activities, !acts.isEmpty {
                    ForEach(acts.reversed()) { act in
                        ActivityRow(activity: act)
                    }
                } else {
                    Text("Тренировок в данных нет.").foregroundStyle(.secondary)
                }
            }
            .refreshable { await store.refresh() }
            .navigationTitle("Тренировки")
        }
    }
}

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(activity.name ?? activity.type ?? "Тренировка").font(.body.weight(.semibold))
                Spacer()
                Text(DateUtil.short(activity.dayString)).foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Label(Fmt.minutes(activity.movingTime), systemImage: "clock")
                if let hr = activity.avgHR {
                    Label("\(Fmt.num(hr)) / \(Fmt.num(activity.maxHR))", systemImage: "heart")
                }
                if let l = activity.load {
                    Label("нагр. \(Fmt.num(l))", systemImage: "bolt")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if let hr = activity.avgHR, hr > 141, isEasyCandidate {
                Text("Средний пульс выше потолка лёгкой зоны 141 уд/мин (оценка).")
                    .font(.caption).foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 2)
    }

    /// Rides are mostly meant to be easy in the base block; flag them for a quick look.
    private var isEasyCandidate: Bool {
        (activity.type ?? "").contains("Ride")
    }
}
