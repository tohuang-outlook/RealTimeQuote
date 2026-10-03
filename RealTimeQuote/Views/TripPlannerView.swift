import SwiftUI

/// V1 deliberately presents vehicle information only. It has no vehicle command surfaces.
struct TripPlannerView: View {
    @StateObject private var store = OwnershipStore()
    @State private var selectedSection = "Overview"
    @State private var showChargingPlan = false
    @State private var showCostDetails = false
    @State private var showSettings = false
    @State private var showAddSession = false

    private let sections = ["Overview", "Charging", "Costs", "Alerts"]

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            mainContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CompanionTheme.canvas)
        .sheet(isPresented: $showChargingPlan) { chargingPlan }
        .sheet(isPresented: $showCostDetails) { costDetails }
        .sheet(isPresented: $showSettings) { settings }
        .sheet(isPresented: $showAddSession) { AddChargingSessionSheet(store: store) }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11).fill(CompanionTheme.accent)
                    Image(systemName: "bolt.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(.black)
                }
                .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Y Companion").font(.system(size: 18, weight: .bold))
                    Text("MODEL Y · READ ONLY").font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(CompanionTheme.muted)
                }
            }
            .padding(.bottom, 46)

            ForEach(sections, id: \.self) { section in
                Button { selectedSection = section } label: {
                    HStack(spacing: 12) {
                        Image(systemName: icon(for: section)).frame(width: 18)
                        Text(section).font(.system(size: 14, weight: .medium))
                        Spacer()
                    }
                    .foregroundStyle(selectedSection == section ? .black : CompanionTheme.muted)
                    .padding(.horizontal, 13).padding(.vertical, 11)
                    .background(selectedSection == section ? CompanionTheme.accent : .clear, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 5)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Circle().fill(CompanionTheme.good).frame(width: 7, height: 7)
                    Text("LOCAL OWNERSHIP DATA").font(.system(size: 10, weight: .bold)).tracking(0.8)
                }
                Text("Stored on this Mac")
                    .font(.system(size: 12)).foregroundStyle(CompanionTheme.muted)
                Text("Read-only V1. Tesla account sync and all vehicle controls are intentionally unavailable.")
                    .font(.system(size: 11)).foregroundStyle(CompanionTheme.dim).fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(CompanionTheme.panel, in: RoundedRectangle(cornerRadius: 14))
        }
        .padding(24)
        .frame(width: 230, alignment: .leading)
        .background(CompanionTheme.sidebar)
    }

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                hero
                HStack(alignment: .top, spacing: 18) {
                    chargingGuidance.frame(maxWidth: .infinity)
                    alerts.frame(width: 310)
                }
                HStack(alignment: .top, spacing: 18) {
                    costAndEfficiency.frame(maxWidth: .infinity)
                    recentCharging.frame(width: 310)
                }
            }
            .padding(30)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Good evening, Tony").font(.system(size: 28, weight: .bold))
                Text("Your local charging and ownership overview for a 2026 Model Y Long Range.")
                    .font(.system(size: 14)).foregroundStyle(CompanionTheme.muted)
            }
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "lock.shield").foregroundStyle(CompanionTheme.accent)
                Text("READ-ONLY ACCESS").font(.system(size: 11, weight: .bold)).tracking(0.8)
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(CompanionTheme.accent.opacity(0.12), in: Capsule())
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3").font(.system(size: 14, weight: .semibold))
                    .padding(10).background(CompanionTheme.panel, in: Circle())
            }
            .buttonStyle(.plain).foregroundStyle(CompanionTheme.muted)
        }
    }

    private var hero: some View {
        HStack(spacing: 26) {
            ZStack {
                Circle().stroke(CompanionTheme.track, lineWidth: 14).frame(width: 170, height: 170)
                Circle().trim(from: 0, to: 0.64).stroke(CompanionTheme.accent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90)).frame(width: 170, height: 170)
                VStack(spacing: 0) {
                    Text("\(store.batteryPercent)%").font(.system(size: 38, weight: .bold, design: .rounded))
                    Text("CHARGE").font(.system(size: 10, weight: .bold)).tracking(1).foregroundStyle(CompanionTheme.muted)
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Circle().fill(CompanionTheme.good).frame(width: 8, height: 8)
                    Text("PARKED AT HOME").font(.system(size: 11, weight: .bold)).tracking(0.8).foregroundStyle(CompanionTheme.good)
                }
                Text("\(store.estimatedRange) mi estimated range").font(.system(size: 24, weight: .semibold))
                Text("Target charge: \(store.chargeTarget)%  ·  Ready for tomorrow’s commute")
                    .font(.system(size: 13)).foregroundStyle(CompanionTheme.muted)
                HStack(spacing: 22) {
                    heroMetric("72°", "CABIN")
                    heroMetric("0 mph", "SPEED")
                    heroMetric(store.odometerText, "ODOMETER")
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 7) {
                Image(systemName: "car.side.fill").font(.system(size: 54)).foregroundStyle(CompanionTheme.primary)
                Text("Midnight Silver Metallic").font(.system(size: 11)).foregroundStyle(CompanionTheme.muted)
            }
        }
        .padding(25)
        .background(CompanionTheme.hero, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(CompanionTheme.stroke, lineWidth: 1))
    }

    private func heroMetric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.system(size: 15, weight: .semibold))
            Text(label).font(.system(size: 9, weight: .bold)).tracking(0.8).foregroundStyle(CompanionTheme.dim)
        }
    }

    private var chargingGuidance: some View {
        card(title: "Charging guidance", subtitle: "Based on your next scheduled drive") {
            HStack(alignment: .center, spacing: 20) {
                Image(systemName: "bolt.car.fill").font(.system(size: 30)).foregroundStyle(CompanionTheme.accent)
                    .frame(width: 58, height: 58).background(CompanionTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 5) {
                    Text("Charge to \(store.chargeTarget)% tonight").font(.system(size: 17, weight: .semibold))
                    Text("Adds ~\(store.neededRangeBuffer) mi beyond tomorrow’s planned \(store.plannedDriveMiles) mi, leaving a comfortable arrival buffer.")
                        .font(.system(size: 13)).foregroundStyle(CompanionTheme.muted).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button("View plan") { showChargingPlan = true }
                    .buttonStyle(CompanionButtonStyle())
            }
            Divider().overlay(CompanionTheme.stroke)
            HStack {
                guidanceItem("BEST WINDOW", "11 PM – 6 AM", "moon.stars.fill")
                Spacer()
                guidanceItem("HOME RATE", store.rateText + " / kWh", "house.fill")
                Spacer()
                guidanceItem("EST. SESSION", "2 hr 12 min", "clock.fill")
            }
        }
    }

    private func guidanceItem(_ label: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(CompanionTheme.muted)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 9, weight: .bold)).tracking(0.7).foregroundStyle(CompanionTheme.dim)
                Text(value).font(.system(size: 13, weight: .medium))
            }
        }
    }

    private var alerts: some View {
        card(title: "Vehicle alerts", subtitle: "Informational only") {
            alertRow(icon: "exclamationmark.triangle.fill", color: CompanionTheme.warning, title: "Tire pressure check", detail: "Rear right is 2 PSI below your set point.")
            Divider().overlay(CompanionTheme.stroke)
            alertRow(icon: "calendar", color: CompanionTheme.accent, title: "Service reminder", detail: "Cabin air filter recommended in 21 days.")
            Divider().overlay(CompanionTheme.stroke)
            HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(CompanionTheme.good); Text("No urgent vehicle issues").font(.system(size: 13, weight: .medium)); Spacer() }
        }
    }

    private func alertRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 16)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 13, weight: .semibold))
                Text(detail).font(.system(size: 12)).foregroundStyle(CompanionTheme.muted)
            }
        }
    }

    private var costAndEfficiency: some View {
        card(title: "Cost & efficiency", subtitle: "Rolling 30 days") {
            HStack(spacing: 10) {
                statTile(store.monthlySpendText, "CHARGING SPEND", "arrow.down.right", CompanionTheme.good)
                statTile("\(store.monthlyMiles) mi", "DISTANCE DRIVEN", "arrow.right", CompanionTheme.primary)
                statTile("\(store.averageEfficiency) Wh/mi", "AVG. EFFICIENCY", "gauge.with.dots.needle.50percent", CompanionTheme.accent)
            }
            HStack(alignment: .bottom, spacing: 11) {
                ForEach([42, 64, 50, 80, 58, 93, 70], id: \.self) { height in
                    VStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 3).fill(CompanionTheme.accent.opacity(0.3)).frame(height: CGFloat(height))
                        Text(weekday(for: height)).font(.system(size: 9)).foregroundStyle(CompanionTheme.dim)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 112)
            .padding(.top, 3)
            HStack { Text("Efficient driving this month").font(.system(size: 12)).foregroundStyle(CompanionTheme.good); Spacer(); Button("Details") { showCostDetails = true }.buttonStyle(.plain).foregroundStyle(CompanionTheme.accent).font(.system(size: 12, weight: .semibold)) }
        }
    }

    private func weekday(for height: Int) -> String { [42: "M", 64: "T", 50: "W", 80: "T", 58: "F", 93: "S", 70: "S"][height] ?? "" }

    private func statTile(_ value: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon).foregroundStyle(color).font(.system(size: 13))
            Text(value).font(.system(size: 19, weight: .bold))
            Text(label).font(.system(size: 9, weight: .bold)).tracking(0.6).foregroundStyle(CompanionTheme.dim)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(13)
        .background(CompanionTheme.panel, in: RoundedRectangle(cornerRadius: 13))
    }

    private var recentCharging: some View {
        card(title: "Recent charging", subtitle: "Last 3 sessions") {
            ForEach(Array(store.sessions.prefix(3).enumerated()), id: \.element.id) { index, session in
                chargeRow(session.dateLabel, session.location, session.energyText, session.costText)
                if index < min(store.sessions.count, 3) - 1 { Divider().overlay(CompanionTheme.stroke) }
            }
            Button { showAddSession = true } label: { Label("Record charging session", systemImage: "plus").font(.system(size: 12, weight: .semibold)) }
                .buttonStyle(.plain).foregroundStyle(CompanionTheme.accent)
        }
    }

    private func chargeRow(_ date: String, _ location: String, _ energy: String, _ cost: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: location == "Home" ? "house.fill" : "bolt.fill").foregroundStyle(CompanionTheme.accent).frame(width: 18)
            VStack(alignment: .leading, spacing: 2) { Text(location).font(.system(size: 12, weight: .medium)); Text(date + " · " + energy).font(.system(size: 11)).foregroundStyle(CompanionTheme.muted) }
            Spacer(); Text(cost).font(.system(size: 13, weight: .semibold))
        }
    }

    private func card<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 3) { Text(title).font(.system(size: 17, weight: .bold)); Text(subtitle).font(.system(size: 12)).foregroundStyle(CompanionTheme.muted) }
            content()
        }
        .padding(19).background(CompanionTheme.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(CompanionTheme.stroke, lineWidth: 1))
    }

    private var chargingPlan: some View {
        CompanionSheet(title: "Tonight’s charging plan", subtitle: "A read-only recommendation based on your schedule.") {
            planLine("Start", "11:00 PM", "Power rates are lowest")
            planLine("Finish", "1:12 AM", "Target: \(store.chargeTarget)% charge")
            planLine("Estimated cost", store.estimatedSessionCostText, "18.0 kWh at \(store.rateText)/kWh")
        }
    }

    private var costDetails: some View {
        CompanionSheet(title: "Efficiency details", subtitle: "Your last 30 days of driving and charging.") {
            planLine("Average", "\(store.averageEfficiency) Wh/mi", "8% better than your 90-day average")
            planLine("Home charging", "72%", "$0.18/kWh average rate")
            planLine("Public charging", "28%", "$0.40/kWh average rate")
        }
    }

    private func planLine(_ label: String, _ value: String, _ detail: String) -> some View {
        HStack { VStack(alignment: .leading, spacing: 3) { Text(label).font(.system(size: 12)).foregroundStyle(CompanionTheme.muted); Text(value).font(.system(size: 18, weight: .semibold)) }; Spacer(); Text(detail).font(.system(size: 12)).foregroundStyle(CompanionTheme.muted).multilineTextAlignment(.trailing) }
        .padding(.vertical, 9)
    }

    private var settings: some View {
        CompanionSheet(title: "Charging preferences", subtitle: "Stored locally on this Mac. These settings only affect guidance; they never send a vehicle command.") {
            Stepper("Charge target: \(store.chargeTarget)%", value: $store.chargeTarget, in: 50...100, step: 5)
            Stepper("Home electricity: \(store.rateText)/kWh", value: $store.homeRate, in: 0.05...1.00, step: 0.01)
            Stepper("Next planned drive: \(store.plannedDriveMiles) mi", value: $store.plannedDriveMiles, in: 10...400, step: 5)
        }
    }

    private func icon(for section: String) -> String {
        ["Overview": "square.grid.2x2.fill", "Charging": "bolt.fill", "Costs": "chart.line.uptrend.xyaxis", "Alerts": "bell.fill"][section] ?? "circle"
    }
}

