import SwiftUI

struct DigimonInfo: Decodable {
    let id: Int
    let level: String
    let type: String
    let attribute: String
    let moves: [String]
    let excerpt: String
    let source: String
    static let records = load("species-info")
    static let englishRecords = load("species-info-en")
    static func record(_ id: Int, language: AppLanguage) -> DigimonInfo? {
        (language == .ko ? records : englishRecords)[id]
    }
    private static func load(_ name: String) -> [Int: DigimonInfo] {
        struct Manifest: Decodable { let records: [DigimonInfo] }
        guard let url = DigimonCatalog.resource(name, extension: "json"),
              let data = try? Data(contentsOf: url), let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else { return [:] }
        return Dictionary(uniqueKeysWithValues: manifest.records.map { ($0.id, $0) })
    }
}

@MainActor
struct DigimonInfoView: View {
    let speciesID: Int
    var language: AppLanguage = .ko
    private var l: L { L(language) }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(l.digimonUI("Digimon information")).font(.headline)
            if let info = DigimonInfo.record(speciesID, language: language), !info.excerpt.isEmpty {
                Text([info.level, info.type, info.attribute].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(CyberPalette.cyan)
                if [10349,10390,10426].contains(speciesID) {
                    Text(l.digimonUI("This game variant has no separate profile; the official base-form profile is shown."))
                        .font(.caption2).foregroundStyle(CyberPalette.yellow)
                }
                Text(l.digimonUI("Official profile classification · may differ from the game stage."))
                    .font(.caption2).foregroundStyle(CyberPalette.muted)
                Text("“" + info.excerpt + "”").font(.callout).textSelection(.enabled)
                Text(l.digimonUI(language == .ko ? "Official Korean profile excerpt · wording follows the official translation." : "Official English profile excerpt · wording follows the official translation."))
                    .font(.caption2).foregroundStyle(CyberPalette.muted)
                if !info.moves.isEmpty {
                    Text(l.digimonUI("Moves")).font(.subheadline.bold())
                    Text(info.moves.joined(separator: " · ")).font(.callout)
                }
                if let url = URL(string: info.source) { Link(l.digimonUI("Read the full official profile ↗"), destination: url).font(.caption) }
            } else {
                Text(l.digimonUI("Official profile information is unavailable.")).font(.callout)
            }
        }.padding(12).cyberPanel()
    }
}
