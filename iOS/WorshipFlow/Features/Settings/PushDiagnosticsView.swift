import SwiftUI
import UserNotifications
import FirebaseMessaging

// MARK: - Push Diagnostics
//
// One-tap surface to verify the entire push-notification pipeline:
//
//   1.  iOS notification permission state
//   2.  APNs device-token availability (real device only)
//   3.  Firebase FCM token
//   4.  Backend record of this user's tokens
//   5.  End-to-end FCM → APNs → device round-trip
//
// Use this when the rehearsal/service notification doesn't arrive — the
// failing step is highlighted in red with the FCM error message.

struct PushDiagnosticsView: View {
    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var fcmToken: String = "(loading…)"
    @State private var apnsTokenHex: String = "(none — real device only)"

    @State private var serverInfo: ServerDiagnostics?
    @State private var serverError: String?
    @State private var loadingServer = false

    @State private var testResult: TestPushResult?
    @State private var testError: String?
    @State private var sendingTest = false

    var body: some View {
        Form {
            Section {
                row("permission".localized, value: authStatusText, color: authStatusColor)
                row("APNs token", value: apnsTokenHex, mono: true,
                    color: apnsTokenHex.hasPrefix("(") ? .statusMaybe : .statusGoing)
                row("FCM token", value: fcmToken, mono: true,
                    color: fcmToken.hasPrefix("(") ? .statusMaybe : .statusGoing,
                    copyable: !fcmToken.hasPrefix("("))
            } header: {
                Text("on_this_device".localized)
            }

            Section {
                if loadingServer {
                    HStack { ProgressView(); Text("loading".localized) }
                } else if let err = serverError {
                    Text(err).foregroundColor(.statusNo).font(.appCaption)
                } else if let info = serverInfo {
                    row("firebase_admin".localized,
                        value: info.fcmReady ? "ready".localized : "not_initialised".localized,
                        color: info.fcmReady ? .statusGoing : .statusNo)
                    row("registered_devices".localized,
                        value: "\(info.tokenCount)",
                        color: info.tokenCount > 0 ? .statusGoing : .statusNo)
                    if info.tokenCount > 0 {
                        ForEach(info.tokens.indices, id: \.self) { i in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(info.tokens[i].preview)
                                    .font(.appMono)
                                    .foregroundColor(.appPrimary)
                                if let createdAt = info.tokens[i].createdAt {
                                    Text(createdAt)
                                        .font(.appSmall)
                                        .foregroundColor(.appSecondary)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("on_the_backend".localized)
            } footer: {
                Text("backend_diag_footer".localized)
                    .font(.appSmall)
            }

            Section {
                Button {
                    Task { await sendTestPush() }
                } label: {
                    HStack {
                        if sendingTest { ProgressView() }
                        Text("send_test_push".localized)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(sendingTest)

                if let err = testError {
                    Text(err)
                        .font(.appCaption)
                        .foregroundColor(.statusNo)
                }

                if let res = testResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(format: "test_push_summary".localized, res.succeeded, res.attempted))
                            .font(.appHeadline)
                            .foregroundColor(res.failed == 0 ? .statusGoing : .statusNo)

                        ForEach(res.results.indices, id: \.self) { i in
                            let r = res.results[i]
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Image(systemName: r.ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
                                        .foregroundColor(r.ok ? .statusGoing : .statusNo)
                                    Text(r.tokenPreview).font(.appMono)
                                }
                                if let code = r.code {
                                    Text("FCM error: \(code)")
                                        .font(.appSmall)
                                        .foregroundColor(.statusNo)
                                }
                                if let msg = r.message, !r.ok {
                                    Text(msg)
                                        .font(.appSmall)
                                        .foregroundColor(.appSecondary)
                                }
                                if let hint = r.hint {
                                    Text(hint)
                                        .font(.appSmall)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.appAccent)
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            } header: {
                Text("end_to_end_test".localized)
            } footer: {
                Text("end_to_end_footer".localized)
                    .font(.appSmall)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("push_diagnostics".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task { await refresh() }
        .refreshable { await refresh() }
    }

    // MARK: - Refresh

    private func refresh() async {
        // 1. Permission
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authStatus = settings.authorizationStatus

        // 2. APNs token (Messaging.apnsToken is set only if APNs gave us one)
        if let data = Messaging.messaging().apnsToken {
            apnsTokenHex = data.map { String(format: "%02x", $0) }.joined().prefix(16) + "…"
        } else {
            apnsTokenHex = "(none — real device only)"
        }

        // 3. FCM token
        do {
            let t = try await Messaging.messaging().token()
            fcmToken = t
        } catch {
            fcmToken = "(error: \(error.localizedDescription))"
        }

        // 4. Backend state
        loadingServer = true
        serverError = nil
        do {
            serverInfo = try await APIClient.shared.get("/notifications/diagnostics")
        } catch {
            serverError = "Could not reach backend: \(error.localizedDescription)"
        }
        loadingServer = false
    }

    // MARK: - Send test push

    private func sendTestPush() async {
        sendingTest = true
        testError = nil
        testResult = nil
        defer { sendingTest = false }
        do {
            testResult = try await APIClient.shared.post("/notifications/test", body: [:])
        } catch {
            testError = error.localizedDescription
        }
    }

    // MARK: - Permission text

    private var authStatusText: String {
        switch authStatus {
        case .notDetermined:    return "not_determined".localized
        case .denied:           return "denied".localized
        case .authorized:       return "authorized".localized
        case .provisional:      return "provisional".localized
        case .ephemeral:        return "ephemeral".localized
        @unknown default:       return "unknown"
        }
    }

    private var authStatusColor: Color {
        switch authStatus {
        case .authorized, .provisional: return .statusGoing
        case .denied:                   return .statusNo
        default:                        return .statusMaybe
        }
    }

    // MARK: - Row builder

    @ViewBuilder
    private func row(_ label: String, value: String, mono: Bool = false,
                     color: Color = .appPrimary, copyable: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.appCaption)
                .foregroundColor(.appSecondary)
            HStack {
                Text(value)
                    .font(mono ? .appMono : .appBody)
                    .foregroundColor(color)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                Spacer(minLength: 0)
                if copyable {
                    Button {
                        UIPasteboard.general.string = value
                        AppHaptics.success()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.appAccent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - DTOs

private struct ServerDiagnostics: Decodable {
    let fcmReady: Bool
    let tokenCount: Int
    let tokens: [TokenInfo]

    enum CodingKeys: String, CodingKey {
        case fcmReady   = "fcm_ready"
        case tokenCount = "token_count"
        case tokens
    }

    struct TokenInfo: Decodable {
        let preview: String
        let createdAt: String?

        enum CodingKeys: String, CodingKey {
            case preview
            case createdAt = "created_at"
        }
    }
}

private struct TestPushResult: Decodable {
    let attempted: Int
    let succeeded: Int
    let failed: Int
    let results: [Outcome]

    struct Outcome: Decodable {
        let tokenPreview: String
        let ok: Bool
        let messageId: String?
        let code: String?
        let message: String?
        let hint: String?

        enum CodingKeys: String, CodingKey {
            case ok, messageId, code, message, hint
            case tokenPreview = "token_preview"
        }
    }
}
