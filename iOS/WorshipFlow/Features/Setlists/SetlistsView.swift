import SwiftUI

struct SetlistsView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @StateObject private var vm = SetlistViewModel()
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.setlists.isEmpty && !vm.isLoading {
                    EmptyStateView(
                        icon: "📋",
                        title: "no_setlists".localized,
                        subtitle: "Create your first setlist for an upcoming service",
                        buttonTitle: "new_setlist".localized
                    ) {
                        showCreate = true
                    }
                } else {
                    List {
                        ForEach(vm.setlists) { setlist in
                            NavigationLink {
                                SetlistDetailView(setlist: setlist)
                                    .environmentObject(vm)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(setlist.name)
                                        .font(.appHeadline)
                                        .foregroundColor(.appPrimary)

                                    if let date = setlist.formattedDate {
                                        Text(date)
                                            .font(.appCaption)
                                            .foregroundColor(.appSecondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for idx in indexSet {
                                    await vm.deleteSetlist(vm.setlists[idx])
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("setlists".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showCreate = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateSetlistView(vm: vm)
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
}
