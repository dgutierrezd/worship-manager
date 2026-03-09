import SwiftUI

@MainActor
class BandViewModel: ObservableObject {
    @Published var bands: [Band] = []
    @Published var currentBand: Band?
    @Published var isLoading = false
    @Published var error: String?

    /// Set after creating a band — triggers the invite code sheet on the dashboard
    @Published var newlyCreatedBand: Band?

    func loadMyBands() async {
        isLoading = true
        do {
            bands = try await BandService.myBands()
            if currentBand == nil, let first = bands.first {
                currentBand = first
            }
        } catch {
            print("loadMyBands error: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func createBand(name: String, church: String?, emoji: String, color: String) async -> Bool {
        isLoading = true
        error = nil
        do {
            let band = try await BandService.createBand(
                name: name, church: church, emoji: emoji, color: color
            )
            bands.append(band)
            currentBand = band
            newlyCreatedBand = band
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func joinBand(code: String) async -> Bool {
        isLoading = true
        error = nil
        do {
            let band = try await BandService.joinBand(code: code)
            bands.append(band)
            currentBand = band
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func switchBand(_ band: Band) {
        currentBand = band
    }

    func refreshCurrentBand() async {
        guard let id = currentBand?.id else { return }
        do {
            currentBand = try await BandService.getBand(id: id)
        } catch {
            print("refreshCurrentBand error: \(error.localizedDescription)")
        }
    }

    func regenerateCode() async {
        guard let id = currentBand?.id else { return }
        do {
            let updated = try await BandService.regenerateCode(bandId: id)
            currentBand?.inviteCode = updated.inviteCode
        } catch {
            self.error = error.localizedDescription
        }
    }
}