@MainActor
private final class OwnershipStore: ObservableObject {
    @Published var chargeTarget: Int { didSet { savePreferences() } }
    @Published var homeRate: Double { didSet { savePreferences() } }
    @Published var plannedDriveMiles: Int { didSet { savePreferences() } }
    @Published private(set) var sessions: [ChargingSession] { didSet { saveSessions() } }

    let batteryPercent = 64
    let odometerText = "38,492"

    init(defaults: UserDefaults = .standard) {
        let storedTarget = defaults.object(forKey: "ownership.chargeTarget") as? Int
        let storedRate = defaults.object(forKey: "ownership.homeRate") as? Double
        let storedDrive = defaults.object(forKey: "ownership.plannedDriveMiles") as? Int
        chargeTarget = storedTarget ?? 80
        homeRate = storedRate ?? 0.18
        plannedDriveMiles = storedDrive ?? 126
        if let data = defaults.data(forKey: "ownership.chargingSessions"),
           let decoded = try? JSONDecoder().decode([ChargingSession].self, from: data), !decoded.isEmpty {
            sessions = decoded.sorted { $0.date > $1.date }
        } else {
            sessions = ChargingSession.seeded
        }
    }

    var estimatedRange: Int { Int((Double(batteryPercent) / 100.0) * 263.0) }
    var neededRangeBuffer: Int { max(20, chargeTarget * 263 / 100 - plannedDriveMiles) }
    var rateText: String { String(format: "$%.2f", homeRate) }
    var monthlySpendText: String { String(format: "$%.2f", sessions.reduce(0) { $0 + $1.cost }) }
    var monthlyMiles: Int { 274 }
    var averageEfficiency: Int { 244 }
    var estimatedSessionCostText: String { String(format: "$%.2f", 18.0 * homeRate) }

