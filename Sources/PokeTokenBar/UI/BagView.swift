import SwiftUI

/// 가방(인벤토리) — 소유 아이템 카드 + 사용. 빈 상태는 움직이는 잠만보(컬렉션의 피카츄 패턴).
@MainActor
struct BagView: View {
    let store: CompanionStore
    let nav: PopoverNavigation

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                CyberSectionHeading(number: "03", title: "ITEM STORAGE")
                CyberGuidePanel(language: store.language, compact: !store.ownedItems.isEmpty)
                if store.ownedItems.isEmpty {
                    emptyState
                } else {
                    ForEach(store.ownedItems, id: \.kind) { item in
                        ItemCard(store: store, nav: nav, kind: item.kind, count: item.count)
                    }
                }
            }.reservesScrollerLane()
        }.frame(height: 520)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text(store.l.bagEmptyTitle).font(.callout.weight(.semibold))
            Button(store.l.shop) { nav.tab = .shop }
                .buttonStyle(TerminalCommandStyle(prominent: true)).tint(CyberPalette.cyan)
                .controlSize(.small)
        }.frame(maxWidth: .infinity).padding(.vertical, 24).cyberPanel()
    }
}

/// 아이템 1장 — 아이콘·이름·개수·설명 + 인라인 확인 사용.
/// 확인은 인라인(버튼 morph) — .sheet/.alert 금지: transient 팝오버가 닫힐 때 고아 시트가
/// 이후 클릭을 먹통내는 기존 결함(PopoverView 주석) 회피.
@MainActor
private struct ItemCard: View {
    let store: CompanionStore
    let nav: PopoverNavigation
    let kind: ItemKind
    let count: Int
    @State private var confirming = false
    @State private var candyCount = 1

    private var selectedCandyCount: Int { min(candyCount, max(1, store.maxRareCandyUseCount)) }

    var body: some View {
        let l = store.l
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                ItemIconView(kind: kind, size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(l.itemName(kind)).font(.callout.weight(.semibold))
                        if !kind.isPassive {   // 보유형은 개수 개념이 없음(1회 구매·영구)
                            Text("×\(count)").font(.caption.weight(.bold))
                                .foregroundStyle(CyberPalette.muted).monospacedDigit()
                        }
                        Spacer(minLength: 4)
                        if kind == .rareCandy, store.canUseRareCandy {
                            Stepper(value: $candyCount, in: 1...max(1, store.maxRareCandyUseCount)) {
                                Text("×\(selectedCandyCount)").font(.callout.weight(.semibold)).monospacedDigit()
                            }
                            .fixedSize()
                            .accessibilityLabel(l.itemName(.rareCandy))
                            .accessibilityValue("\(selectedCandyCount)")
                        }
                    }
                    Text(l.itemDescription(kind))
                        .font(.caption).foregroundStyle(CyberPalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if kind == .rareCandy, let preview = store.planRareCandyUse(count: selectedCandyCount) {
                if preview.graduates {
                    Text(l.candyGraduates).font(.caption2).foregroundStyle(CyberPalette.muted)
                }
                if preview.discardedXP > 0 {
                    Text(l.candyDiscardedXP(TokenFormatter.compact(preview.discardedXP)))
                        .font(.caption2).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
                } else if preview.evolves && !preview.graduates {
                    Text(l.candyCarryoverXP(TokenFormatter.compact(preview.carryoverXP)))
                        .font(.caption2).foregroundStyle(CyberPalette.muted).fixedSize(horizontal: false, vertical: true)
                }
            }
            useControls(l)
        }
        .padding(10)
        .cyberPanel()
        .onChange(of: store.maxRareCandyUseCount) { _, _ in
            candyCount = selectedCandyCount
        }
    }

    /// 이 아이템을 지금 쓸 수 있나 (kind 별 — 사탕은 라인 로딩 필요, 민트는 활성 포켓몬만).
    private var canUse: Bool {
        switch kind {
        case .rareCandy: return store.canUseRareCandy
        case .mint:      return store.canUseMint
        default: return false   // 보유형 — 사용 개념 없음(상시 효과)
        }
    }
    /// 사용 컨트롤 효과 힌트 ("+XP" / "성격 랜덤 변경").
    private func effectHint(_ l: L) -> String {
        switch kind {
        case .rareCandy: return "+\(TokenFormatter.compact(selectedCandyCount * RareCandy.xp)) XP"
        case .mint:      return l.mintEffectHint
        case .shinyCharm: return l.shinyCharmEffectHint
        default: return l.digimonUI("Used for evolution")
        }
    }
    private func performUse() {
        switch kind {
        case .rareCandy: _ = store.useRareCandy(count: selectedCandyCount)
        case .mint:      _ = store.useMint()
        default: break   // 보유형 — 사용 동작 없음
        }
    }

    @ViewBuilder
    private func useControls(_ l: L) -> some View {
        if kind.isEvolutionItem {
            Text(l.digimonUI("Use from evolution selection · one consumed at confirmation"))
                .font(.caption2).foregroundStyle(CyberPalette.cyan)
        } else if kind.isPassive {
            // 보유형(이로치 부적) — 사용 버튼 대신 상시 효과 표시.
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill").font(.caption2).foregroundStyle(.green)
                Text(l.shinyCharmEffectHint).font(.caption2.weight(.semibold)).foregroundStyle(.green)
                Spacer()
            }
        } else if canUse {
            if confirming {
                HStack(spacing: 8) {
                    Text(l.useOnCurrent(store.displayName))
                        .font(.caption2).foregroundStyle(CyberPalette.muted).lineLimit(1)
                    Spacer()
                    Button(kind == .rareCandy ? "\(l.use) ×\(selectedCandyCount)" : l.use) { useNow() }
                        .buttonStyle(TerminalCommandStyle(prominent: true)).controlSize(.small)
                    Button(l.cancel) { confirming = false }
                        .buttonStyle(.borderless).controlSize(.small)
                }
            } else {
                HStack {
                    Text(effectHint(l))
                        .font(.caption2).foregroundStyle(CyberPalette.muted.opacity(0.85)).monospacedDigit()
                    Spacer()
                    Button(l.useItem) { confirming = true }
                        .buttonStyle(TerminalCommandStyle()).controlSize(.small)
                }
            }
        } else {
            // 알(부화 전)/활성 없음/(사탕만)라인 미로딩 — 비활성 + 사유
            Text(store.isEgg ? l.useAfterHatch : l.useNeedsPokemon)
                .font(.caption2).foregroundStyle(CyberPalette.muted.opacity(0.85))
        }
    }

    /// 사용 → 항상 Home 탭으로 전환(진화/졸업 연출·"+XP"·성격 변경 토스트는 Home 의 CompanionHeader 에서 재생).
    private func useNow() {
        confirming = false
        performUse()
        nav.tab = .home
    }
}
