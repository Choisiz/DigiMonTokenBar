import AppKit
import SwiftUI

/// Shared native palette: data remains the focus; the circuit pattern is static and never intercepts input.
enum CyberPalette {
    static let background = Color(red: 0.008, green: 0.027, blue: 0.035)
    static let panel = Color(red: 0.024, green: 0.063, blue: 0.078)
    static let panelRaised = Color(red: 0.051, green: 0.110, blue: 0.153)
    static let cyan = Color(red: 0.49, green: 0.83, blue: 0.99)
    static let yellow = Color(red: 1, green: 0.86, blue: 0.22)
    static let text = Color(red: 0.90, green: 0.96, blue: 1)
    static let muted = Color(red: 0.54, green: 0.68, blue: 0.78)
    static let line = cyan.opacity(0.24)
}

struct CyberCutCorner: Shape {
    var cut: CGFloat = 9
    func path(in rect: CGRect) -> Path {
        let c = min(cut, min(rect.width, rect.height) / 3)
        return Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX - c, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + c))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX + c, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - c))
            p.closeSubpath()
        }
    }
}

/// Geometry copied from the approved HTML SVGs; static Canvas drawing needs no timer.
private struct CyberPatternAsset: Decodable, Sendable {
    struct Point: Decodable, Sendable { let command: String; let x: Double; let y: Double }
    struct Mark: Decodable, Sendable {
        let color: String
        let opacity: Double
        let lineWidth: Double
        let points: [Point]?
        let rect: [Double]?
        let radius: Double?
        let ellipse: Bool?
        let fill: String?
    }
    let width: Double
    let height: Double
    let shapes: [Mark]
    @MainActor static func load(_ name: String) -> Self? {
        guard let url = CyberAssets.url(name: name, ext: "json"), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}

private func patternColor(_ hex: String) -> Color {
    let value = UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
    return Color(red: Double((value >> 16) & 255) / 255,
                 green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
}

@MainActor
struct CyberPattern: View {
    var binary = false
    var offset = CGPoint.zero
    private static let circuit = CyberPatternAsset.load("circuit")
    private static let digits = CyberPatternAsset.load("card-glyphs")
    var body: some View {
        Canvas { context, size in
            guard let asset = binary ? Self.digits : Self.circuit else { return }
            for tileY in stride(from: offset.y, to: size.height, by: asset.height) {
                for tileX in stride(from: offset.x, to: size.width, by: asset.width) {
                    var tile = context
                    tile.translateBy(x: tileX, y: tileY)
                    tile.clip(to: Path(CGRect(x: 0, y: 0, width: asset.width, height: asset.height)))
                    for mark in asset.shapes {
                        var path = Path()
                        if let points = mark.points {
                            for point in points {
                                switch point.command {
                                case "M": path.move(to: CGPoint(x: point.x, y: point.y))
                                case "L": path.addLine(to: CGPoint(x: point.x, y: point.y))
                                default: path.closeSubpath()
                                }
                            }
                        } else if let r = mark.rect {
                            let rect = CGRect(x: r[0], y: r[1], width: r[2], height: r[3])
                            if mark.ellipse == true { path.addEllipse(in: rect) }
                            else { path.addRoundedRect(in: rect, cornerSize: CGSize(width: mark.radius ?? 0, height: mark.radius ?? 0)) }
                        }
                        var ink = tile
                        ink.opacity = mark.opacity * (binary ? 1 : 0.85)
                        if let fill = mark.fill { ink.fill(path, with: .color(patternColor(fill))) }
                        if mark.lineWidth > 0 { ink.stroke(path, with: .color(patternColor(mark.color)), lineWidth: mark.lineWidth) }
                    }
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

@MainActor
struct CyberPanel: ViewModifier {
    var accent: Color = CyberPalette.cyan
    var binary = false
    var patternOffset = CGPoint.zero
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    CyberPalette.panel.opacity(0.96)
                    if binary {
                        CyberPattern(binary: true, offset: patternOffset)
                        LinearGradient(stops: [
                            .init(color: patternColor("#041018").opacity(0.063), location: 0),
                            .init(color: patternColor("#041018").opacity(0.439), location: 0.30),
                            .init(color: patternColor("#041018").opacity(0.502), location: 0.76),
                            .init(color: patternColor("#041018").opacity(0.094), location: 1)
                        ], startPoint: .leading, endPoint: .trailing)
                    }
                }.clipShape(Rectangle()).allowsHitTesting(false)
            }
            .overlay(Rectangle().stroke(CyberPalette.line, lineWidth: 0.7).allowsHitTesting(false))
            .overlay(alignment: .topLeading) { Rectangle().fill(accent).frame(width: 30, height: 2).allowsHitTesting(false) }
    }
}

extension View {
    func cyberPanel(accent: Color = CyberPalette.cyan, binary: Bool = false, patternOffset: CGPoint = .zero) -> some View { modifier(CyberPanel(accent: accent, binary: binary, patternOffset: patternOffset)) }
    func cyberSurface() -> some View {
        self
            .foregroundStyle(CyberPalette.text)
            .tint(CyberPalette.cyan)
            .accentColor(CyberPalette.cyan)
            .background { CyberPalette.background.overlay { CyberPattern() } }
            .environment(\.colorScheme, .dark)
            .preferredColorScheme(.dark)
    }
}

@MainActor
struct CyberSectionHeading: View {
    let number: String
    let title: String
    var detail: String = ""
    var body: some View {
        HStack(spacing: 7) {
            Text(number).foregroundStyle(CyberPalette.yellow)
            Text(title).tracking(1.5).foregroundStyle(CyberPalette.cyan)
            Rectangle().fill(CyberPalette.line).frame(height: 1)
            if !detail.isEmpty { Text(detail).foregroundStyle(CyberPalette.muted) }
        }.font(.system(size: 9, weight: .semibold, design: .monospaced))
    }
}

@MainActor
struct CyberTerminalHeader: View {
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                CyberCutCorner(cut: 7).stroke(CyberPalette.cyan, lineWidth: 1)
                Image(systemName: "square.stack.3d.up").font(.system(size: 18, weight: .light))
                    .foregroundStyle(CyberPalette.cyan)
            }.frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text("Digimon").font(.system(size: 19, weight: .bold, design: .monospaced))
                Text("TOKEN TERMINAL / PERSONAL NETWORK")
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .tracking(1.2).foregroundStyle(CyberPalette.muted)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "waveform.path").font(.system(size: 18)).foregroundStyle(CyberPalette.yellow)
                Text("D–LINK").font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundStyle(CyberPalette.yellow)
            }.accessibilityHidden(true)
        }.padding(.bottom, 2)
    }
}

