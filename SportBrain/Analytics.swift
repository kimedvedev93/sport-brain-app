import Foundation

/// Simple read-only summaries of data.json. Heavy analysis stays in GitHub / the coach tasks.
struct Analytics {
    let data: SportData
    let today: String = DateUtil.todayString()

    var wellness: [Wellness] { data.wellness }

    var isStale: Bool {
        guard let f = data.fetchedOn else { return true }
        return f < today
    }

    /// Record for today's date (last night's sleep lives here).
    var todayRecord: Wellness? { wellness.last { $0.date == today } }

    /// Latest record that has a value for the given field.
    func latest(_ field: KeyPath<Wellness, Double?>) -> (date: String, value: Double)? {
        for w in wellness.reversed() {
            if let v = w[keyPath: field] { return (w.date, v) }
        }
        return nil
    }

    /// Mean of the previous `days` values strictly before `date`.
    func baseline(_ field: KeyPath<Wellness, Double?>, before date: String, days: Int = 28) -> Double? {
        let values = wellness.filter { $0.date < date }.compactMap { $0[keyPath: field] }.suffix(days)
        guard values.count >= 3 else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Average over the last `days` calendar records that have a value.
    func recentAverage(_ field: KeyPath<Wellness, Double?>, days: Int = 7) -> Double? {
        let values = wellness.suffix(days).compactMap { $0[keyPath: field] }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    var lastSleep: (date: String, value: Double)? { latest(\.sleepHours) }
    var sleepBaseline: Double? { baseline(\.sleepHours, before: lastSleep?.date ?? today) }

    var load: (date: String, ctl: Double, atl: Double)? {
        for w in wellness.reversed() {
            if let c = w.ctl, let a = w.atl { return (w.date, c, a) }
        }
        return nil
    }

    var lastActivity: Activity? { data.activities.last }

    /// Points for charts, last `days` days.
    func series(_ field: KeyPath<Wellness, Double?>, days: Int) -> [ChartPoint] {
        guard let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return [] }
        return wellness.compactMap { w in
            guard let d = w.day, d >= start, let v = w[keyPath: field] else { return nil }
            return ChartPoint(date: d, value: v)
        }
    }
}

struct ChartPoint: Identifiable {
    let date: Date
    let value: Double
    var id: Date { date }
}

enum Fmt {
    static func num(_ v: Double?, _ digits: Int = 0) -> String {
        guard let v else { return "—" }
        return String(format: "%.\(digits)f", v).replacingOccurrences(of: ".", with: ",")
    }

    static func hours(_ h: Double?) -> String {
        guard let h else { return "—" }
        let total = Int((h * 60).rounded())
        return "\(total / 60) ч \(total % 60) мин"
    }

    static func minutes(_ secs: Double?) -> String {
        guard let s = secs else { return "—" }
        return "\(Int((s / 60).rounded())) мин"
    }

    /// "+3" / "−2" difference against a baseline.
    static func delta(_ v: Double?, _ base: Double?, _ digits: Int = 0) -> String? {
        guard let v, let base else { return nil }
        let d = v - base
        let s = String(format: "%.\(digits)f", abs(d)).replacingOccurrences(of: ".", with: ",")
        return (d >= 0 ? "+" : "−") + s
    }
}
