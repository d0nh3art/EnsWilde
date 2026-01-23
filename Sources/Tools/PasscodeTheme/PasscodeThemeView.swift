import SwiftUI
import UniformTypeIdentifiers

// MARK: - Passcode Theme View
struct PasscodeThemeView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject var themeStore: PasscodeThemeStore
    @StateObject private var viewModel: PasscodeThemeViewModel
    @State private var showImportSheet = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    init(themeStore: PasscodeThemeStore) {
        self.themeStore = themeStore
        self._viewModel = StateObject(wrappedValue: PasscodeThemeViewModel(store: themeStore))
    }
    
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    AppSectionHeader(title: L("passcode_theme_manager"))
                    
                    // Enable Toggle
                    CardRow(
                        title: L("passcode_enable_theme"),
                        subtitle: themeStore.passcodeThemeEnabled ? L("enabled") : L("disabled"),
                        ok: nil,
                        showChevron: false,
                        trailing: AnyView(Toggle("", isOn: $themeStore.passcodeThemeEnabled).labelsHidden())
                    )
                    .padding(.horizontal, 20)
                    
                    Text(L("msg_tool_enable_instruction"))
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Theme Library
                    AppSectionHeader(title: L("section_theme_library"))
                    
                    if themeStore.themes.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.white.opacity(0.3))
                            Text(L("passcode_no_themes"))
                                .font(.system(size: 16, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(themeStore.themes) { theme in
                                NavigationLink(destination: ThemeDetailView(theme: theme, themeStore: themeStore, viewModel: viewModel)) {
                                    ThemeRowView(theme: theme, themeStore: themeStore)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Import Button
                    AppSectionHeader(title: L("section_import_theme"))
                    
                    WalletStyleButton(title: L("passcode_import_file")) {
                        showImportSheet = true
                    }
                    .padding(.horizontal, 20)
                    
                    Text(L("passcode_import_desc"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 20)
                }
                .padding(.top, 6)
            }
        }
        .navigationTitle(L("tool_passcode_theme"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImportSheet) {
            ImportThemeSheet(viewModel: viewModel, themeStore: themeStore)
        }
        .alert(L("alert_error"), isPresented: $showErrorAlert) {
            Button(L("alert_ok")) {}
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Theme Row View
struct ThemeRowView: View {
    let theme: PasscodeTheme
    @ObservedObject var themeStore: PasscodeThemeStore
    
    var body: some View {
        HStack(spacing: 12) {
            // Preview Image
            if let previewImage = theme.getPreviewImage() {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(Color.white.opacity(0.5))
                    )
            }
            
            // Theme Info
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.name)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(theme.customPrefix.rawValue) • \(theme.keySize.rawValue) • \(theme.telephonyVersion.rawValue)")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Selection Radio Button
            Image(systemName: theme.isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundStyle(theme.isSelected ? .green : Color.white.opacity(0.3))
                .onTapGesture {
                    themeStore.selectTheme(theme)
                }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.white.opacity(0.55))
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(18)
        .background(AppTheme.row)
        .cornerRadius(16)
    }
}

// MARK: - Theme Detail View
struct ThemeDetailView: View {
    @State var theme: PasscodeTheme
    @ObservedObject var themeStore: PasscodeThemeStore
    @ObservedObject var viewModel: PasscodeThemeViewModel
    @State private var showDeleteAlert = false
    @State private var showFullPreview = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Preview
                    AppSectionHeader(title: L("section_preview"))
                    
                    if let previewImage = theme.getPreviewImage() {
                        VStack(spacing: 12) {
                            Image(uiImage: previewImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 120)
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                            
                            Button {
                                showFullPreview = true
                            } label: {
                                HStack {
                                    Image(systemName: "eye.fill")
                                    Text(L("passcode_view_all_keys"))
                                }
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.row)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Theme Info
                    AppSectionHeader(title: L("section_theme_settings"))
                    
                    VStack(spacing: 12) {
                        // Theme Name
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("passcode_theme_name"))
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                TextField(L("passcode_theme_name"), text: $theme.name)
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white)
                                    .onChange(of: theme.name) { _ in themeStore.updateTheme(theme) }
                            }
                            Spacer()
                        }
                        .padding(18)
                        .background(AppTheme.row)
                        .cornerRadius(16)
                        
                        // Custom Prefix Picker
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("passcode_language_method"))
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                
                                Picker("Language Prefix", selection: $theme.customPrefix) {
                                    ForEach(PasscodeTheme.PrefixLanguage.allCases, id: \.self) { prefix in
                                        Text(prefix.displayName).tag(prefix)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.white)
                                .onChange(of: theme.customPrefix) { _ in themeStore.updateTheme(theme) }
                                
                                Text(theme.customPrefix.description)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(18)
                        .background(AppTheme.row)
                        .cornerRadius(16)
                        
                        // Detected Size Info
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("passcode_detected_size"))
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text(sizeDescription(for: theme.detectedSize))
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            Image(systemName: "info.circle")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(18)
                        .background(AppTheme.row)
                        .cornerRadius(16)
                        
                        // Key Size (FIXED: Changed label from detected_size to target_key_size)
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L("passcode_target_key_size"))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            Picker("Key Size", selection: $theme.keySize) {
                                ForEach(PasscodeTheme.KeySize.allCases, id: \.self) { size in
                                    Text(size.rawValue).tag(size)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: theme.keySize) { _ in themeStore.updateTheme(theme) }
                            
                            Text(scalingDescription(from: theme.detectedSize, to: theme.keySize))
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(18)
                        .background(AppTheme.row)
                        .cornerRadius(16)
                        
                        // Telephony Version Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L("passcode_telephony_version"))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            Picker(L("passcode_telephony_version"), selection: $theme.telephonyVersion) {
                                ForEach(PasscodeTheme.TelephonyVersion.allCases, id: \.self) { version in
                                    Text(version.displayName).tag(version)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: theme.telephonyVersion) { _ in themeStore.updateTheme(theme) }
                            
                            Text(L("passcode_telephony_desc"))
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(18)
                        .background(AppTheme.row)
                        .cornerRadius(16)
                        
                        // Selection
                        CardRow(
                            title: L("passcode_selected_theme"),
                            subtitle: theme.isSelected ? L("passcode_theme_selected") : L("passcode_theme_not_selected"),
                            ok: theme.isSelected ? true : nil,
                            showChevron: false,
                            trailing: AnyView(
                                Button {
                                    themeStore.selectTheme(theme)
                                    theme.isSelected = true
                                } label: {
                                    Text(theme.isSelected ? L("passcode_selected") : L("passcode_select"))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(theme.isSelected ? .green : .white)
                                }
                            )
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Files Info
                    AppSectionHeader(title: L("section_theme_files"))
                    
                    let imageFiles = theme.getImageFiles()
                    Text("\(imageFiles.count) image file(s) found")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    // Delete
                    AppSectionHeader(title: L("section_danger_zone"))
                    
                    SecondaryActionButton(title: L("passcode_delete_theme")) {
                        showDeleteAlert = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 6)
            }
        }
        .navigationTitle(theme.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFullPreview) {
            FullPasscodePreviewSheet(theme: theme)
        }
        .alert(L("passcode_delete_theme"), isPresented: $showDeleteAlert) {
            Button(L("alert_cancel"), role: .cancel) {}
            Button(L("alert_delete"), role: .destructive) {
                themeStore.deleteTheme(theme)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this theme? This action cannot be undone.")
        }
    }
    
    
    // Helper functions for size descriptions
    private func sizeDescription(for detectedSize: PasscodeTheme.DetectedSize) -> String {
        switch detectedSize {
        case .small:
            return "Small Keys (202px)"
        case .big:
            return "Big Keys (287px)"
        case .unknown:
            return "Unknown (will use target size)"
        }
    }
    
    private func scalingDescription(from detectedSize: PasscodeTheme.DetectedSize, to targetSize: PasscodeTheme.KeySize) -> String {
        if detectedSize == .unknown {
            return "No scaling info available - images will be used as-is"
        } else if (detectedSize == .small && targetSize == .big) {
            return "Will scale up from small to big (×1.42)"
        } else if (detectedSize == .big && targetSize == .small) {
            return "Will scale down from big to small (×0.70)"
        } else {
            return "No scaling needed - sizes match"
        }
    }
}

