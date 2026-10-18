import AppKit
import XCTest
@testable import PokeTokenBar

private final class ArtworkURLProtocol: URLProtocol, @unchecked Sendable {
    struct Reply: Sendable { let status: Int; let data: Data }
    final class State: @unchecked Sendable {
        private let lock = NSLock()
        private var replies: [Reply] = []
        private var received: [URL] = []
        func configure(_ values: [Reply]) { lock.withLock { replies = values; received = [] } }
        func next(_ url: URL) -> Reply? {
            lock.withLock { received.append(url); return replies.isEmpty ? nil : replies.removeFirst() }
        }
        var urls: [URL] { lock.withLock { received } }
    }
    static let state = State()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let url = request.url else { return }
        guard let reply = Self.state.next(url) else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet)); return
        }
        // Keep the task in flight long enough for concurrent thumbnail subscribers to join it.
        Thread.sleep(forTimeInterval: 0.02)
        let response = HTTPURLResponse(url: url, statusCode: reply.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: reply.data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@MainActor
final class DigimonArtworkCacheTests: XCTestCase {
    private var root: URL!
    private var session: URLSession!
    private var png: Data!
    override func setUpWithError() throws {
        SpriteLoader.imageCache.removeAllObjects()
        root = FileManager.default.temporaryDirectory.appendingPathComponent("digimon-artwork-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ArtworkURLProtocol.self]
        session = URLSession(configuration: config)
        let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 3, pixelsHigh: 2,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        for x in 0..<3 { for y in 0..<2 { bitmap.setColor(.cyan, atX: x, y: y) } }
        png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        ArtworkURLProtocol.state.configure([])
    }
    override func tearDownWithError() throws {
        session.invalidateAndCancel()
        try FileManager.default.removeItem(at: root)
    }
    private func cache() -> DigimonArtworkCache { DigimonArtworkCache(directory: root, session: session) }
    private var source: DigimonArtwork.Source { .init(url: URL(string: "https://artwork.example/original.png")!) }

    func testAllSpeciesAndOriginalCapsulesAreMappedWithoutBundledCopies() throws {
        XCTAssertEqual(DigimonArtwork.sources.count, 489)
        let allowlist = try XCTUnwrap(DigimonCatalog.resource("bundled-files", extension: "json"))
        let expected = Set(try JSONDecoder().decode([String].self, from: Data(contentsOf: allowlist)))
            .union(["bundled-files.json"])
        let actual = Set(try FileManager.default.contentsOfDirectory(atPath: allowlist.deletingLastPathComponent().path))
        XCTAssertEqual(actual, expected, "SwiftPM resource copies must not retain old downloaded artwork")
        for species in DigimonCatalog.species {
            XCTAssertEqual(species.imageURL.scheme, "https")
            XCTAssertNil(DigimonCatalog.resource(String(species.id), extension: "png"))
            XCTAssertNil(DigimonCatalog.resource(String(species.id), extension: "jpg"))
        }
        for kind in ItemKind.allCases where kind.capsuleKey != nil {
            let key = try XCTUnwrap(kind.evolutionAsset)
            let source = try XCTUnwrap(DigimonArtwork.source(for: key))
            XCTAssertEqual(source.url.pathExtension, "jpg")
            XCTAssertEqual(source.url.host, "wikimon.net")
            XCTAssertNil(DigimonCatalog.resource(key, extension: "png"))
        }
        for key in ["gennai", "evolution-tag", "digivice-adventure", "digitama-adventure"] {
            XCTAssertNotNil(DigimonArtwork.source(for: key))
            XCTAssertNil(DigimonCatalog.resource(key, extension: key == "gennai" ? "jpg" : "png"))
        }
        XCTAssertNotNil(DigimonCatalog.resource("x-antibody-a", extension: "png"))
        XCTAssertNotNil(DigimonCatalog.resource("x-antibody-s", extension: "png"))
        XCTAssertTrue(DigimonArtwork.source(for: "evolution-tag")!.pageImage)
    }

    func testOriginalBytesSurviveDownloadAndOfflineRelaunch() async throws {
        ArtworkURLProtocol.state.configure([.init(status: 200, data: png)])
        let first = await cache().data(key: "capsule", source: source)
        XCTAssertEqual(first, png)
        ArtworkURLProtocol.state.configure([])
        let offline = await cache().data(key: "capsule", source: source)
        XCTAssertEqual(offline, png)
        XCTAssertTrue(ArtworkURLProtocol.state.urls.isEmpty, "A warm cache must work offline without any request")
        XCTAssertEqual(try Data(contentsOf: DigimonArtworkCache.fileURL(key: "capsule", source: source, directory: root)), png)
    }

    func testConcurrentReadersShareOneDownload() async {
        ArtworkURLProtocol.state.configure([.init(status: 200, data: png)])
        let cache = cache()
        let source = self.source
        async let first = cache.data(key: "shared", source: source)
        async let second = cache.data(key: "shared", source: source)
        let results = await [first, second]
        XCTAssertEqual(results, [png, png])
        XCTAssertEqual(ArtworkURLProtocol.state.urls.count, 1)
    }

    func testBadResponsesAreNotCachedAndLaterRetrySucceeds() async {
        let cache = cache()
        for reply in [ArtworkURLProtocol.Reply(status: 404, data: png), .init(status: 200, data: Data("<html>Error</html>".utf8))] {
            ArtworkURLProtocol.state.configure([reply])
            let failed = await cache.data(key: "retry", source: source)
            XCTAssertNil(failed)
            XCTAssertFalse(FileManager.default.fileExists(atPath: DigimonArtworkCache.fileURL(key: "retry", source: source, directory: root).path))
        }
        ArtworkURLProtocol.state.configure([])
        let offline = await cache.data(key: "retry", source: source)
        XCTAssertNil(offline)
        ArtworkURLProtocol.state.configure([.init(status: 200, data: png)])
        let recovered = await cache.data(key: "retry", source: source)
        XCTAssertEqual(recovered, png)
    }

    func testCorruptDiskCacheIsReplacedAndChangedSourceCannotReuseIt() async throws {
        let file = DigimonArtworkCache.fileURL(key: "same", source: source, directory: root)
        try Data("corrupt".utf8).write(to: file)
        ArtworkURLProtocol.state.configure([.init(status: 200, data: png), .init(status: 200, data: png)])
        let cache = cache()
        let repaired = await cache.data(key: "same", source: source)
        XCTAssertEqual(repaired, png)
        let changed = DigimonArtwork.Source(url: URL(string: "https://artwork.example/new-original.png")!)
        let downloaded = await cache.data(key: "same", source: changed)
        XCTAssertEqual(downloaded, png)
        XCTAssertEqual(ArtworkURLProtocol.state.urls.count, 2)
        XCTAssertNotEqual(file, DigimonArtworkCache.fileURL(key: "same", source: changed, directory: root))
    }

    func testArtistPageResolvesPublicSignedImageThenWorksOffline() async {
        let page = DigimonArtwork.Source(url: URL(string: "https://www.deviantart.com/artist/art/tag")!, pageImage: true)
        let html = "<meta content='https://images-wixmp-test.wixmp.com/tag.png?token=public&amp;x=1' property='og:image'>"
        ArtworkURLProtocol.state.configure([.init(status: 200, data: Data(html.utf8)), .init(status: 200, data: png)])
        let first = await cache().data(key: "tag", source: page)
        XCTAssertEqual(first, png)
        XCTAssertEqual(ArtworkURLProtocol.state.urls.count, 2)
        XCTAssertEqual(ArtworkURLProtocol.state.urls.last?.query, "token=public&x=1")
        ArtworkURLProtocol.state.configure([])
        let offline = await cache().data(key: "tag", source: page)
        XCTAssertEqual(offline, png)
        XCTAssertTrue(ArtworkURLProtocol.state.urls.isEmpty)
    }

    func testMissingArtistImageAndUntrustedAddressesFailWithoutImageRequest() async {
        for html in ["no metadata", "<meta property='og:image' content='http://images.wixmp.com/a.png'>",
                     "<meta property='og:image' content='https://evilwixmp.com/a.png'>"] {
            ArtworkURLProtocol.state.configure([.init(status: 200, data: Data(html.utf8))])
            let result = await cache().data(key: UUID().uuidString,
                source: .init(url: URL(string: "https://www.deviantart.com/artist/art/tag")!, pageImage: true))
            XCTAssertNil(result)
            XCTAssertEqual(ArtworkURLProtocol.state.urls.count, 1)
        }
        ArtworkURLProtocol.state.configure([])
        let insecure = await cache().data(key: "http", source: .init(url: URL(string: "http://artwork.example/a.png")!))
        XCTAssertNil(insecure)
        let missing = await cache().data(for: "unknown-artwork")
        XCTAssertNil(missing)
        XCTAssertTrue(ArtworkURLProtocol.state.urls.isEmpty)
    }

    func testReadOnlyCacheStillReturnsDownloadedOriginal() async throws {
        let blocked = root.appendingPathComponent("file-not-directory")
        try Data().write(to: blocked)
        ArtworkURLProtocol.state.configure([.init(status: 200, data: png)])
        let result = await DigimonArtworkCache(directory: blocked, session: session).data(key: "a", source: source)
        XCTAssertEqual(result, png)
    }

    func testProductionSpriteAndEggConsumersUseNewCacheNotLegacyFiles() async throws {
        let artDirectory = root.appendingPathComponent("external-artwork-v1")
        let artCache = DigimonArtworkCache(directory: artDirectory, session: session)
        let store = SpriteStore(directory: root, artworkCache: artCache)
        try Data("legacy Pokemon egg".utf8).write(to: root.appendingPathComponent("egg.png"))
        ArtworkURLProtocol.state.configure([.init(status: 200, data: png), .init(status: 200, data: png)])
        XCTAssertNil(SpriteLoader.cachedImage(speciesID: 2003, directory: root))
        let loaded = await SpriteLoader.image(speciesID: 2003, store: store)
        XCTAssertNotNil(loaded)
        XCTAssertNotNil(SpriteLoader.cachedImage(speciesID: 2003, directory: root))
        let egg = await store.eggData()
        XCTAssertEqual(egg, png)
        XCTAssertEqual(ArtworkURLProtocol.state.urls, [DigimonCatalog.find(2003)!.imageURL, DigimonArtwork.source(for: "digitama-adventure")!.url])
    }
    func testPendantCannotUseLegacyCandyCacheOnFirstDownloadFailure() {
        let result = ItemIconView.initialImage(kind: .rareCandy, asset: { key in
            XCTAssertEqual(key, "evolution-tag")
            return nil
        }, legacy: { _ in
            XCTFail("Old rare-candy pixels cannot replace the Pendant")
            return NSImage(size: NSSize(width: 3, height: 2))
        })
        XCTAssertNil(result)
        let oldItem = NSImage(size: NSSize(width: 3, height: 2))
        XCTAssertTrue(ItemIconView.initialImage(kind: .shinyCharm, asset: { _ in nil }, legacy: { _ in oldItem }) === oldItem)
    }

    func testConcurrentSpriteViewsReuseOneImageAndWarmMemorySurvivesDiskRemoval() async throws {
        let artDirectory = root.appendingPathComponent("external-artwork-v1")
        let cache = DigimonArtworkCache(directory: artDirectory, session: session)
        let store = SpriteStore(directory: root, artworkCache: cache)
        ArtworkURLProtocol.state.configure([.init(status: 200, data: png)])
        var first: NSImage?
        var second: NSImage?
        let firstTask = Task { @MainActor in first = await SpriteLoader.image(speciesID: 2003, store: store) }
        let secondTask = Task { @MainActor in second = await SpriteLoader.image(speciesID: 2003, store: store) }
        await firstTask.value
        await secondTask.value
        let image = try XCTUnwrap(first)
        XCTAssertTrue(second === image, "Concurrent Digimon thumbnails must share decoded image identity")
        let file = try XCTUnwrap(DigimonArtworkCache.cachedURL(for: "species-2003", directory: artDirectory))
        try FileManager.default.removeItem(at: file)
        XCTAssertTrue(SpriteLoader.cachedImage(speciesID: 2003, directory: root) === image)
        let repeated = await SpriteLoader.image(speciesID: 2003, store: store)
        XCTAssertTrue(repeated === image)
        XCTAssertEqual(ArtworkURLProtocol.state.urls.count, 1)
    }

    func testLiveOriginalSourcesWhenRequested() async throws {
        guard ProcessInfo.processInfo.environment["DIGITOKEN_VALIDATE_ARTWORK"] == "1" else {
            throw XCTSkip("Opt-in live validation of all 489 remote originals")
        }
        let live = DigimonArtworkCache(directory: root.appendingPathComponent("live"))
        let keys = DigimonArtwork.sources.keys.sorted()
        var failures: [String] = []
        for offset in stride(from: 0, to: keys.count, by: 8) {
            let chunk = Array(keys[offset..<min(offset + 8, keys.count)])
            let missing = await withTaskGroup(of: String?.self) { group in
                for key in chunk {
                    group.addTask {
                        guard let bytes = await live.data(for: key), DigimonArtworkCache.validImage(bytes) else { return key }
                        return nil
                    }
                }
                var missing: [String] = []
                for await key in group { if let key { missing.append(key) } }
                return missing
            }
            failures += missing
        }
        XCTAssertEqual(failures, [], "Live source failures: \(failures)")
        print("LIVE ARTWORK: \(keys.count - failures.count)/\(keys.count) originals downloaded and decoded, including artist-page resolution")
    }

}
