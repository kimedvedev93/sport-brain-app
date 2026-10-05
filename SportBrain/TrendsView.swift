import SwiftUI
import Charts

struct TrendsView: View {
    @EnvironmentObject var store: DataStore
    @State private var days = 30

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("Период", selection: $days) {
                        Text("14 дн").tag(14)
                        Text("30 дн").tag(30)
                        Text("90 дн").tag(90)
                    }
                    .pickerStyle(.segmented)

                    if let a = store.analytics {
                        chart("HRV SDNN, мс", a.series(\.hrvSDNN, days: days), color: .green)
                        chart("Пульс покоя, уд/мин", a.series(\.restingHR, days: days), color: .red)
                        chart("Сон, ч", a.series(\.sleepHours, days: days), color: .indigo)
                        chart("Пульс во сне, уд/мин", a.series(\.avgSleepingHR, days: days), color: .pink)
                        loadChart(a)
                        chart("Вес, кг", a.series(\.weight, days: days), color: .orange)
                    } else {
                        ContentUnavailableView("Нет данных", systemImage: "chart.xyaxis.line")
                    }
                }
                .padding()
            }
            .refreshable { await store.refresh() }
            .navigationTitle("Динамика")
        }
    }

    @ViewBuilder
    private func chart(_ title: String, _ points: [ChartPoint], color: Color) -> some View {
        Card(title: title) {
            if points.count < 2 {
                Text("Мало данных за период.").foregroundStyle(.secondary)
            } else {
                let values = points.map(\.value)
                let lo = values.min() ?? 0
                let hi = values.max() ?? 1
                let pad = max((hi - lo) * 0.15, 1)
                Chart(points) { p in
                    LineMark(x: .value("Дата", p.date, unit: .day), y: .value(title, p.value))
                        .foregroundStyle(color)
                        .interpolationMethod(.monotone)
                    PointMark(x: .value("Дата", p.date, unit: .day), y: .value(title, p.value))
                        .foregroundStyle(color)
                        .symbolSize(18)
                }
                .chartYScale(domain: (lo - pad)...(hi + pad))
                .frame(height: 160)
                if let last = points.last {
                    Text("Последнее: \(Fmt.num(last.value, 1)) · среднее: \(Fmt.num(values.reduce(0, +) / Double(values.count), 1))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func loadChart(_ a: Analytics) -> some View {
        let ctl = a.series(\.ctl, days: days)
        let atl = a.series(\.atl, days: days)
        Card(title: "Фитнес (CTL) и усталость (ATL)") {
            if ctl.count < 2 {
                Text("Мало данных за период.").foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(ctl) { p in
                        LineMark(x: .value("Дата", p.date, unit: .day), y: .value("Значение", p.value),
                                 series: .value("Ряд", "CTL"))
                            .foregroundStyle(by: .value("Ряд", "Фитнес (CTL)"))
                    }
                    ForEach(atl) { p in
                        LineMark(x: .value("Дата", p.date, unit: .day), y: .value("Значение", p.value),
                                 series: .value("Ряд", "ATL"))
                            .foregroundStyle(by: .value("Ряд", "Усталость (ATL)"))
                    }
                }
                .frame(height: 180)
            }
        }
    }
}
