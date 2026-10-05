import SwiftUI
import WebKit

/// Shows the same dashboard.html that GitHub Actions builds, so the app
/// always matches the published panel without duplicating calculations.
struct DashboardView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        NavigationStack {
            Group {
                if let html = store.dashboardHTML {
                    HTMLView(html: html)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    ContentUnavailableView("Панель не загружена",
                                           systemImage: "rectangle.grid.1x2",
                                           description: Text("Обновите данные на вкладке «Сегодня»."))
                }
            }
            .navigationTitle("Панель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    Task { await store.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(store.isLoading)
            }
        }
    }
}

struct HTMLView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.isOpaque = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        if context.coordinator.loaded != html {
            context.coordinator.loaded = html
            view.loadHTMLString(html, baseURL: nil)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var loaded: String?
    }
}
