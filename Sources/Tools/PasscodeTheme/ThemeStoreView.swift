import SwiftUI

// MARK: - Theme Store View
struct ThemeStoreView: View {
    @StateObject private var storeManager = ThemeStoreManager()
    @ObservedObject var themeStore: PasscodeThemeStore
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // Use LocalizationManager directly without observing to prevent crashes
    private var localizationManager: LocalizationManager { LocalizationManager.shared }
    
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
            if let selectedRepo = storeManager.selectedRepository {
                // Show themes from selected repository
                ThemesListView(
                    repository: selectedRepo,
                    themeStore: themeStore,
                    storeManager: storeManager
                )
            } else {
                // Show repository list
                RepositoriesListView(
                    storeManager: storeManager
                )
            }
        }
        .task {
            if storeManager.repositories.isEmpty {
                await storeManager.fetchRepositories()
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Repositories List View
struct RepositoriesListView: View {
    @ObservedObject var storeManager: ThemeStoreManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AppSectionHeader(title: L("theme_store_title"))
                
                if storeManager.isLoading {
                    ProgressView(L("theme_store_loading"))
                        .tint(.white)
                        .padding(.vertical, 40)
                } else if let error = storeManager.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.red.opacity(0.8))
                        Text(error)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            Task {
                                await storeManager.fetchRepositories()
                            }
                        } label: {
                            Text(L("theme_store_retry"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.accent)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if storeManager.repositories.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.white.opacity(0.3))
                        Text(L("theme_store_no_themes"))
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(storeManager.repositories) { repository in
                            RepositoryRowView(repository: repository, storeManager: storeManager)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Text(L("theme_store_credit"))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.bottom, 20)
            }
            .padding(.top, 6)
        }
        .refreshable {
            await storeManager.fetchRepositories()
        }
    }
}

// MARK: - Repository Row View
struct RepositoryRowView: View {
    let repository: ThemeRepository
    @ObservedObject var storeManager: ThemeStoreManager
    @State private var themeCount: Int?
    
    var body: some View {
        Button {
            Task {
                await storeManager.fetchThemes(from: repository)
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(LinearGradient(
                        colors: [Color(hex: 0xAEEBFF), Color(hex: 0xE6B2FF)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(repository.name)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                    
                    if let count = themeCount {
                        Text("\(count) themes")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        Text("Loading...")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(18)
            .background(AppTheme.row)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            await fetchThemeCount()
        }
    }
    
    private func fetchThemeCount() async {
        guard let url = URL(string: repository.themesURL) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let themes = try JSONDecoder().decode([RemoteThemeCodable].self, from: data)
            await MainActor.run {
                themeCount = themes.count
            }
        } catch {
            // Silently fail - we'll just show "Loading..." 
        }
    }
}

// MARK: - Themes List View  
struct ThemesListView: View {
    let repository: ThemeRepository
    @ObservedObject var themeStore: PasscodeThemeStore
    @ObservedObject var storeManager: ThemeStoreManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Back button and header
                HStack {
                    Button {
                        storeManager.backToRepositories()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text(L("theme_store_title"))
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                
                AppSectionHeader(title: repository.name)
                
                if storeManager.isLoading {
                    ProgressView(L("theme_store_loading"))
                        .tint(.white)
                        .padding(.vertical, 40)
                } else if let error = storeManager.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.red.opacity(0.8))
                        Text(error)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            Task {
                                await storeManager.fetchThemes(from: repository)
                            }
                        } label: {
                            Text(L("theme_store_retry"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.accent)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if storeManager.remoteThemes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.white.opacity(0.3))
                        Text(L("theme_store_no_themes"))
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(storeManager.remoteThemes) { theme in
                            RemoteThemeRowView(
                                theme: theme,
                                themeStore: themeStore,
                                storeManager: storeManager
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Text(L("theme_store_credit"))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.bottom, 20)
            }
        }
        .refreshable {
            await storeManager.fetchThemes(from: repository)
        }
    }
}

// MARK: - Remote Theme Row View
struct RemoteThemeRowView: View {
    let theme: RemoteTheme
    @ObservedObject var themeStore: PasscodeThemeStore
    @ObservedObject var storeManager: ThemeStoreManager
    @State private var previewImage: UIImage?
    @State private var isDownloading = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // Use LocalizationManager directly without observing to prevent crashes
    private var localizationManager: LocalizationManager { LocalizationManager.shared }
    
    // Check if theme is already downloaded
    private var isDownloaded: Bool {
        themeStore.themes.contains { $0.name == theme.name }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Preview Image
                if let image = previewImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 70, height: 70)
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                }
                
                // Theme Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(theme.name)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(theme.description)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                    
                    Text("by \(theme.authors)")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(18)
            
            // Download Button or Downloaded Indicator
            if isDownloaded {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(L("theme_store_downloaded"))
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            } else {
                Button {
                    downloadTheme()
                } label: {
                    HStack {
                        if isDownloading {
                            ProgressView()
                                .tint(Color.black.opacity(0.75))
                            Text(L("theme_store_downloading"))
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                            Text(L("theme_store_download_import"))
                        }
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.86))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(downloadButtonBackground)
                }
                .disabled(isDownloading)
                .opacity(isDownloading ? 0.55 : 1.0)
                .saturation(isDownloading ? 0.0 : 1.0)
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
        .background(AppTheme.row)
        .cornerRadius(16)
        .task {
            await loadPreviewImage()
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // Download button background with gradient
    private var downloadButtonBackground: some View {
        let grad = LinearGradient(
            colors: [Color(hex: 0xAEEBFF), Color(hex: 0xE6B2FF), Color(hex: 0xFFE08A)],
            startPoint: .leading, endPoint: .trailing
        )
        
        return RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(grad)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 5)
    }
    
    private func loadPreviewImage() async {
        guard let url = theme.previewURL else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    previewImage = image
                }
            }
        } catch {
            // Silently fail for preview images - not critical
        }
    }
    
    private func downloadTheme() {
        isDownloading = true
        
        Task {
            do {
                try await storeManager.downloadAndImportTheme(theme, themeStore: themeStore)
                
                await MainActor.run {
                    isDownloading = false
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}
