import Foundation

// MARK: - Lenient decoding helpers
// data.json comes from intervals.icu; fields are often null or change type,
// so every value is optional and a bad value never breaks the whole file.

extension KeyedDecodingContainer {
    func lenientDouble(_ key: K) -> Double? {
        if let v = try? decodeIfPresent(Double.self, forKey: key) { return v }
        if let s = try? decodeIfPresent(String.self, forKey: key) { return Double(s) }
        return nil
    }

    func lenientString(_ key: K) -> String? {
        (try? decodeIfPresent(String.self, forKey: key)) ?? nil
    }
}

// MARK: - data.json

struct SportData: Decodable {
    let fetchedOn: String?
    let activities: [Activity]
    let wellness: [Wellness]

    enum CodingKeys: String, CodingKey {
        case fetchedOn = "fetched_on"
        case activities, wellness
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        fetchedOn = c.lenientString(.fetchedOn)
        let acts = (try? c.decodeIfPresent([Activity].self, forKey: .activities)) ?? nil
        let well = (try? c.decodeIfPresent([Wellness].self, forKey: .wellness)) ?? nil
        activities = (acts ?? []).sorted { ($0.startDateLocal ?? "") < ($1.startDateLocal ?? "") }
        wellness = (well ?? []).sorted { $0.date < $1.date }
    }
}

struct Wellness: Decodable, Identifiable {
    var id: String { date }
    let date: String
    let sleepSecs: Double?
    let avgSleepingHR: Double?
    let hrvSDNN: Double?
    let restingHR: Double?
    let ctl: Double?
    let atl: Double?
    let weight: Double?
    let bodyFat: Double?
    let readiness: Double?

    enum Top: String, CodingKey { case date, sleepSecs, hrvSDNN, restingHR, raw }
    enum Raw: String, CodingKey {
        case sleepSecs, avgSleepingHR, hrvSDNN, restingHR, ctl, atl, weight, bodyFat, readiness
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Top.self)
        date = try c.decode(String.self, forKey: .date)
        let r = try? c.nestedContainer(keyedBy: Raw.self, forKey: .raw)
        sleepSecs = c.lenientDouble(.sleepSecs) ?? r?.lenientDouble(.sleepSecs)
        hrvSDNN = c.lenientDouble(.hrvSDNN) ?? r?.lenientDouble(.hrvSDNN)
        restingHR = c.lenientDouble(.restingHR) ?? r?.lenientDouble(.restingHR)
        avgSleepingHR = r?.lenientDouble(.avgSleepingHR)
        ctl = r?.lenientDouble(.ctl)
        atl = r?.lenientDouble(.atl)
        weight = r?.lenientDouble(.weight)
        bodyFat = r?.lenientDouble(.bodyFat)
        readiness = r?.lenientDouble(.readiness)
    }

    var day: Date? { DateUtil.parseDay(date) }
    var sleepHours: Double? {
        guard let s = sleepSecs, s > 0 else { return nil }
        return s / 3600
    }
}

struct Activity: Decodable, Identifiable {
    let id: String
    let startDateLocal: String?
    let type: String?
    let name: String?
    let movingTime: Double?
    let load: Double?
    let avgHR: Double?
    let maxHR: Double?
    let distance: Double?

    enum CodingKeys: String, CodingKey {
        case id, type, name, distance
        case startDateLocal = "start_date_local"
        case movingTime = "moving_time"
        case load = "icu_training_load"
        case avgHR = "average_heartrate"
        case maxHR = "max_heartrate"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenientString(.id) ?? UUID().uuidString
        startDateLocal = c.lenientString(.startDateLocal)
        type = c.lenientString(.type)
        name = c.lenientString(.name)
        movingTime = c.lenientDouble(.movingTime)
        load = c.lenientDouble(.load)
        avgHR = c.lenientDouble(.avgHR)
        maxHR = c.lenientDouble(.maxHR)
        distance = c.lenientDouble(.distance)
    }

    var dayString: String { String((startDateLocal ?? "").prefix(10)) }
}

// MARK: - state/recommendation.json

struct Advice: Decodable {
    let date: String?
    let lines: [String]
}

// MARK: - Dates

enum DateUtil {
    static let moscow = TimeZone(identifier: "Europe/Moscow") ?? .current

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = moscow
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let ruFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.timeZone = moscow
        f.dateFormat = "d MMM"
        return f
    }()

    static func parseDay(_ s: String) -> Date? { dayFormatter.date(from: String(s.prefix(10))) }
    static func todayString() -> String { dayFormatter.string(from: Date()) }
    static func short(_ s: String) -> String {
        guard let d = parseDay(s) else { return s }
        return ruFormatter.string(from: d)
    }
}
