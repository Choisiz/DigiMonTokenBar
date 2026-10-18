import XCTest
import SwiftUI
@testable import PokeTokenBar

@MainActor
final class DigimonTests: XCTestCase {
    func testPackagedResourcesDoNotProbeMissingPackageBundle() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let app = root.appendingPathComponent("Isolated.app")
        let resources = app.appendingPathComponent("Contents/Resources/Digimon")
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        let plist: [String: String] = ["CFBundleIdentifier": "test.digimon.resources", "CFBundlePackageType": "APPL"]
        try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            .write(to: app.appendingPathComponent("Contents/Info.plist"))
        try Data(contentsOf: XCTUnwrap(DigimonCatalog.resource("x-antibody-a", extension: "png"))).write(to: resources.appendingPathComponent("native-art.png"))
        let bundle = try XCTUnwrap(Bundle(url: app))
        var packageLookups = 0
        func absentPackage() -> Bundle {
            packageLookups += 1
            XCTFail("Packaged resource lookup consulted the missing SwiftPM bundle")
            return .main
        }
        XCTAssertNil(DigimonCatalog.resource("native-art", extension: "jpg", applicationBundle: bundle, packageBundle: absentPackage))
        XCTAssertNotNil(DigimonCatalog.resource("native-art", extension: "png", applicationBundle: bundle, packageBundle: absentPackage))
        XCTAssertNil(DigimonCatalog.resource("optional-missing", extension: "png", applicationBundle: bundle, packageBundle: absentPackage))
        XCTAssertEqual(packageLookups, 0)
        // Raw test executables still use SwiftPM's own packaged resources.
        XCTAssertNotNil(DigimonCatalog.resource("time-stranger", extension: "json"))
    }
    func testCatalogAndRemoteAssetMappingAreComplete() async throws {
        let provider = DigimonProvider.shared
        let bases = try await provider.baseSpeciesIndex()
        XCTAssertEqual(bases.count, 7)
        XCTAssertEqual(Set(DigimonCatalog.species.map(\.id)).count, 475)
        for route in DigimonCatalog.routes {
            let line = try await provider.line(baseSpeciesID: route[0])
            XCTAssertEqual(line.totalForms, 6)
            XCTAssertEqual(line.tree.finalIDs, [route.last!])
            for id in route {
                XCTAssertNotNil(line.tree.node(withID: id))
                XCTAssertFalse(line.localizedName(id, .ko).hasPrefix("#"))
                XCTAssertEqual(SpriteStore.spriteURL(speciesID: id, animated: true, shiny: false).scheme, "https")
                XCTAssertNotNil(DigimonArtwork.source(for: DigimonArtwork.speciesKey(id)))
            }
        }
        let nonBase = try await provider.baseSpecies(id: 2003)
        XCTAssertNil(nonBase)
        do {
            _ = try await provider.line(baseSpeciesID: 25)
            XCTFail("Pokémon IDs must never hatch through the Digimon provider")
        } catch {}
    }

    func testBothRoutesGrowAndPersistWithoutPokemonFeatures() async throws {
        for route in DigimonCatalog.routes {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let suite = "digimon-tests-\(UUID())"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
            let file = directory.appendingPathComponent("state.json")
            let store = CompanionStore(fileURL: file, defaults: defaults)
            await store.hatch(baseID: route[0])
            XCTAssertEqual(store.currentSpeciesID, route[0])
            XCTAssertFalse(try XCTUnwrap(store.state.active).isShiny)
            XCTAssertNil(store.state.active?.dittoDisguise)
            XCTAssertFalse(store.purchasableItems.contains(.shinyCharm))
            XCTAssertFalse(store.canBuyEgg(.rare))
            for id in route.dropFirst() {
                XCTAssertTrue(store.chooseEvolution(id))
                if store.currentSpeciesID != id { store.applyUsage(store.tokensToNext) }
                XCTAssertEqual(store.currentSpeciesID, id)
            }
            XCTAssertTrue(store.isEvolutionRegistered(route.last!))
            for _ in 0..<30 {
                guard let next = store.trainingEvolutionChoices.first(where: { store.evolutionRule(to: $0.id).kind == .normal }) else { break }
                XCTAssertTrue(store.chooseEvolution(next.id))
                if store.currentSpeciesID != next.id { store.applyUsage(store.tokensToNext) }
            }
            let finalID = store.currentSpeciesID
            XCTAssertTrue(store.isFinalStage)
            store.applyUsage(store.tokensToNext)
            XCTAssertNil(store.state.active)
            XCTAssertEqual(store.state.dex.last?.finalID, finalID)
            let restored = CompanionStore(fileURL: file, defaults: defaults)
            XCTAssertEqual(restored.state.dex.last?.finalID, finalID)
        }
    }

    func testRegisteredEvolutionAndNewBranchSelection() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("state.json")
        let suite = "digimon-branch-test-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        var seed = CompanionState()
        seed.dex = [DexEntry(baseID: 2001, finalID: 2006, chainOrder: DigimonCatalog.routes[0], rarity: .common, caughtAt: nil)]
        try JSONEncoder().encode(seed).write(to: file)
        let store = CompanionStore(fileURL: file, defaults: defaults)
        await store.hatch(baseID: 2001)
        store.applyUsage(1234)
        let xp = store.state.active?.profile?.growthTokens
        for id in [2002, 2003, 2004] {
            XCTAssertTrue(store.chooseEvolution(id))
            XCTAssertEqual(store.currentSpeciesID, id)
            XCTAssertEqual(store.state.active?.usedAtStage, 1234)
            XCTAssertEqual(store.state.active?.profile?.growthTokens, xp)
        }
        XCTAssertFalse(store.chooseEvolution(2006), "WarGreymon is not a direct Greymon candidate")
        XCTAssertTrue(store.chooseEvolution(10278))
        XCTAssertEqual(store.currentSpeciesID, 2004)
        XCTAssertEqual(store.selectedEvolutionID, 10278)
        store.applyUsage(store.tokensToNext + 77)
        XCTAssertEqual(store.currentSpeciesID, 10278)
        XCTAssertEqual(store.state.active?.usedAtStage, 77)
        XCTAssertNil(store.selectedEvolutionID)
        XCTAssertTrue(store.isEvolutionRegistered(10278))
        XCTAssertTrue(store.dexSpecies.contains { $0.id == 10278 })
        let restored = CompanionStore(fileURL: file, defaults: defaults)
        XCTAssertEqual(restored.currentSpeciesID, 10278)
        XCTAssertEqual(restored.state.active?.usedAtStage, 77)
    }

    func testGameGraphCyclesCannotRevisitAForm() {
        XCTAssertTrue(DigimonCatalog.find(10456)!.next.contains(10455))
        XCTAssertFalse(DigimonCatalog.choices(from: 10456, visited: [10455,10456]).contains { $0.id == 10455 })
    }

    func testStaticArtDoesNotRetryMissingAnimations() async {
        var fallbacks = 0
        var waits = 0
        let frames = await SpriteLoader.recoveringAnimationFrames(
            speciesID: 2003, shiny: false,
            waitBeforeRetry: { _ in waits += 1 },
            onUnavailable: { fallbacks += 1 })
        XCTAssertTrue(frames.isEmpty)
        XCTAssertEqual(fallbacks, 1)
        XCTAssertEqual(waits, 0)
    }

    func testForkStorageAndLocalization() {
        XCTAssertEqual(SaveEnvelope.formatID, "digitokenbar.save")
        XCTAssertEqual(AppStatePaths.directory().lastPathComponent, "DigiTokenBar")
        XCTAssertFalse(L(.ko).representativePokemonLabel.contains("포켓몬"))
    }

    /// Production SpriteView rendering with sample names; this is a catalog preview, not a live screenshot.
    func testRenderCatalogPreview() throws {
        guard let path = ProcessInfo.processInfo.environment["DIGITOKEN_PREVIEW_PATH"] else { return }
        let preview = VStack(alignment: .leading, spacing: 16) {
            Text("DigiTokenBar").font(.largeTitle.bold())
            Text("토큰으로 키우는 나의 디지몬").foregroundStyle(.secondary)
            ForEach(DigimonCatalog.routes, id: \.self) { route in
                HStack(spacing: 10) {
                    ForEach(route, id: \.self) { id in
                        VStack(spacing: 8) {
                            SpriteView(speciesID: id, size: 90, animated: false)
                            Text(DigimonCatalog.find(id)!.korean).font(.caption)
                        }.frame(width: 100)
                    }
                }
            }
            Text("알 부화 → 토큰 사용으로 진화 → 최종체 수집").font(.callout)
        }.padding(28).background(Color.white).foregroundStyle(Color.black)
        let renderer = ImageRenderer(content: preview)
        renderer.scale = 2
        let image = try XCTUnwrap(renderer.nsImage)
        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(image.tiffRepresentation)))
        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: path))
    }
}
