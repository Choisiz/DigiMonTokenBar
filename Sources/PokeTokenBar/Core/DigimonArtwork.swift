import Foundation
import CryptoKit
import ImageIO

/// Remote originals only. Generated X-Antibody art and the application icon stay bundled.
enum DigimonArtwork {
    struct Source: Codable, Sendable {
        let url: URL
        var pageImage: Bool = false
    }
    static let sources: [String: Source] = {
        guard let url = DigimonCatalog.resource("external-artwork", extension: "json"),
              let data = try? Data(contentsOf: url),
              let sources = try? JSONDecoder().decode([String: Source].self, from: data) else {
            preconditionFailure("Missing external artwork source manifest")
        }
        return sources
    }()
    static func speciesKey(_ id: Int) -> String { "species-\(id)" }
    static func source(for key: String) -> Source? { sources[key] }

    /// The artist's public page supplies a signed image address; never persist its query in source.
    static func pageImageURL(in html: String) -> URL? {
        guard let tags = try? NSRegularExpression(pattern: "<meta\\b[^>]*>", options: [.caseInsensitive]) else { return nil }
        let text = html as NSString
        for match in tags.matches(in: html, range: NSRange(location: 0, length: text.length)) {
            let tag = text.substring(with: match.range)
            func attribute(_ name: String) -> String? {
                guard let pattern = try? NSRegularExpression(pattern: "\\b" + name + "\\s*=\\s*[\"']([^\"']*)[\"']", options: [.caseInsensitive]),
                      let match = pattern.firstMatch(in: tag, range: NSRange(location: 0, length: (tag as NSString).length)) else { return nil }
                return (tag as NSString).substring(with: match.range(at: 1))
            }
            guard attribute("property")?.lowercased() == "og:image", let value = attribute("content"),
                  let url = URL(string: value.replacingOccurrences(of: "&amp;", with: "&").replacingOccurrences(of: "&#38;", with: "&")),
                  url.scheme == "https", url.host?.hasSuffix(".wixmp.com") == true else { continue }
            return url
        }
        return nil
    }
}

/// Source-addressed disk cache: a changed source cannot reuse an old processed capsule or Pokémon egg.
/// In-flight requests are shared across thumbnails, the menu, and detail views. No network on the UI thread.
actor DigimonArtworkCache {
    static let shared = DigimonArtworkCache()
    nonisolated static var defaultDirectory: URL { AppStatePaths.directory().appendingPathComponent("sprites/external-artwork-v1") }
    nonisolated let directory: URL
    private let session: URLSession
    private var pending: [String: Task<Data?, Never>] = [:]

    init(directory: URL = DigimonArtworkCache.defaultDirectory, session: URLSession = .shared) {
        self.directory = directory
        self.session = session
    }
    nonisolated static func fileURL(key: String, source: DigimonArtwork.Source, directory: URL = defaultDirectory) -> URL {
        let digest = SHA256.hash(data: Data((key + "\n" + source.url.absoluteString + "\noriginal-v1").utf8))
            .map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(digest + ".image")
    }
    nonisolated static func cachedURL(for key: String, directory: URL = defaultDirectory) -> URL? {
        guard let source = DigimonArtwork.source(for: key) else { return nil }
        let file = fileURL(key: key, source: source, directory: directory)
        return FileManager.default.fileExists(atPath: file.path) ? file : nil
    }
    nonisolated static func validImage(_ data: Data) -> Bool {
        guard !data.isEmpty, data.count <= 16 * 1024 * 1024,
              let image = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetStatus(image) == .statusComplete,
              let properties = CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0, width <= 8192, height <= 8192 else { return false }
        return CGImageSourceCreateImageAtIndex(image, 0, nil) != nil
    }
    func data(for key: String) async -> Data? {
        guard let source = DigimonArtwork.source(for: key) else { return nil }
        return await data(key: key, source: source)
    }
    func data(key: String, source: DigimonArtwork.Source) async -> Data? {
        guard source.url.scheme == "https" else { return nil }
        let file = Self.fileURL(key: key, source: source, directory: directory)
        if let bytes = try? Data(contentsOf: file) {
            if Self.validImage(bytes) { return bytes }
            try? FileManager.default.removeItem(at: file)
        }
        let identity = file.path
        if let task = pending[identity] { return await task.value }
        let session = self.session
        let task = Task<Data?, Never> {
            func fetch(_ url: URL) async -> Data? {
                var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 25)
                request.setValue("DigiTokenBar/0.1", forHTTPHeaderField: "User-Agent")
                guard let (bytes, response) = try? await session.data(for: request),
                      let response = response as? HTTPURLResponse, response.statusCode == 200,
                      response.url?.scheme == "https" else { return nil }
                return bytes
            }
            var url = source.url
            if source.pageImage {
                guard let page = await fetch(url), page.count < 4 * 1024 * 1024,
                      let html = String(data: page, encoding: .utf8),
                      let image = DigimonArtwork.pageImageURL(in: html) else { return nil }
                url = image
            }
            guard let bytes = await fetch(url), Self.validImage(bytes) else { return nil }
            do {
                try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
                try bytes.write(to: file, options: .atomic)
            } catch { /* A read-only/full disk must not prevent this session's display. */ }
            return bytes
        }
        pending[identity] = task
        let result = await task.value
        pending[identity] = nil
        return result
    }
}