/// A tied cloth bundle, drawn locally so its outline matches the other tab icons.
struct CyberBundleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 5, y: 5))
        p.addLine(to: CGPoint(x: 3, y: 1))
        p.addLine(to: CGPoint(x: 8, y: 2))
        p.addLine(to: CGPoint(x: 13, y: 1))
        p.addLine(to: CGPoint(x: 11, y: 5))
        p.addCurve(to: CGPoint(x: 15, y: 13), control1: CGPoint(x: 13, y: 7), control2: CGPoint(x: 15, y: 10))
        p.addCurve(to: CGPoint(x: 8, y: 17), control1: CGPoint(x: 15, y: 16), control2: CGPoint(x: 12, y: 17))
        p.addCurve(to: CGPoint(x: 1, y: 13), control1: CGPoint(x: 4, y: 17), control2: CGPoint(x: 1, y: 16))
        p.addCurve(to: CGPoint(x: 5, y: 5), control1: CGPoint(x: 1, y: 10), control2: CGPoint(x: 3, y: 7))
        p.closeSubpath()
        p.move(to: CGPoint(x: 4, y: 5)); p.addLine(to: CGPoint(x: 12, y: 5))
        p.move(to: CGPoint(x: 8, y: 5)); p.addLine(to: CGPoint(x: 10, y: 9))
        return p.applying(CGAffineTransform(scaleX: rect.width / 16, y: rect.height / 18)
            .concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY)))
    }
}

