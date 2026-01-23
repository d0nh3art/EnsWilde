import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @AppStorage("zPatchUnlocked") private var zPatchUnlocked: Bool = false
    @State private var showPasscodeAlert = false
    @State private var passcodeInput: String = ""

    private let contactURL = URL(string: "https://x.com/duongduong0908")!

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Guide
                Button(action: {
                    if let url = URL(string: "https://github.com/YangJiiii/EnsWilde") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "book.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.accent)
                        Text(L("settings_guide"))
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                    .padding(18)
                    .background(AppTheme.row)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)

                // Contact me (NEW)
                Button(action: {
                    UIApplication.shared.open(contactURL)
                }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.cyan)
                        Text(L("settings_contact"))
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                    .padding(18)
                    .background(AppTheme.row)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)

                // Language
                NavigationLink(destination: LanguageSettingsView()) {
                    HStack {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.accent)
                        Text(L("settings_language"))
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                    .padding(18)
                    .background(AppTheme.row)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)

                // zPatch Unlock Button
                Button(action: {
                    if zPatchUnlocked {
                        zPatchUnlocked = false
                    } else {
                        showPasscodeAlert = true
                    }
                }) {
                    HStack {
                        Image(systemName: zPatchUnlocked ? "lock.open.fill" : "lock.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(zPatchUnlocked ? .green : .orange)

                        Text(L("settings_zpatch_enable"))
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)

                        Spacer()

                        Text(zPatchUnlocked ? L("settings_zpatch_unlocked") : L("settings_zpatch_locked"))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(zPatchUnlocked ? .green : Color.white.opacity(0.5))
                    }
                    .padding(18)
                    .background(AppTheme.row)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)

                // Donate
                Button(action: {
                    if let url = URL(string: "https://ko-fi.com/yangjiii") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.pink)
                        Text(L("settings_donate"))
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                    .padding(18)
                    .background(AppTheme.row)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)

                // Thanks To
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("settings_thanks_to"))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 10) {
                        ThanksRow(name: "Carrot1211", description: "For cheering me on and supporting me during development.")
                        ThanksRow(name: "@khanhduytran0", description: "is based on SparseBox.")
                        ThanksRow(name: "@SideStore team", description: "idevice and C bindings from StikDebug.")
                        ThanksRow(name: "@JJTech0130", description: "SparseRestore and backup exploit.")
                        ThanksRow(name: "@hanakim3945", description: "bl_sbx exploit files and writeup.")
                        ThanksRow(name: "@Lakr233", description: "BBackupp.")
                        ThanksRow(name: "@libimobiledevice", description: L("settings_thanks_libimobile"))
                    }
                }
                
                // Language (Translators)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Language")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 10) {
                        // List all languages with translators from languages.json
                        ForEach(languageManager.availableLanguages.filter { $0.translator != nil && !($0.translator?.isEmpty ?? true) }) { langInfo in
                            ThanksRow(name: langInfo.translator ?? "", description: "\(langInfo.nativeName) (\(langInfo.name)) translation")
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(AppTheme.bg.ignoresSafeArea())
        .navigationTitle(L("nav_settings"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Refresh language list to get translator info
            if languageManager.availableLanguages.isEmpty {
                Task {
                    await languageManager.fetchAvailableLanguages()
                }
            }
        }
        .alert(L("settings_zpatch_passcode_title"), isPresented: $showPasscodeAlert) {
            TextField(L("settings_zpatch_passcode_placeholder"), text: $passcodeInput)
                .keyboardType(.numberPad)

            Button(L("alert_cancel"), role: .cancel) {
                passcodeInput = ""
            }

            Button(L("alert_unlock")) {
                if passcodeInput == "3105" {
                    zPatchUnlocked = true
                }
                passcodeInput = ""
            }
        } message: {
            Text(L("settings_zpatch_passcode_prompt"))
        }
    }
}

// MARK: - Components Helper
struct ThanksRow: View {
    let name: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text(description)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.row)
        .cornerRadius(12)
    }
}
