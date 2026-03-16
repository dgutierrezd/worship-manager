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
                    withAnimation(.easeInOut(duration: 0.2)) {
                        filter = f
                    }
                } label: {
                    Text(f.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(filter == f ? .white : .appPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(filter == f ? Color.appPrimary : Color.appSurface)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.appDivider, lineWidth: filter == f ? 0 : 1))
                }
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(setlist.name)
                        .font(.appHeadline)
                        .foregroundColor(.appPrimary)

                    if let date = setlist.formattedDate {
                        Label(date, systemImage: "calendar")
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                    }
                }

                Spacer()

                if setlist.serviceType != nil {
                    ServiceTypeBadge(setlist: setlist)
                }
            }

            HStack(spacing: 12) {
                if let location = setlist.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.circle")
                        .font(.system(size: 11))
                        .foregroundColor(.appSecondary)
                }
                if let theme = setlist.theme, !theme.isEmpty {
                    Label(theme, systemImage: "sparkles")
                        .font(.system(size: 11))
                        .foregroundColor(.appSecondary)
                        .italic()
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Service Type Badge

struct ServiceTypeBadge: View {
    let setlist: Setlist

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: setlist.serviceTypeIcon)
                .font(.system(size: 10))
            Text(setlist.serviceTypeDisplay)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.appAccent)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.appAccent.opacity(0.12))
        .clipShape(Capsule())
    }
}
