import AppKit
import SwiftUI
import WebKit

@MainActor
struct EvolutionReadyButton: View {
    var language: AppLanguage = .ko
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @State private var dim = false
    var body: some View {
        Button(action: action) {
            Image(systemName: "lightbulb.fill").font(.system(size: 14))
                .foregroundStyle(LinearGradient(colors: [CyberPalette.yellow, .orange], startPoint: .top, endPoint: .bottom)).padding(7)
                .background(Color.orange.opacity(0.12))
                .overlay(Rectangle().stroke(Color.orange.opacity(0.65), lineWidth: 0.7))
        }.buttonStyle(.plain).opacity(dim && !reducedMotion ? 0.4 : 1)
            .help(L(language).digimonUI("Special evolution or continuation available")).accessibilityLabel(L(language).digimonUI("Special evolution or continuation available"))
            .onAppear {
                if !reducedMotion { withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { dim = true } }
            }
    }
}

@MainActor
struct DigimonEvolutionSceneView: View {
    let store: CompanionStore
    let scene: DigimonEvolutionScene
    @Environment(PopoverNavigation.self) private var navigation
    @State private var artwork: [Int: Data] = [:]
    @State private var loading = true
    @State private var ready = false
    private func prepareArtwork() async {
        loading = true
        ready = false
        var loaded: [Int: Data] = [:]
        let ids = scene.kind == .fusion ? Set(scene.ingredients + [scene.source, scene.target]) : [scene.target]
        for id in ids {
            if let bytes = await DigimonArtworkCache.shared.data(for: DigimonArtwork.speciesKey(id)) { loaded[id] = bytes }
            guard !Task.isCancelled else { return }
        }
        artwork = loaded
        ready = ids.allSatisfy { loaded[$0] != nil }
        loading = false
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(DigimonEvolutionRules.rule(from: scene.source, to: scene.target).localizedMethod(store.l))
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button(store.l.digimonUI("Home")) { store.dismissEvolutionScene(); navigation.reset() }
                    .buttonStyle(TerminalCommandStyle())
            }.padding(14)
            if ready {
                EvolutionWebScene(store: store, scene: scene, artwork: artwork)
                    .id(store.language.rawValue)
            } else {
                Spacer()
                if loading { ProgressView(store.l.digimonUI("Loading artwork…")) }
                else {
                    Text(store.l.digimonUI("Artwork could not be downloaded. Check your connection and retry."))
                        .multilineTextAlignment(.center).padding()
                    Button(store.l.digimonUI("Retry")) { Task { await prepareArtwork() } }
                        .buttonStyle(TerminalCommandStyle())
                }
                Spacer()
            }
        }.frame(width: PopoverMetrics.width, height: 640).cyberSurface()
            .task(id: scene.id) { await prepareArtwork() }
    }
}

/// Bundled HTML receives downloaded originals as data URLs; the web view never navigates remotely.
@MainActor
private struct EvolutionWebScene: NSViewRepresentable {
    let store: CompanionStore
    let scene: DigimonEvolutionScene
    let artwork: [Int: Data]
    func makeCoordinator() -> Coordinator { Coordinator(store: store, scene: scene) }
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.userContentController.addScriptMessageHandler(context.coordinator, contentWorld: .page, name: "evolution")
        let web = WKWebView(frame: .zero, configuration: configuration)
        web.setValue(false, forKey: "drawsBackground")
        web.navigationDelegate = context.coordinator
        let result = DigimonCatalog.find(scene.target)
        func name(_ id: Int) -> String {
            let species = DigimonCatalog.find(id)
            return species?.names[store.language.rawValue] ?? species?.english ?? ""
        }
        func art(_ id: Int) -> String {
            guard let bytes = artwork[id] else { return "" }
            let type = bytes.starts(with: [0x89, 0x50, 0x4e, 0x47]) ? "png" : "jpeg"
            return "data:image/\(type);base64," + bytes.base64EncodedString()
        }
        let leftID = scene.ingredients.first ?? scene.source
        let rightID = scene.ingredients.dropFirst().first ?? scene.source
        let config: [String: Any] = ["language": store.language.rawValue, "kind": scene.kind == .fusion ? "fusion" : "normal",
            "left": name(leftID), "right": name(rightID),
            "result": result?.names[store.language.rawValue] ?? result?.english ?? "",
            "art": scene.kind == .fusion
                ? ["war": art(leftID), "metal": art(rightID), "omega": art(scene.target)]
                : ["omega": art(scene.target)]]
        if let url = CyberAssets.url(name: "evolution-scene", ext: "html"),
           let template = try? String(contentsOf: url, encoding: .utf8),
           let data = try? JSONSerialization.data(withJSONObject: config, options: [.sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            // Escape '<' so a catalog name can never terminate the inline script.
            web.loadHTMLString(template.replacingOccurrences(of: "__EVOLUTION_CONFIG__", with: json.replacingOccurrences(of: "<", with: "\\u003c")), baseURL: nil)
        }
        return web
    }
    func updateNSView(_ view: WKWebView, context: Context) {}
    static func dismantleNSView(_ view: WKWebView, coordinator: Coordinator) {
        view.stopLoading()
        view.configuration.userContentController.removeScriptMessageHandler(forName: "evolution", contentWorld: .page)
    }
    @MainActor
    final class Coordinator: NSObject, WKScriptMessageHandlerWithReply, WKNavigationDelegate {
        let store: CompanionStore
        let scene: DigimonEvolutionScene
        init(store: CompanionStore, scene: DigimonEvolutionScene) { self.store = store; self.scene = scene }
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage,
                                   replyHandler: @escaping @MainActor @Sendable (Any?, String?) -> Void) {
            guard message.frameInfo.isMainFrame, let payload = message.body as? [String: String] else { replyHandler(false, nil); return }
            switch payload["action"] {
            case "start": replyHandler(store.commitEvolutionScene(scene.id), nil)
            case "done": replyHandler(true, nil)
            default: replyHandler(false, nil)
            }
        }
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
            decisionHandler(action.request.url?.scheme == "about" ? .allow : .cancel)
        }
    }
}
