import SwiftUI

// MARK: - Services View (OnStage-inspired)

struct ServicesView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @StateObject private var vm = SetlistViewModel()
    @State private var showCreate = false
    @State private var filter: ServiceFilter = .upcoming

    enum ServiceFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case past = "Past"
        case all = "All"
    }

    var filteredSetlists: [Setlist] {
        switch filter {
        case .upcoming: return vm.setlists.filter { $0.isUpcoming }
        case .past:     return vm.setlists.filter { !$0.isUpcoming }
        case .all:      return vm.setlists
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                Divider()
                    .opacity(0.5)

                contentBody
            }
            .background(Color.appBackground)
            .navigationTitle("Services")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateServiceView(vm: vm)
            }
            .refreshable {
                guard let bandId = bandVM.currentBand?.id else { return }
                await vm.loadSetlists(bandId: bandId)
            }
            .task {
                guard let bandId = bandVM.currentBand?.id else { return }
                await vm.loadSetlists(bandId: bandId)
            }
        }
        .background(Color.appBackground)
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(ServiceFilter.allCases, id: \.self) { f in
                Button {
                    AppHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        filter = f
                    }
                } label: {
                    Text(f.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(filter == f ? .white : .appPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if filter == f {
                                    AnyView(AppGradients.gold)
                                } else {
                                    AnyView(Color.appSurface)
                                }
                            }
                        )
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(
                            filter == f ? Color.clear : Color.appDivider,
                            lineWidth: 1
                        ))
                        .shadow(color: filter == f ? Color.appAccent.opacity(0.30) : .clear,
                                radius: 5, x: 0, y: 2)
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: filter)
            }
            Spacer()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentBody: some View {
        if vm.isLoading && vm.setlists.isEmpty {
            List {
                SkeletonList(count: 6) { SkeletonServiceRow() }
                    .listRowBackground(Color.appSurface)
                    .listRowSeparatorTint(Color.appDivider)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .allowsHitTesting(false)
        } else if filteredSetlists.isEmpty {
            emptyState
        } else {
            List {
                ForEach(filteredSetlists) { setlist in
                    NavigationLink {
                        ServiceDetailView(setlist: setlist)
                            .environmentObject(bandVM)
                    } label: {
                        ServiceRow(setlist: setlist)
                    }
                    .listRowBackground(Color.appSurface)
                }
                .onDelete { indexSet in
                    Task {
                        let items = filteredSetlists
                        for idx in indexSet {
                            await vm.deleteSetlist(items[idx])
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "🎹",
            title: filter == .upcoming ? "No upcoming services" : "No services yet",
            subtitle: "Create a service plan to organize your songs and team",
            buttonTitle: "New Service"
        ) {
            showCreate = true
        }
    }
}

// MARK: - Service Row

struct ServiceRow: View {
    let setlist: Setlist

    var body: some View {
        HStack(spacing: 14) {
            // Date column
            if let date = setlist.formattedDate {
                VStack(spacing: 2) {
                    Text(monthString(from: date))
                        .font(.appSmall)
                        .foregroundColor(.appAccent)
                        .fontWeight(.bold)
                    Text(dayString(from: date))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.appPrimary)
                }
                .frame(width: 44)
                .padding(.vertical, 6)
                .background(Color.appAccent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.featureServices.opacity(0.12))
                        .frame(width: 44, height: 48)
                    Image(systemName: "music.note.list")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.featureServices)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    Text(setlist.name)
                        .font(.appHeadline)
                        .foregroundColor(.appPrimary)
                        .lineLimit(1)
                    Spacer()
                    if setlist.serviceType != nil {
                        ServiceTypeBadge(setlist: setlist)
                    }
                }

                HStack(spacing: 10) {
                    if let location = setlist.location, !location.isEmpty {
                        Label(location, systemImage: "mappin.circle.fill")
                            .font(.appSmall)
                            .foregroundColor(.appSecondary)
                            .lineLimit(1)
                    }
                    if let theme = setlist.theme, !theme.isEmpty {
                        Label(theme, systemImage: "sparkles")
                            .font(.appSmall)
                            .foregroundColor(.appSecondary)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func monthString(from dateStr: String) -> String {
        // dateStr is already formatted; try to parse a month abbreviation
        let parts = dateStr.components(separatedBy: " ")
        return parts.first?.prefix(3).uppercased() ?? ""
    }

    private func dayString(from dateStr: String) -> String {
        let parts = dateStr.components(separatedBy: " ")
        // Look for a numeric part
        return parts.first(where: { Int($0.filter(\.isNumber)) != nil })?.filter(\.isNumber) ?? "--"
    }
}

// MARK: - Service Type Badge

struct ServiceTypeBadge: View {
    let setlist: Setlist

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: setlist.serviceTypeIcon)
                .font(.system(size: 9, weight: .semibold))
            Text(setlist.serviceTypeDisplay)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AppGradients.gold)
        .clipShape(Capsule())
        .shadow(color: Color.appAccent.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}
