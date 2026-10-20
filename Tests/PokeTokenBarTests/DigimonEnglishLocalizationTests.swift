import XCTest
import JavaScriptCore
@testable import PokeTokenBar

@MainActor
final class DigimonEnglishLocalizationTests: XCTestCase {
    private func assertEnglish(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(text.isEmpty, file: file, line: line)
        XCTAssertNil(text.range(of: "[가-힣]", options: .regularExpression), text, file: file, line: line)
    }

    func testEnglishAlertRequirementsAndShopUseSelectedLanguage() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "digimon-english-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer {
            try? FileManager.default.removeItem(at: directory)
            defaults.removePersistentDomain(forName: suite)
        }
        let store = CompanionStore(fileURL: directory.appendingPathComponent("state.json"), defaults: defaults)
        store.setLanguage(.en)
        for rule in DigimonEvolutionRules.rules {
            assertEnglish(rule.localizedMethod(store.l))
            assertEnglish(store.evolutionRequirement(from: rule.source, to: rule.target))
        }
        for item in ItemKind.allCases {
            assertEnglish(store.l.itemName(item))
            assertEnglish(store.l.itemDescription(item))
        }
        assertEnglish(store.continuationTitle(2006))
        assertEnglish(try XCTUnwrap(store.continuationBlockReason(2006)))
        XCTAssertTrue(store.evolutionRequirement(from: 2006, to: 10430).contains("WarGreymon"))
        XCTAssertEqual(L(.ko).itemName(.xAntibodyA), "X항체 A")
    }

    func testEnglishProfilesHaveMatchingIDsAndNoKoreanFallback() throws {
        XCTAssertEqual(Set(DigimonInfo.englishRecords.keys), Set(DigimonInfo.records.keys))
        XCTAssertGreaterThan(DigimonInfo.englishRecords.values.filter { !$0.excerpt.isEmpty }.count, 450)
        for id in DigimonInfo.records.keys {
            let info = try XCTUnwrap(DigimonInfo.record(id, language: .en))
            XCTAssertTrue(info.source.contains("/reference_en/"))
            for text in [info.level, info.type, info.attribute, info.excerpt] + info.moves where !text.isEmpty {
                assertEnglish(text)
            }
        }
        let agumon = try XCTUnwrap(DigimonInfo.record(2003, language: .en))
        XCTAssertEqual(agumon.moves, ["Pepper Breath"])
        XCTAssertNotEqual(agumon.excerpt, DigimonInfo.record(2003, language: .ko)?.excerpt)
        XCTAssertNil(DigimonInfo.record(-1, language: .en))
    }

    func testProductionSceneLocalizesEveryPhaseAndControl() throws {
        let url = try XCTUnwrap(CyberAssets.url(name: "evolution-scene", ext: "html"))
        let html = try String(contentsOf: url, encoding: .utf8)
        let script = try XCTUnwrap(html.components(separatedBy: "<script>'use strict';").last?.components(separatedBy: "</script>").first)
        for language in ["en", "ko"] {
            let context = try XCTUnwrap(JSContext())
            context.exceptionHandler = { _, error in XCTFail(error?.toString() ?? "JavaScript error") }
            context.evaluateScript("""
            var elements={};function element(id){return elements[id]||(elements[id]={textContent:'',disabled:false,hidden:false,style:{},classList:{toggle(){},add(){}},lastChild:{},setAttribute(){},addEventListener(){},getContext(){return {}},getBoundingClientRect(){return {width:420}}});}
            var document={documentElement:{},getElementById:element,querySelector:element,querySelectorAll(){return [0,1,2,3].map(i=>element('step'+i))},addEventListener(){}};
            var window={matchMedia(){return {matches:false}},addEventListener(){},devicePixelRatio:1};
            function cancelAnimationFrame(){};function requestAnimationFrame(){};
            """)
            // Exercise production initialization and phase text without downloading artwork or running canvas animation.
            let prefix = script.components(separatedBy: "fit();Promise.all")[0]
            context.evaluateScript(prefix.replacingOccurrences(of: "__EVOLUTION_CONFIG__", with: "{language:'\(language)',kind:'fusion',result:'Omnimon',left:'WarGreymon',right:'MetalGarurumon',art:{}}"))
            for phase in -1...3 {
                context.evaluateScript("updatePhase(\(phase))")
                for id in ["phase", "title", "detail", "start"] {
                    let text = try XCTUnwrap(context.evaluateScript("document.getElementById('\(id)').textContent")?.toString())
                    if language == "en" { assertEnglish(text) }
                }
            }
            XCTAssertEqual(context.evaluateScript("tr('Evolution complete')")?.toString(), language == "en" ? "Evolution complete" : "진화 완료")
        }
    }
}
