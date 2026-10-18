import SwiftUI

@MainActor
struct DigimonEvolutionPicker: View {
    let store: CompanionStore
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.l.chooseDigivolution).font(.title2.bold())
                    Text(store.displayName).font(.headline).foregroundStyle(CyberPalette.cyan)
                }
                Spacer()
                Button(store.l.digivolutionDone, action: onClose)
            }
            Text(store.isContinuingSpecialTraining ? store.l.digimonUI("Only paths to uncollected ordinary forms are shown. Registered intermediate forms are free transit.") : store.l.digivolutionChoiceHint).font(.callout)
            Text(store.language == .ko ? store.l.digimonUI("Fusion, item, release, Burst and Bond evolution require a manual start after meeting their conditions.") : "Fusion and item evolutions have separate requirements and never evolve automatically.")
                .font(.caption).foregroundStyle(CyberPalette.cyan)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(store.trainingEvolutionChoices, id: \.id) { species in
                        let registered = store.isEvolutionRegistered(species.id)
                        let rule = store.evolutionRule(to: species.id)
                        let special = rule.kind != .normal
                        let ready = store.specialEvolutionReady(species.id)
                        let selected = store.selectedEvolutionID == species.id
                        HStack(spacing: 12) {
                            SpriteView(speciesID: species.id, size: 56, animated: false)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(species.names[store.language.rawValue] ?? species.english).font(.headline)
                                Text(registered ? store.l.notebookRegistered : store.l.notebookUnregistered)
                                    .font(.caption).foregroundStyle(registered ? CyberPalette.yellow : CyberPalette.muted)
                                if special {
                                    Text(store.l.digimonUI("Requirements · ") + store.evolutionRequirement(from: store.currentSpeciesID ?? 0, to: species.id))
                                        .font(.caption2).foregroundStyle(CyberPalette.cyan)
                                        .fixedSize(horizontal: false, vertical: true)
                                } else if !registered {
                                    Text(store.l.toNextEvolution(TokenFormatter.compact(store.tokensToNext)))
                                        .font(.caption2).foregroundStyle(CyberPalette.muted)
                                }
                            }
                            Spacer(minLength: 0)
                            Button(special ? (ready ? store.l.digimonUI("Evolution screen") : store.l.digimonUI("Requirements not met")) : selected ? store.l.digivolutionTraining : registered ? store.evolutionChoiceAction(species.id) : store.l.startDigivolutionTraining) {
                                if store.chooseEvolution(species.id), !registered { onClose() }
                            }
                            .buttonStyle(.bordered)
                            .disabled((special ? !ready : selected) || store.isHatching || store.currentLine == nil)
                            .accessibilityIdentifier("digimon.evolve.\(species.id)")
                        }
                        .padding(12)
                        .cyberPanel(accent: registered ? CyberPalette.yellow : CyberPalette.cyan)
                    }
                    if store.trainingEvolutionChoices.isEmpty {
                        Text(store.l.digivolutionEnd).font(.callout).padding()
                    }
                }
                .reservesScrollerLane()
            }
            Text(store.l.digivolutionBankHint).font(.caption2).foregroundStyle(CyberPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: PopoverMetrics.width, height: 640)
        .cyberSurface()
    }
}

