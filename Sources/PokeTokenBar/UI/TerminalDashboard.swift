import SwiftUI

/// Read-only presentation of measured token composition; never represents a quota.
enum TerminalTraffic {
    static func fractions(_ usage: DailyUsage?) -> [Double] {
        guard let usage else { return [0, 0, 0, 0] }
        let parts = [usage.inputTokens, usage.outputTokens,
                     usage.cacheCreationTokens + usage.cacheReadTokens].map { Double(max(0, $0)) }
        let total = max(Double(usage.totalTokens), parts.reduce(0, +))
        guard total > 0 else { return [0, 0, 0, 0] }
        return (parts + [max(0, total - parts.reduce(0, +))]).map { $0 / total }
    }
}

@MainActor
struct TerminalGrowth: View {
    let value: Double
    let used: Int
    let total: Int
    let label: String
    private var fraction: Double { min(1, max(0, value)) }
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.system(size: 8)).foregroundStyle(CyberPalette.muted)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(TokenFormatter.compact(min(used, total)))
                Text("/ " + TokenFormatter.compact(total)).foregroundStyle(CyberPalette.muted)
                Spacer(minLength: 0)
                Text(String(format: "%.1f%%", fraction * 100)).foregroundStyle(CyberPalette.cyan)
            }.font(.system(size: 11, design: .monospaced)).lineLimit(1).minimumScaleFactor(0.7)
            HStack(spacing: 2) {
                ForEach(0..<20) { index in
                    Parallelogram().fill(Double(index) < fraction * 20 ? CyberPalette.cyan : CyberPalette.line)
                }
            }.frame(height: 5).accessibilityHidden(true)
        }.padding(.top, 5)
            .help(CompanionHeader.progressDetail(used: used, total: total))
            .accessibilityElement(children: .combine)
    }
    private struct Parallelogram: Shape {
        func path(in r: CGRect) -> Path {
            Path { p in
                p.move(to: CGPoint(x: 2, y: 0)); p.addLine(to: CGPoint(x: r.width, y: 0))
                p.addLine(to: CGPoint(x: r.width - 2, y: r.height)); p.addLine(to: CGPoint(x: 0, y: r.height)); p.closeSubpath()
            }
        }
    }
}

