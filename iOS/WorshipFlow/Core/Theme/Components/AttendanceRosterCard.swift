import SwiftUI

// MARK: - Attendance Roster Card
//
// Reusable card that shows who in the band has responded "Going",
// "Maybe", or "Not going" to a service or rehearsal. Tap the header
// chips to filter; the body lists each member with their status badge.

struct AttendanceRosterCard: View {
    let rsvps: [AttendanceRSVP]
    let isLoading: Bool

    @State private var filter: Filter = .going

    enum Filter: String, CaseIterable, Identifiable {
        case going, maybe, notGoing
        var id: String { rawValue }
        var apiValue: String {
            switch self {
            case .going:    return "going"
            case .maybe:    return "maybe"
            case .notGoing: return "not_going"
            }
        }
        var titleKey: String {
            switch self {
            case .going:    return "rsvp_going"
            case .maybe:    return "rsvp_maybe"
            case .notGoing: return "rsvp_no"
            }
        }
        var color: Color {
            switch self {
            case .going:    return .statusGoing
            case .maybe:    return .statusMaybe
            case .notGoing: return .statusNo
            }
        }
        var icon: String {
            switch self {
            case .going:    return "checkmark"
            case .maybe:    return "questionmark"
            case .notGoing: return "xmark"
            }
        }
    }

    private func count(for f: Filter) -> Int {
        rsvps.filter { $0.status == f.apiValue }.count
    }

    private var visibleRSVPs: [AttendanceRSVP] {
        rsvps
            .filter { $0.status == filter.apiValue }
            .sorted { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appAccent)
                Text("attendance".localized)
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)
                Spacer()
                if isLoading {
                    ProgressView().scaleEffect(0.7)
                }
            }

            // Filter chips with counts
            HStack(spacing: 8) {
                ForEach(Filter.allCases) { f in
                    rosterChip(for: f)
                }
                Spacer(minLength: 0)
            }

            Divider().opacity(0.4)

            // Body
            if visibleRSVPs.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(visibleRSVPs) { rsvp in
                        AttendanceRow(rsvp: rsvp)
                    }
                }
            }
        }
        .padding(18)
        .cardStyle()
    }

    @ViewBuilder
    private func rosterChip(for f: Filter) -> some View {
        let isSelected = filter == f
        let n = count(for: f)
        Button {
            AppHaptics.selection()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                filter = f
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: f.icon)
                    .font(.system(size: 10, weight: .bold))
                Text(f.titleKey.localized)
                    .font(.appSmall)
                    .fontWeight(.semibold)
                Text("\(n)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white.opacity(0.25) : f.color.opacity(0.15))
                    )
            }
            .foregroundColor(isSelected ? .white : f.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? f.color : f.color.opacity(0.10))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : f.color.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 6) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 28))
                    .foregroundColor(.appDivider)
                Text("no_responses_yet".localized)
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
            }
            .padding(.vertical, 16)
            Spacer()
        }
    }
}

// MARK: - Row

private struct AttendanceRow: View {
    let rsvp: AttendanceRSVP

    var body: some View {
        HStack(spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text(rsvp.displayName)
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)
                if let inst = rsvp.profile?.instrument, !inst.isEmpty {
                    Text(inst)
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
            Text(initial)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var initial: String {
        String(rsvp.displayName.prefix(1)).uppercased()
    }

    /// Stable accent color per name.
    private var color: Color {
        let palette: [Color] = [.featureServices, .featureSongs, .featureSchedule, .featureTeam]
        let idx = abs(rsvp.displayName.hashValue) % palette.count
        return palette[idx]
    }
}
