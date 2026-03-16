import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @ObservedObject var practice = PracticeManager.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                // 1. Home / Dashboard
                BandHomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                // 2. Services (OnStage-style setlists with team assignments)
                ServicesView()
                    .tabItem {
                        Label("Services", systemImage: "music.note.list")
                    }

                // 3. Song Library
                SongLibraryView()
                    .tabItem {
                        Label("songs".localized, systemImage: "music.note")
                    }

                // 4. Rehearsals / Schedule
                RehearsalsView()
                    .tabItem {
                        Label("Schedule", systemImage: "calendar")
                    }

                // 5. Team / Members
                MembersView()
                    .tabItem {
                        Label("Team", systemImage: "person.3.fill")
                    }
            }
            .tint(.appPrimary)

            // Floating mini metronome player above tab bar
            VStack(spacing: 0) {
                PracticeMiniPlayerView()
                    .padding(.bottom, 49) // tab bar height
            }
        }
        .fullScreenCover(isPresented: $practice.showFullPlayer) {
            PracticeSessionView()
        }
    }
}
