import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @ObservedObject var practice = PracticeManager.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                // 1. Home — launchpad for all sections
                BandHomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                // 2. Settings
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("settings".localized, systemImage: "gearshape.fill")
                }
            }
            .tint(.appAccent)

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
