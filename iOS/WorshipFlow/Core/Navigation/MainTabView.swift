import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @ObservedObject var practice = PracticeManager.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                BandHomeView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }

                SetlistsView()
                    .tabItem {
                        Image(systemName: "music.note.list")
                        Text("setlists".localized)
                    }

                SongLibraryView()
                    .tabItem {
                        Image(systemName: "music.note")
                        Text("songs".localized)
                    }

                RehearsalsView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("rehearsals".localized)
                    }

                MembersView()
                    .tabItem {
                        Image(systemName: "person.3")
                        Text("members".localized)
                    }
            }
            .tint(.appPrimary)

            // Floating mini player above tab bar
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
