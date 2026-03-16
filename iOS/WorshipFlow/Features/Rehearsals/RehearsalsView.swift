import SwiftUI

struct RehearsalsView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @StateObject private var vm = RehearsalsViewModel()
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.rehearsals.isEmpty {
                    List {
                        Section("Upcoming") {
                            SkeletonList(count: 3) { SkeletonRehearsalRow() }
                                .listRowBackground(Color.appSurface)
                        }
                        Section("Past") {
                            SkeletonList(count: 4) { SkeletonRehearsalRow() }
                                .listRowBackground(Color.appSurface)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .allowsHitTesting(false)
                } else if vm.rehearsals.isEmpty {
                    EmptyStateView(
                        icon: "📅",
                        title: "no_rehearsals".localized,
                        subtitle: "Schedule a rehearsal for your band",
                        buttonTitle: "new_rehearsal".localized
                    ) {
                        showCreate = true
                    }
                } else {
                    List {
                        if !vm.upcomingRehearsals.isEmpty {
                            Section("Upcoming") {
                                ForEach(vm.upcomingRehearsals) { rehearsal in
                                    NavigationLink {
                                        RehearsalDetailView(rehearsal: rehearsal, vm: vm)
                                    } label: {
                                        RehearsalRow(rehearsal: rehearsal)
                                    }
                                }
                                .onDelete { indexSet in
                                    Task {
                                        for idx in indexSet {
                                            await vm.deleteRehearsal(vm.upcomingRehearsals[idx])
                                        }
                                    }
                                }
                            }
                        }

                        if !vm.pastRehearsals.isEmpty {
                            Section("Past") {
                                ForEach(vm.pastRehearsals) { rehearsal in
                                    NavigationLink {
                                        RehearsalDetailView(rehearsal: rehearsal, vm: vm)
                                    } label: {
                                        RehearsalRow(rehearsal: rehearsal)
                                            .opacity(0.6)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("rehearsals".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showCreate = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateRehearsalView(vm: vm)
            }
            .refreshable {
                guard let bandId = bandVM.currentBand?.id else { return }
                await vm.loadRehearsals(bandId: bandId)
            }
            .task {
                guard let bandId = bandVM.currentBand?.id else { return }
                await vm.loadRehearsals(bandId: bandId)
            }
        }
        .background(Color.appBackground)
    }
}

struct RehearsalRow: View {
    let rehearsal: Rehearsal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(rehearsal.title)
                .font(.appHeadline)
                .foregroundColor(.appPrimary)

            HStack(spacing: 8) {
                Label(rehearsal.formattedDate, systemImage: "calendar")
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)

                Text(rehearsal.formattedTime)
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
            }

            if let location = rehearsal.location {
                Label(location, systemImage: "mappin")
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
            }

            if let setlistName = rehearsal.setlists?.name {
                Label(setlistName, systemImage: "music.note.list")
                    .font(.appCaption)
                    .foregroundColor(.appAccent)
            }
        }
        .padding(.vertical, 4)
    }
}