    func addSession(location: String, energyKWh: Double, cost: Double, date: Date = .now) {
        let cleanedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedLocation.isEmpty, energyKWh > 0, cost >= 0 else { return }
        sessions.insert(ChargingSession(date: date, location: cleanedLocation, energyKWh: energyKWh, cost: cost), at: 0)
    }

    private func savePreferences() {
        let defaults = UserDefaults.standard
        defaults.set(chargeTarget, forKey: "ownership.chargeTarget")
        defaults.set(homeRate, forKey: "ownership.homeRate")
        defaults.set(plannedDriveMiles, forKey: "ownership.plannedDriveMiles")
    }

    private func saveSessions() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: "ownership.chargingSessions")
    }
}

private struct ChargingSession: Codable, Identifiable {
    let id: UUID
    let date: Date
    let location: String
    let energyKWh: Double
    let cost: Double

    init(id: UUID = UUID(), date: Date, location: String, energyKWh: Double, cost: Double) {
        self.id = id; self.date = date; self.location = location; self.energyKWh = energyKWh; self.cost = cost
    }

    var dateLabel: String { date.formatted(.dateTime.month(.abbreviated).day()) }
    var energyText: String { String(format: "%.1f kWh", energyKWh) }
    var costText: String { String(format: "$%.2f", cost) }

