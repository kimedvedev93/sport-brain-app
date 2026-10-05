import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: DataStore
    @State private var token = ""
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("github_pat_…", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Сохранить и обновить") {
                        store.setToken(token)
                        token = ""
                        saved = true
                        Task { await store.refresh() }
                    }
                    .disabled(token.trimmingCharacters(in: .whitespaces).isEmpty)
                    if store.hasToken {
                        Label("Ключ сохранён на этом телефоне", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Button("Удалить ключ", role: .destructive) {
                            store.setToken("")
                            saved = false
                        }
                    }
                } header: {
                    Text("Ключ GitHub")
                } footer: {
                    Text("Нужен ключ только на чтение репозитория \(DataStore.owner)/\(DataStore.repo): Fine-grained token, доступ к одному репозиторию, право Contents: Read-only. Ключ хранится в связке ключей iPhone и никуда не отправляется, кроме GitHub.")
                }

                Section("Состояние") {
                    MetricRow(label: "Данные от", value: store.data?.fetchedOn.map(DateUtil.short) ?? "—")
                    MetricRow(label: "Обновлено в приложении",
                              value: store.lastRefresh.map { $0.formatted(date: .omitted, time: .shortened) } ?? "—")
                    if let err = store.errorText {
                        Text(err).foregroundStyle(.red)
                    }
                }

                Section {
                    Text("Все расчёты делаются в GitHub (sport-brain). Приложение только показывает результат.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Настройки")
        }
    }
}