@MainActor
struct CyberNavigation: View {
    @Bindable var navigation: PopoverNavigation
    let l: L
    private let tabs: [PopoverTab] = [.home, .shop, .bag, .collection]
    private func title(_ tab: PopoverTab) -> String {
        switch tab { case .home: l.home; case .shop: l.shop; case .bag: l.bag; case .collection: l.dexTitle }
    }
    private func symbol(_ tab: PopoverTab) -> String {
        switch tab { case .home: "square.grid.2x2"; case .shop: "cart"; case .bag: "shippingbox"; case .collection: "laptopcomputer" }
    }
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.element) { index, tab in
                let selected = navigation.tab == tab
                Button { navigation.tab = tab } label: {
                    HStack(spacing: 6) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 9, design: .monospaced)).opacity(0.6)
                        Text(title(tab)).font(.system(size: 10)).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity).frame(height: 36)
                    .foregroundStyle(selected ? CyberPalette.text : CyberPalette.muted)
                    .background(selected ? CyberPalette.cyan.opacity(0.08) : CyberPalette.panel.opacity(0.7))
                    .overlay(alignment: .bottom) { Rectangle().fill(selected ? CyberPalette.cyan : CyberPalette.line).frame(height: selected ? 2 : 0.5) }
                    .overlay(alignment: .trailing) { Rectangle().fill(CyberPalette.line).frame(width: 0.5) }
                    .contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .accessibilityLabel(title(tab))
                    .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}

@MainActor
enum CyberAssets {
    static func url(name: String, ext: String) -> URL? {
        if DigimonArtwork.source(for: name) != nil { return DigimonArtworkCache.cachedURL(for: name) }
        return DigimonCatalog.resource(name, extension: ext)
    }
    private static var images: [String: NSImage] = [:]
    static func image(name: String, ext: String) -> NSImage? {
        let key = name + "." + ext
        if let cached = images[key] { return cached }
        guard let url = url(name: name, ext: ext), let image = NSImage(contentsOf: url) else { return nil }
        images[key] = image
        return image
    }
    static func loadImage(name: String, ext: String) async -> NSImage? {
        if let cached = image(name: name, ext: ext) { return cached }
        guard DigimonArtwork.source(for: name) != nil,
              let data = await DigimonArtworkCache.shared.data(for: name), !Task.isCancelled,
              let loaded = NSImage(data: data) else { return nil }
        images[name + "." + ext] = loaded
        return loaded
    }
}

@MainActor
struct CyberAssetImage: View {
    let name: String
    let ext: String
    @State private var loaded: NSImage?
    var body: some View {
        Group {
            if let image = loaded ?? CyberAssets.image(name: name, ext: ext) {
                Image(nsImage: image).resizable().interpolation(.high).scaledToFit()
            } else {
                Image(systemName: "photo").foregroundStyle(.secondary)
            }
        }.task(id: name + "." + ext) {
            loaded = await CyberAssets.loadImage(name: name, ext: ext)
        }
    }
}

@MainActor
struct CyberGuidePanel: View {
    let language: AppLanguage
    var compact = false
    var body: some View {
        HStack(spacing: 16) {
            CyberAssetImage(name: "gennai", ext: "jpg")
                .frame(width: compact ? 42 : 76, height: compact ? 100 : 180)
                .background(Color.white)
                .clipShape(CyberCutCorner(cut: 8))
                .overlay(CyberCutCorner(cut: 8).stroke(CyberPalette.cyan.opacity(0.5), lineWidth: 1))
                .accessibilityLabel(L(language).gennaiName)
            VStack(alignment: .leading, spacing: 8) {
                Text("SUPPLY GUIDE").font(.system(size: 8, weight: .bold, design: .monospaced))
                    .tracking(2).foregroundStyle(CyberPalette.cyan)
                Text(L(language).gennaiName).font(.system(size: 20, weight: .semibold))
                Text(L(language).gennaiGuidance)
                    .font(.system(size: 11)).foregroundStyle(CyberPalette.muted).lineSpacing(4)
                Rectangle().fill(CyberPalette.line).frame(height: 1)
                Text("DIGITAL WORLD / INVENTORY").font(.system(size: 7, weight: .medium, design: .monospaced))
                    .foregroundStyle(CyberPalette.muted)
            }
            Spacer(minLength: 0)
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading).cyberPanel()
    }
}
