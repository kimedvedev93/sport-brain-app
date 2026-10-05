import Foundation

enum AppError: LocalizedError {
    case noToken
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .noToken:
            return "Не задан ключ GitHub. Откройте вкладку «Настройки»."
        case .http(401):
            return "GitHub отклонил ключ (401). Проверьте ключ в «Настройках»."
        case .http(403):
            return "Нет доступа к репозиторию (403). У ключа должно быть право Contents: Read для sport-brain."
        case .http(404):
            return "Файл не найден (404). Проверьте, что ключ выдан на репозиторий sport-brain."
        case .http(let code):
            return "Ошибка GitHub: код \(code)."
        }
    }
}

/// Loads files from the private sport-brain repo. All calculations stay in GitHub;
/// the app only reads data.json, the coach recommendation and the built dashboard.
@MainActor
final class DataStore: ObservableObject {
    static let owner = "kimedvedev93"
    static let repo = "sport-brain"

    @Published var data: SportData?
    @Published var advice: Advice?
    @Published var dashboardHTML: String?
    @Published var errorText: String?
    @Published var isLoading = false
    @Published var lastRefresh: Date?
    @Published var hasToken: Bool = Keychain.load() != nil

    private let cacheDir: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]

    init() {
        loadCache()
    }

    var analytics: Analytics? { data.map(Analytics.init) }

    func setToken(_ token: String) {
        let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty {
            Keychain.delete()
        } else {
            Keychain.save(t)
        }
        hasToken = Keychain.load() != nil
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        errorText = nil
        do {
            let raw = try await fetch("data.json")
            let decoded = try JSONDecoder().decode(SportData.self, from: raw)
            data = decoded
            try? raw.write(to: cacheDir.appendingPathComponent("data.json"))

            if let adv = try? await fetch("state/recommendation.json"),
               let a = try? JSONDecoder().decode(Advice.self, from: adv) {
                advice = a
                try? adv.write(to: cacheDir.appendingPathComponent("recommendation.json"))
            }
            if let html = try? await fetch("dashboard.html") {
                dashboardHTML = String(data: html, encoding: .utf8)
                try? html.write(to: cacheDir.appendingPathComponent("dashboard.html"))
            }
            lastRefresh = Date()
        } catch let e as DecodingError {
            errorText = "Не удалось разобрать data.json: \(e.localizedDescription)"
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func fetch(_ path: String) async throws -> Data {
        guard let token = Keychain.load() else { throw AppError.noToken }
        let url = URL(string: "https://api.github.com/repos/\(Self.owner)/\(Self.repo)/contents/\(path)?ref=main")!
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github.raw+json", forHTTPHeaderField: "Accept")
        req.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 30
        let (body, response) = try await URLSession.shared.data(for: req)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else { throw AppError.http(code) }
        return body
    }

    private func loadCache() {
        if let raw = try? Data(contentsOf: cacheDir.appendingPathComponent("data.json")) {
            data = try? JSONDecoder().decode(SportData.self, from: raw)
        }
        if let adv = try? Data(contentsOf: cacheDir.appendingPathComponent("recommendation.json")) {
            advice = try? JSONDecoder().decode(Advice.self, from: adv)
        }
        if let html = try? Data(contentsOf: cacheDir.appendingPathComponent("dashboard.html")) {
            dashboardHTML = String(data: html, encoding: .utf8)
        }
    }
}