@MainActor
struct TerminalTrafficConsole: View {
    let snapshot: ProviderSnapshot?
    let l: L
    let showsCost: Bool
    let onRecap: () -> Void
    private var today: DailyUsage? { snapshot?.today }
    private var total: Int { today?.totalTokens ?? 0 }
    private var colors: [Color] { [CyberPalette.cyan, CyberPalette.yellow, .mint, CyberPalette.muted] }

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 5) {
                side("INPUT", amount: today?.inputTokens ?? 0, caption: l.tokenInput, color: CyberPalette.cyan)
                ZStack {
                    Circle().stroke(CyberPalette.line, lineWidth: 2)
                    let fractions = TerminalTraffic.fractions(today)
                    ForEach(0..<fractions.count, id: \.self) { index in
                        let start = fractions.prefix(index).reduce(0, +)
                        if fractions[index] > 0 {
                            Circle().trim(from: start, to: max(start, start + fractions[index] - 0.012))
                                .stroke(colors[index], style: StrokeStyle(lineWidth: 2, lineCap: .butt))
                                .rotationEffect(.degrees(-90))
                        }
                    }
                    VStack(spacing: 3) {
                        Text(l.todayTokens).font(.system(size: 8)).foregroundStyle(CyberPalette.muted)
                        Text(TokenFormatter.compact(total)).font(.system(size: 23, design: .monospaced))
                            .lineLimit(1).minimumScaleFactor(0.6)
                        Text("TOKENS").font(.system(size: 6, design: .monospaced)).tracking(2).foregroundStyle(CyberPalette.muted)
                    }.padding(6)
                }.frame(width: 100, height: 100)
                    .help("INPUT / OUTPUT / CACHE / OTHER")
                side("OUTPUT", amount: today?.outputTokens ?? 0, caption: l.tokenOutput, color: CyberPalette.yellow)
            }.padding(.vertical, 5)
            HStack {
                Text(l.lang == .ko ? l.digimonUI("PROCESSED DATA") : "PROCESSED DATA").foregroundStyle(CyberPalette.muted)
                Spacer(minLength: 0)
                Text(TokenFormatter.grouped(total)).font(.system(size: 12, design: .monospaced))
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text("tokens").foregroundStyle(CyberPalette.muted)
            }.font(.system(size: 8)).padding(.vertical, 5)
                .overlay(alignment: .top) { Rectangle().fill(CyberPalette.line).frame(height: 0.5) }
                .overlay(alignment: .bottom) { Rectangle().fill(CyberPalette.line).frame(height: 0.5) }
            HStack(spacing: 10) {
                register("WEEK", label: l.thisWeek, value: snapshot?.weekTotal.map { TokenFormatter.compact($0.totalTokens) } ?? "—")
                Rectangle().fill(CyberPalette.line).frame(width: 1, height: 25)
                register("MONTH", label: l.thisMonth, value: snapshot?.monthTotal.map { TokenFormatter.compact($0.totalTokens) } ?? "—")
                Rectangle().fill(CyberPalette.line).frame(width: 1, height: 25)
                register("PROVIDER", label: "", value: snapshot?.displayName ?? "—")
            }.padding(.vertical, 2)
            activity
            HStack {
                Text("CACHE W " + TokenFormatter.compact(today?.cacheCreationTokens ?? 0))
                Spacer()
                Text("R " + TokenFormatter.compact(today?.cacheReadTokens ?? 0))
            }.font(.system(size: 8, design: .monospaced)).foregroundStyle(.mint)
            if showsCost, let today, snapshot?.reportsCost == true {
                HStack {
                    UsageCostText(cost: today.usageCost, l: l)
                    Spacer()
                    if let week = snapshot?.weekTotal { UsageCostText(cost: week.usageCost, l: l) }
                    if let month = snapshot?.monthTotal { UsageCostText(cost: month.usageCost, l: l) }
                }.font(.caption2).foregroundStyle(CyberPalette.muted)
            }
        }
    }

    private func side(_ title: String, amount: Int, caption: String, color: Color) -> some View {
        VStack(alignment: title == "INPUT" ? .leading : .trailing, spacing: 5) {
            Text(title).font(.system(size: 8, design: .monospaced)).tracking(1.5).foregroundStyle(color)
            Text(TokenFormatter.compact(amount)).font(.system(size: 20, design: .monospaced))
                .foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.6)
            Text(caption).font(.system(size: 8)).foregroundStyle(CyberPalette.muted)
        }.frame(maxWidth: .infinity, alignment: title == "INPUT" ? .leading : .trailing)
    }
    private func register(_ title: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title + (label.isEmpty ? "" : " · " + label))
                .font(.system(size: 7, design: .monospaced)).foregroundStyle(CyberPalette.muted)
            Text(value).font(.system(size: title == "PROVIDER" ? 10 : 16, design: .monospaced))
                .lineLimit(1).minimumScaleFactor(0.6)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private var activity: some View {
        let date = LocalUsageReader.todayKey()
        let columns = DailyTrendMetrics.monthColumns(series: snapshot?.monthDaily ?? [], today: date)
        let peak = max(1, columns.map(\.tokens).max() ?? 0)
        return VStack(spacing: 5) {
            HStack {
                Text(l.thisMonth + " / DATA ACTIVITY")
                Spacer()
                Button(action: onRecap) { Image(systemName: "chart.bar.xaxis") }
                    .buttonStyle(.plain).help(l.recapOpen).accessibilityLabel(l.recapOpen)
            }.font(.system(size: 8)).foregroundStyle(CyberPalette.muted)
            HStack(spacing: 3) {
                ForEach(columns, id: \.date) { day in
                    let opacity: Double = day.isFuture || day.tokens == 0 ? 0.04 : 0.18 + 0.82 * Double(day.tokens) / Double(peak)
                    let border: Color = day.date == date ? CyberPalette.yellow : CyberPalette.line
                    let amount: String = day.isFuture ? "—" : (snapshot?.monthDaily == nil ? "N/A" : TokenFormatter.grouped(day.tokens))
                    Rectangle().fill(CyberPalette.cyan.opacity(opacity))
                        .overlay(Rectangle().stroke(border, lineWidth: 0.7))
                        .help(day.date + " · " + amount)
                        .accessibilityLabel(day.date + " " + amount)
                }
            }.frame(height: 8)
        }.padding(.vertical, 2)
    }
}

/// Square command keys used by the approved terminal mockup.
struct TerminalCommandStyle: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 10, design: .monospaced))
            .padding(.horizontal, 9).padding(.vertical, 6)
            .foregroundStyle(CyberPalette.text)
            .background(CyberPalette.cyan.opacity(configuration.isPressed ? 0.25 : prominent ? 0.16 : 0.06))
            .overlay(Rectangle().stroke(CyberPalette.cyan.opacity(0.4), lineWidth: 0.7))
            .opacity(enabled ? 1 : 0.4)
            .contentShape(Rectangle())
    }
}
