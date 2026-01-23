//
//  LanguageSettingsView.swift
//  EnsWilde
//

import SwiftUI

struct LanguageSettingsView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var downloadingLanguage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Current Language
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("settings_language_current"))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 8)
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.green)
                        
                        Text(getLanguageName(localizationManager.currentLanguage))
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Spacer()
                    }
                    .padding(18)
                    .background(AppTheme.row)
                    .cornerRadius(16)
                }
                
                // Refresh Button
                Button(action: {
                    Task {
                        await languageManager.fetchAvailableLanguages()
                        if let error = languageManager.lastError {
                            errorMessage = error
                            showErrorAlert = true
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.accent)
                        
                        Text(L("settings_language_refresh"))
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        if languageManager.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .padding(18)
                    .background(AppTheme.row)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .disabled(languageManager.isLoading)
                
                // Available Languages
                if !languageManager.availableLanguages.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("settings_language_available"))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.top, 8)
                        
                        ForEach(languageManager.availableLanguages) { language in
                            LanguageRow(
                                language: language,
                                isSelected: localizationManager.currentLanguage == language.code,
                                isDownloaded: languageManager.isDownloaded(language.code),
                                hasUpdate: languageManager.hasUpdate(language),
                                isDownloading: downloadingLanguage == language.code,
                                onSelect: {
                                    localizationManager.currentLanguage = language.code
                                },
                                onDownload: {
                                    Task {
                                        downloadingLanguage = language.code
                                        let success = await languageManager.downloadLanguage(language)
                                        downloadingLanguage = nil
                                        
                                        if success {
                                            // Automatically switch to downloaded language
                                            localizationManager.currentLanguage = language.code
                                        } else if let error = languageManager.lastError {
                                            errorMessage = error
                                            showErrorAlert = true
                                        }
                                    }
                                },
                                onDelete: {
                                    // Don't allow deleting current language
                                    if localizationManager.currentLanguage == language.code {
                                        errorMessage = L("error_cannot_delete_current_language")
                                        showErrorAlert = true
                                        return
                                    }
                                    languageManager.deleteLanguage(language.code)
                                }
                            )
                        }
                    }
                } else if !languageManager.isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "network.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.white.opacity(0.3))
                        
                        Text(L("settings_language_no_available"))
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.5))
                        
                        Text(L("settings_language_refresh_prompt"))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(AppTheme.bg.ignoresSafeArea())
        .navigationTitle(L("settings_language"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(L("alert_error"), isPresented: $showErrorAlert) {
            Button(L("alert_ok"), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Load languages on appear
            if languageManager.availableLanguages.isEmpty {
                Task {
                    await languageManager.fetchAvailableLanguages()
                }
            }
        }
    }
    
    private func getLanguageName(_ code: String) -> String {
        if let language = languageManager.availableLanguages.first(where: { $0.code == code }) {
            return "\(language.name) (\(language.nativeName))"
        }
        return code == "en" ? "English" : code
    }
}

// MARK: - Language Row Component

struct LanguageRow: View {
    let language: LanguageInfo
    let isSelected: Bool
    let isDownloaded: Bool
    let hasUpdate: Bool
    let isDownloading: Bool
    let onSelect: () -> Void
    let onDownload: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Language info
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.name)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(language.nativeName)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                
                Spacer()
                
                // Status indicators and actions
                HStack(spacing: 12) {
                    if isDownloading {
                        ProgressView()
                            .tint(.white)
                    } else if hasUpdate {
                        Button(action: onDownload) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.orange)
                        }
                    } else if isDownloaded {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.green)
                        } else {
                            HStack(spacing: 8) {
                                Button(action: onSelect) {
                                    Text(L("settings_language_use"))
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(AppTheme.accent)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(AppTheme.accent.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                
                                Button(action: onDelete) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    } else {
                        Button(action: onDownload) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 18))
                                Text(L("settings_language_download"))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.accent.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(18)
            .background(AppTheme.row)
            .cornerRadius(16)
        }
    }
}
