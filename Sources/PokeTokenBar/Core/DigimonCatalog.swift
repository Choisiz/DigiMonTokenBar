import Foundation

/// Versioned Time Stranger graph. Internal IDs of the original twelve partners never change.
/// Game/DAPI identifiers are external keys only; existing saves continue using local IDs.
enum DigimonCatalog {
    struct Species: Decodable, Sendable {
        let id: Int
        let gameID: Int
        let name: String
        let stage: Int
        let generation: String
        let next: [Int]
        let dapiID: Int?
        let source: String
        var english: String { name }
        var korean: String { koreanNames[id] ?? name }
        var names: [String: String] { ["en": english, "ko": korean] }
        var imageURL: URL {
            DigimonArtwork.source(for: DigimonArtwork.speciesKey(id))!.url
        }
    }
    private struct Manifest: Decodable { let records: [Species] }
    static func resource(_ name: String, extension ext: String,
                         applicationBundle: Bundle = .main,
                         packageBundle: () -> Bundle = { Bundle.module }) -> URL? {
        if let url = applicationBundle.url(forResource: name, withExtension: ext, subdirectory: "Digimon") { return url }
        // The assembled app carries Digimon directly in Contents/Resources. A missing
        // optional format must return nil, not initialize SwiftPM's fatal bundle accessor.
        if applicationBundle.bundleURL.pathExtension == "app" { return nil }
        return packageBundle().url(forResource: name, withExtension: ext, subdirectory: "Digimon")
    }
    static let species: [Species] = {
        guard let url = resource("time-stranger", extension: "json"),
              let data = try? Data(contentsOf: url), let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else {
            preconditionFailure("Missing or invalid Time Stranger catalog")
        }
        return manifest.records
    }()
    private static let byID = Dictionary(uniqueKeysWithValues: species.map { ($0.id, $0) })
    static func find(_ id: Int) -> Species? { byID[id] }
    /// External display number only; all persistence and graph keys remain local IDs.
    static func displayNumber(for id: Int) -> Int { find(id)?.gameID ?? id }
    static func numberLabel(for id: Int) -> String { String(format: "#%03d", displayNumber(for: id)) }
    static var roots: [Species] { species.filter { $0.stage == 0 } }
    /// Reference routes retained for previews and save compatibility; evolution uses the graph.
    static let routes = [[2001, 2002, 2003, 2004, 2005, 2006], [2007, 2008, 2009, 2010, 2011, 2012]]
    static func choices(from id: Int, visited: [Int]) -> [Species] {
        DigimonEvolutionRules.nextIDs(from: id).filter { !visited.contains($0) }.compactMap(find)
    }
    static func reachableIDs(from id: Int) -> Set<Int> {
        var seen = Set<Int>(), pending = [id]
        while let next = pending.popLast() {
            guard seen.insert(next).inserted else { continue }
            pending += DigimonEvolutionRules.nextIDs(from: next)
        }
        return seen
    }
    private struct KoreanNames: Decodable {
        struct Entry: Decodable { let id: Int; let korean: String }
        let records: [Entry]
    }
    private static let koreanNames: [Int: String] = {
        guard let url = resource("korean-names", extension: "json"),
              let data = try? Data(contentsOf: url),
              let names = try? JSONDecoder().decode(KoreanNames.self, from: data) else {
            preconditionFailure("Missing Korean Digimon name catalog")
        }
        return Dictionary(uniqueKeysWithValues: names.records.map { ($0.id, $0.korean) })
    }()

}

struct DigimonProvider: PokeProviding {
    static let shared = DigimonProvider()
    func baseSpeciesIndex() async throws -> [BaseSpecies] {
        DigimonCatalog.roots.map { BaseSpecies(id: $0.id, captureRate: 255) }
    }
    func baseSpecies(id: Int) async throws -> BaseSpecies? {
        DigimonCatalog.roots.contains { $0.id == id } ? BaseSpecies(id: id, captureRate: 255) : nil
    }
    func line(baseSpeciesID: Int) async throws -> EvoLine {
        guard DigimonCatalog.find(baseSpeciesID) != nil else { throw URLError(.resourceUnavailable) }
        // A small compatibility tree keeps the original Pokémon presentation contract bounded.
        // The full cyclic graph is never recursively expanded into EvoNode.
        var route = DigimonCatalog.routes.first { $0.first == baseSpeciesID } ?? [baseSpeciesID]
        if route.count == 1 {
            while let next = DigimonCatalog.choices(from: route.last!, visited: route).first, route.count < 12 { route.append(next.id) }
        }
        var tree = EvoNode(speciesID: route.last!, children: [])
        for id in route.dropLast().reversed() { tree = EvoNode(speciesID: id, children: [tree]) }
        let names = Dictionary(uniqueKeysWithValues: DigimonCatalog.species.map { ($0.id, $0.names) })
        return EvoLine(baseID: baseSpeciesID, tree: tree, rarity: .common, names: names)
    }
}