/// All ready collection recipes, independent of the partner currently being raised.
@MainActor
struct DigimonSpecialEvolutionPicker: View {
    @Environment(PopoverNavigation.self) private var navigation
    let store: CompanionStore
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(store.l.digimonUI("Evolution and training")).font(.title2.bold())
                Spacer()
                Button(store.l.digimonUI("Home"), action: onClose).buttonStyle(TerminalCommandStyle())
            }
            Text(store.l.digimonUI("Special evolution preserves current training. Continue or resume to park the current partner and switch."))
                .font(.callout).foregroundStyle(CyberPalette.muted)
            if let error = store.trainingSwitchError { Text(error).font(.caption).foregroundStyle(.orange) }
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(store.readySpecialEvolutionRules, id: \.target) { rule in
                        if let target = DigimonCatalog.find(rule.target) {
                            HStack(alignment: .top, spacing: 12) {
                                SpriteView(speciesID: target.id, size: 56, animated: false)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(store.language.resolveName(target.names) ?? target.english).font(.headline)
                                    Text(store.l.digimonUI("Source · ") + (DigimonCatalog.find(rule.source)?.korean ?? ""))
                                        .font(.caption).foregroundStyle(CyberPalette.muted)
                                    Text(store.evolutionRequirement(from: rule.source, to: rule.target))
                                        .font(.caption2).foregroundStyle(CyberPalette.cyan)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                                Button(store.l.digimonUI("Evolution screen")) { _ = store.prepareSpecialEvolution(rule) }
                                    .buttonStyle(TerminalCommandStyle()).controlSize(.small)
                                    .disabled(store.isHatching || store.evolutionScene != nil)
                                    .accessibilityIdentifier("digimon.special.\(rule.target)")
                            }.padding(12).cyberPanel()
                        }
                    }
                    if !store.continuableSpecialDigimon.isEmpty {
                        Text(store.l.digimonUI("Continue a special result")).font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(store.continuableSpecialDigimon, id: \.id) { species in
                            HStack(alignment: .top, spacing: 12) {
                                SpriteView(speciesID: species.id, size: 56, animated: false)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(store.language.resolveName(species.names) ?? species.english).font(.headline)
                                    Text(store.l.digimonUI("Ordinary evolution · normal growth token requirements"))
                                        .font(.caption2).foregroundStyle(CyberPalette.cyan)
                                    Text(store.l.digimonUI("Uncollected · ") + store.missingOrdinaryTargets(species.id).map { store.language.resolveName($0.names) ?? $0.english }.joined(separator: " · "))
                                        .font(.caption2).foregroundStyle(CyberPalette.cyan).fixedSize(horizontal: false, vertical: true)
                                    Text(store.continuationBlockReason(species.id) ?? store.l.digimonUI("Park the current Digimon. It returns automatically when training finishes."))
                                        .font(.caption2).foregroundStyle(CyberPalette.muted).fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                                Button(store.l.digimonUI("Continue training")) {
                                    if store.continueSpecialDigimon(species.id) { navigation.reset() }
                                }.buttonStyle(TerminalCommandStyle()).controlSize(.small).disabled(store.continuationBlockReason(species.id) != nil)
                            }.padding(12).cyberPanel()
                        }
                    }
                    if !store.state.storedTraining.isEmpty {
                        Text(store.l.digimonUI("Stored training · 1 / 1")).font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(store.state.storedTraining) { slot in
                            if let mon = slot.mon {
                            HStack(alignment: .top, spacing: 12) {
                                SpriteView(speciesID: mon.currentID, size: 56, animated: false)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(DigimonCatalog.find(mon.currentID).map { store.language.resolveName($0.names) ?? $0.english } ?? store.l.digimonUI("Digimon"))
                                        .font(.headline)
                                    let used = mon.usedAtStage
                                    let total = PokemonBalance.scaled(mon.phaseThreshold, by: store.growthDifficulty)
                                    Text(store.l.digimonUI("Stored data · ") + TokenFormatter.compact(used) + " / " + TokenFormatter.compact(total))
                                        .font(.caption2).foregroundStyle(CyberPalette.cyan)
                                    Text(store.l.digimonUI("Parked partners do not grow.")).font(.caption2).foregroundStyle(CyberPalette.muted)
                                }
                                Spacer(minLength: 0)
                                Button(store.l.digimonUI("Resume training")) {
                                    if store.resumeTraining(slot.id) { navigation.reset() }
                                }.buttonStyle(TerminalCommandStyle()).controlSize(.small).disabled(!store.canSwitchTraining)
                            }.padding(12).cyberPanel()
                            }
                        }
                    }
                    if store.readySpecialEvolutionRules.isEmpty && store.continuableSpecialDigimon.isEmpty && store.state.storedTraining.isEmpty {
                        Text(store.l.digimonUI("No special evolution, continuation or stored training is available.")).font(.callout).padding()
                    }
                }
                .reservesScrollerLane()
            }
            Text(store.l.digimonUI("Collection records are retained. One item is consumed at evolution start; daily-token conditions are rechecked before starting."))
                .font(.caption2).foregroundStyle(CyberPalette.muted)
        }.padding(20).frame(width: PopoverMetrics.width, height: 640).cyberSurface()
    }
}