    static let seeded = [
        ChargingSession(date: .now, location: "Home", energyKWh: 18.6, cost: 3.35),
        ChargingSession(date: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now, location: "Supercharger · San Mateo", energyKWh: 31.2, cost: 12.48),
        ChargingSession(date: Calendar.current.date(byAdding: .day, value: -4, to: .now) ?? .now, location: "Home", energyKWh: 22.8, cost: 4.10)
    ]
}

private struct AddChargingSessionSheet: View {
    @ObservedObject var store: OwnershipStore
    @Environment(\.dismiss) private var dismiss
    @State private var location = "Home"
    @State private var energy = ""
    @State private var cost = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Record charging session").font(.system(size: 24, weight: .bold))
            Text("This record stays on this Mac unless a future connected service is configured.").foregroundStyle(.secondary)
            TextField("Location", text: $location)
            TextField("Energy added (kWh)", text: $energy)
            TextField("Total cost ($)", text: $cost)
            HStack { Spacer(); Button("Cancel") { dismiss() }; Button("Save") { save() }.buttonStyle(.borderedProminent).disabled(!isValid) }
        }
        .textFieldStyle(.roundedBorder).padding(28).frame(width: 430)
    }

    private var isValid: Bool { (Double(energy) ?? 0) > 0 && (Double(cost) ?? -1) >= 0 && !location.trimmingCharacters(in: .whitespaces).isEmpty }
    private func save() { guard let energyValue = Double(energy), let costValue = Double(cost) else { return }; store.addSession(location: location, energyKWh: energyValue, cost: costValue); dismiss() }
}

