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
        HStack(spacing: 14) {
            // Colored left indicator bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.featureSchedule)
                .frame(width: 4, height: 52)

            VStack(alignment: .leading, spacing: 5) {
                Text(rehearsal.title)
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(.appSecondary)
                    Text("\(rehearsal.formattedDate) · \(rehearsal.formattedTime)")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                }

                if let location = rehearsal.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 11))
                            .foregroundColor(.appSecondary)
                        Text(location)
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            if let setlistName = rehearsal.setlists?.name {
                Text(setlistName)
                    .font(.appSmall)
                    .foregroundColor(.appAccent)
                    .lineLimit(1)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.appAccent.opacity(0.10))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 6)
    }
}
