import SwiftUI

@main
struct SportBrainApp: App {
    @StateObject private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem { Label("Сегодня", systemImage: "heart.text.square") }
                .tag(0)
            TrendsView()
                .tabItem { Label("Динамика", systemImage: "chart.xyaxis.line") }
                .tag(1)
            ActivitiesView()
                .tabItem { Label("Тренировки", systemImage: "figure.outdoor.cycle") }
                .tag(2)
            DashboardView()
                .tabItem { Label("Панель", systemImage: "rectangle.grid.1x2") }
                .tag(3)
            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gearshape") }
                .tag(4)
        }
        .task {
            if !store.hasToken { tab = 4 } else { await store.refresh() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, store.hasToken {
                Task { await store.refresh() }
            }
        }
    }
}

/// Shared header: data freshness and errors.
struct StatusBanner: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let err = store.errorText {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
            if let a = store.analytics {
                if a.isStale {
                    Label("Данные от \(DateUtil.short(a.data.fetchedOn ?? "?")): обновление в GitHub ещё не прошло сегодня.",
                          systemImage: "clock.badge.exclamationmark")
                        .foregroundStyle(.orange)
                } else {
                    Text("Данные от \(DateUtil.short(a.data.fetchedOn ?? "?"))")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.footnote)
    }
}

struct Card<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    var note: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(value).font(.body.monospacedDigit().weight(.semibold))
                if let note {
                    Text(note).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}