private enum CompanionTheme {
    static let canvas = Color(red: 0.055, green: 0.067, blue: 0.075)
    static let sidebar = Color(red: 0.038, green: 0.048, blue: 0.054)
    static let card = Color(red: 0.09, green: 0.105, blue: 0.112)
    static let panel = Color.white.opacity(0.045)
    static let hero = LinearGradient(colors: [Color(red: 0.12, green: 0.145, blue: 0.145), Color(red: 0.075, green: 0.09, blue: 0.095)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let primary = Color.white.opacity(0.93)
    static let muted = Color.white.opacity(0.56)
    static let dim = Color.white.opacity(0.36)
    static let stroke = Color.white.opacity(0.09)
    static let track = Color.white.opacity(0.09)
    static let accent = Color(red: 0.26, green: 0.94, blue: 0.64)
    static let good = Color(red: 0.32, green: 0.9, blue: 0.57)
    static let warning = Color(red: 1.0, green: 0.70, blue: 0.25)
}

private struct CompanionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label.font(.system(size: 12, weight: .bold)).foregroundStyle(.black).padding(.horizontal, 13).padding(.vertical, 9).background(CompanionTheme.accent.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 9)) }
}

private struct CompanionSheet<Content: View>: View {
    let title: String; let subtitle: String; @ViewBuilder let content: Content
    @Environment(\.dismiss) private var dismiss
    var body: some View { VStack(alignment: .leading, spacing: 18) { Text(title).font(.system(size: 24, weight: .bold)); Text(subtitle).foregroundStyle(.secondary); Divider(); content; Spacer(); Button("Done") { dismiss() }.buttonStyle(.borderedProminent) }.padding(28).frame(width: 500, height: 340) }
}
