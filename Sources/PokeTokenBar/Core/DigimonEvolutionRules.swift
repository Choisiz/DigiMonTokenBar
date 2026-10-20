import Foundation

enum DigimonEvolutionKind: String, Codable, Sendable { case normal, fusion, item, buff, unverified }

struct DigimonEvolutionRule: Decodable, Sendable {
    let source: Int
    let target: Int
    let kind: DigimonEvolutionKind
    let ingredients: [Int]
    var item: ItemKind? = nil
    var dailyTokens: Int? = nil
    var method: String? = nil
    let reference: String

    func localizedMethod(_ l: L) -> String {
        let methods = ["분류 검토 중": "Classification under review · Evolution unavailable",
            "아이템·X항체": "X-Antibody evolution", "아이템·데이터": "Data evolution",
            "아이템·스피릿": "Spirit evolution", "아이템·캡슐": "Armor evolution",
            "일반·버스트": "Burst evolution", "일반·복귀": "Mode reversion",
            "일반·성장": "Ordinary evolution", "일반·유대": "Bond evolution",
            "일반·해방": "Release evolution", "조그레스·힘 계승": "Jogress · Power inheritance"]
        if let method, let english = methods[method] { return l.digimonUI(english) }
        switch kind {
        case .fusion: return l.digimonUI("Jogress evolution")
        case .item: return l.digimonUI("Item evolution")
        case .buff: return l.digimonUI("Release evolution")
        case .unverified: return l.digimonUI("Classification under review · Evolution unavailable")
        case .normal: return l.digimonUI("Ordinary growth · Game evolution route")
        }
    }

}

enum DigimonEvolutionRules {
    private struct Manifest: Decodable { let rules: [DigimonEvolutionRule]; let removedEdges: [[Int]]?; let addedEdges: [[Int]]? }
    private static let manifest: Manifest = {
        guard let url = DigimonCatalog.resource("evolution-rules", extension: "json"),
              let data = try? Data(contentsOf: url), let result = try? JSONDecoder().decode(Manifest.self, from: data)
        else { preconditionFailure("Missing evolution rules") }
        return result
    }()
    static func nextIDs(from id: Int) -> [Int] {
        let m = manifest
        let removed = Set((m.removedEdges ?? []).filter { $0[0] == id }.map { $0[1] })
        return (DigimonCatalog.find(id)?.next ?? []).filter { !removed.contains($0) } + (m.addedEdges ?? []).filter { $0[0] == id }.map { $0[1] }
    }
    static let rules = manifest.rules
    /// Ordinary-only reachability, excluding the realised path so mode-change cycles cannot offer a return trip.
    static func missingOrdinaryDescendants(from source: Int, visited: [Int] = [], isCollected: (Int) -> Bool) -> [Int] {
        var seen = Set(visited + [source]), pending = [source], missing = Set<Int>()
        while let id = pending.popLast() {
            for next in nextIDs(from: id) where rule(from: id, to: next).kind == .normal {
                guard seen.insert(next).inserted else { continue }
                if !isCollected(next) { missing.insert(next) }
                pending.append(next)
            }
        }
        return missing.sorted { DigimonCatalog.displayNumber(for: $0) < DigimonCatalog.displayNumber(for: $1) }
    }

    static func rule(from source: Int, to target: Int) -> DigimonEvolutionRule {
        rules.first { $0.source == source && $0.target == target }
            ?? DigimonEvolutionRule(source: source, target: target, kind: .normal, ingredients: [], reference: DigimonCatalog.find(target)?.source ?? "")
    }
}

struct DigimonEvolutionScene: Identifiable, Equatable {
    let id = UUID()
    let source: Int
    let target: Int
    let kind: DigimonEvolutionKind
    let ingredients: [Int]
    var committed: Bool
}
