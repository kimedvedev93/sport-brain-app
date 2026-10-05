import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    StatusBanner()
                    if let a = store.analytics {
                        recovery(a)
                        loadCard(a)
                        adviceCard(a)
                        weightCard(a)
                        lastWorkout(a)
                    } else if !store.isLoading {
                        ContentUnavailableView("Нет данных",
                                               systemImage: "tray",
                                               description: Text("Задайте ключ GitHub в «Настройках» и потяните экран вниз."))
                    }
                }
                .padding()
            }
            .refreshable { await store.refresh() }
            .overlay { if store.isLoading && store.data == nil { ProgressView() } }
            .navigationTitle("Сегодня")
        }
    }

    @ViewBuilder
    private func recovery(_ a: Analytics) -> some View {
        Card(title: "Восстановление") {
            if let s = a.lastSleep {
                MetricRow(label: "Сон (\(DateUtil.short(s.date)))",
                          value: Fmt.hours(s.value),
                          note: a.sleepBaseline.map { "среднее \(Fmt.hours($0))" })
            } else {
                MetricRow(label: "Сон", value: "—")
            }
            let shr = a.latest(\.avgSleepingHR)
            MetricRow(label: "Пульс во сне" + (shr.map { " (\(DateUtil.short($0.date)))" } ?? ""),
                      value: shr.map { "\(Fmt.num($0.value)) уд/мин" } ?? "—",
                      note: shr.flatMap { s in
                          a.baseline(\.avgSleepingHR, before: s.date).map { "база \(Fmt.num($0))" }
                      })
            let hrv = a.latest(\.hrvSDNN)
            MetricRow(label: "HRV SDNN" + (hrv.map { " (\(DateUtil.short($0.date)))" } ?? ""),
                      value: hrv.map { "\(Fmt.num($0.value)) мс" } ?? "—",
                      note: hrv.flatMap { h in
                          a.baseline(\.hrvSDNN, before: h.date).map {
                              "база \(Fmt.num($0)) (\(Fmt.delta(h.value, $0) ?? ""))"
                          }
                      })
            let rhr = a.latest(\.restingHR)
            MetricRow(label: "Пульс покоя" + (rhr.map { " (\(DateUtil.short($0.date)))" } ?? ""),
                      value: rhr.map { "\(Fmt.num($0.value)) уд/мин" } ?? "—",
                      note: rhr.flatMap { r in
                          a.baseline(\.restingHR, before: r.date).map {
                              "база \(Fmt.num($0)) (\(Fmt.delta(r.value, $0) ?? ""))"
                          }
                      })
            Text("База: среднее за предыдущие 28 дней с данными.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func loadCard(_ a: Analytics) -> some View {
        if let l = a.load {
            Card(title: "Нагрузка (\(DateUtil.short(l.date)))") {
                MetricRow(label: "Фитнес (CTL)", value: Fmt.num(l.ctl, 1))
                MetricRow(label: "Усталость (ATL)", value: Fmt.num(l.atl, 1))
                MetricRow(label: "Форма (CTL − ATL)", value: Fmt.num(l.ctl - l.atl, 1))
            }
        }
    }

    @ViewBuilder
    private func adviceCard(_ a: Analytics) -> some View {
        Card(title: "Рекомендация на сегодня") {
            if let adv = store.advice, !adv.lines.isEmpty {
                ForEach(adv.lines, id: \.self) { line in
                    Text(line).fixedSize(horizontal: false, vertical: true)
                }
                if let d = adv.date {
                    if d == a.today {
                        Text("Сформирована проверкой восстановления \(DateUtil.short(d)).")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("Внимание: рекомендация от \(DateUtil.short(d)), за сегодня ещё не обновлена.")
                            .font(.caption).foregroundStyle(.orange)
                    }
                }
            } else {
                Text("Ещё не рассчитана: появится после проверки восстановления.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func weightCard(_ a: Analytics) -> some View {
        let w = a.latest(\.weight)
        let avg = a.recentAverage(\.weight, days: 7)
        if w != nil || avg != nil {
            Card(title: "Вес") {
                if let w {
                    MetricRow(label: "Последнее взвешивание (\(DateUtil.short(w.date)))",
                              value: "\(Fmt.num(w.value, 1)) кг")
                }
                MetricRow(label: "Среднее за 7 дней", value: avg.map { "\(Fmt.num($0, 1)) кг" } ?? "—")
                if let bf = a.latest(\.bodyFat) {
                    MetricRow(label: "Жир (оценка весов)", value: "\(Fmt.num(bf.value, 1)) %",
                              note: "тренд, не точное значение")
                }
            }
        }
    }

    @ViewBuilder
    private func lastWorkout(_ a: Analytics) -> some View {
        if let act = a.lastActivity {
            Card(title: "Последняя тренировка") {
                ActivityRow(activity: act)
            }
        }
    }
}