// MARK: - Import Theme Sheet
struct ImportThemeSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: PasscodeThemeViewModel
    @ObservedObject var themeStore: PasscodeThemeStore
    @State private var themeName = ""
    @State private var showFilePicker = false
    @State private var selectedFileURL: URL?
    @State private var isImporting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if let url = selectedFileURL {
                        Text("Selected: \(url.lastPathComponent)")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    Form {
                        Section(header: Text("Theme Information")) {
                            TextField(L("passcode_theme_name"), text: $themeName)
                                .autocorrectionDisabled()
                        }
                        
                        Section {
                            Button("Select .passthm File") {
                                showFilePicker = true
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    
                    if isImporting {
                        ProgressView("Importing theme...")
                            .tint(AppTheme.accent)
                    }
                }
            }
            .navigationTitle(L("section_import_theme"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("alert_cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        importTheme()
                    }
                    .disabled(themeName.isEmpty || selectedFileURL == nil || isImporting)
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.passthm, .zip],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        selectedFileURL = url
                        if themeName.isEmpty {
                            themeName = url.deletingPathExtension().lastPathComponent
                        }
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
            .alert(L("alert_error"), isPresented: .constant(errorMessage != nil)) {
                Button(L("alert_ok")) { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func importTheme() {
        guard let url = selectedFileURL else { return }
        
        isImporting = true
        Task {
            do {
                try await viewModel.importTheme(from: url, name: themeName)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isImporting = false
                }
            }
        }
    }
}

// MARK: - Full Passcode Preview Sheet
struct FullPasscodePreviewSheet: View {
    let theme: PasscodeTheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Info
                        Text("All passcode keys from \(theme.name)")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.top, 10)
                        
                        // Get all passcode key images
                        let keyImages = getAllPasscodeKeyImages()
                        
                        if keyImages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Color.white.opacity(0.3))
                                Text("No passcode key images found")
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            // Display keys in a grid (3 columns for numeric keypad layout)
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(keyImages, id: \.key) { item in
                                    if item.key == "empty" {
                                        // Empty placeholder
                                        Color.clear
                                            .frame(maxWidth: 100, maxHeight: 100)
                                    } else {
                                        VStack(spacing: 6) {
                                            Image(uiImage: item.image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxWidth: 100, maxHeight: 100)
                                                .cornerRadius(8)
                                            
                                            Text(item.label)
                                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            Text("\(keyImages.count) key image(s)")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .padding(.top, 10)
                                .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("All Passcode Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func getAllPasscodeKeyImages() -> [(key: String, label: String, image: UIImage)] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: theme.themeFolderURL.path) else { return [] }
        
        var keyImages: [(String, String, UIImage)] = []
        
        // Define the keys in proper iPhone passcode keyboard order: 1-2-3, 4-5-6, 7-8-9, empty-0-empty
        // iPhone passcode layout: 0 should be below 8 (middle column)
        // Grid positions: [0,1,2], [3,4,5], [6,7,8], [9,10,11]
        // Row 4 has empty spaces: empty below 7, 0 below 8, empty below 9
        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "empty", "0", "empty"]
        let labels = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", ""]
        
        for (index, key) in keys.enumerated() {
            // Skip empty slots
            if key == "empty" {
                keyImages.append((key, labels[index], UIImage()))  // Add empty placeholder
                continue
            }
            
            // Look for files containing the key pattern
            if let file = files.first(where: {
                $0.lowercased().contains("-\(key)-") ||
                $0.lowercased().contains("-\(key)@") ||
                $0.lowercased().contains("_\(key)_") ||
                $0.lowercased().contains("_\(key)@")
            }) {
                let imageURL = theme.themeFolderURL.appendingPathComponent(file)
                if let image = UIImage(contentsOfFile: imageURL.path) {
                    keyImages.append((key, labels[index], image))
                }
            }
        }
        
        return keyImages
    }
}
