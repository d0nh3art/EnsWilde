import SwiftUI

struct ThemesUIView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject var toolStore: ToolStore
    let globalPrefsURL: URL
    
    @State private var globalPrefsDict: NSMutableDictionary = [:]
    @State private var showErrorAlert = false
    @State private var lastError: String?
    
    // Solarium/Liquid Glass toggles based on user's request
    @State private var solariumForceFallback = false          // SolariumForceFallback
    @State private var disableSolarium = false                 // com.apple.SwiftUI.DisableSolarium
    @State private var ignoreSolariumLinkedOnCheck = false     // com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck
    @State private var disallowGlassTime = false               // SBDisallowGlassTime
    @State private var disableGlassDock = false                // SBDisableGlassDock
    @State private var disableSpecularMotion = false           // SBDisableSpecularEverywhereUsingLSSAssertion
    @State private var disableOuterRefraction = false          // SolariumDisableOuterRefraction
    @State private var allowHDR = true                         // SolariumAllowHDR (inverted - false to disable)
    
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    // Enable Tool
                    AppSectionHeader(title: L("themes_ui_title"))
                    
                    CardRow(
                        title: L("enable_tool"),
                        subtitle: toolStore.themesUIEnabled ? L("enabled") : L("disabled"),
                        ok: nil,
                        showChevron: false,
                        trailing: AnyView(Toggle("", isOn: $toolStore.themesUIEnabled).labelsHidden())
                    )
                    .padding(.horizontal, 20)
                    
                    // Liquid Glass (Solarium) Section
                    AppSectionHeader(title: L("section_liquid_glass"))
                    
                    VStack(spacing: 0) {
                        // SolariumForceFallback
                        toggleRow(
                            title: L("themes_force_fallback"),
                            subtitle: L("themes_force_fallback_desc"),
                            binding: $solariumForceFallback
                        )
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.leading, 18)
                        
                        // DisableSolarium
                        toggleRow(
                            title: L("themes_disable_swiftui"),
                            subtitle: L("themes_disable_swiftui_desc"),
                            binding: $disableSolarium
                        )
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.leading, 18)
                        
                        // IgnoreSolariumLinkedOnCheck
                        toggleRow(
                            title: L("themes_ignore_check"),
                            subtitle: L("themes_ignore_check_desc"),
                            binding: $ignoreSolariumLinkedOnCheck
                        )
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.leading, 18)
                        
                        // SBDisallowGlassTime
                        toggleRow(
                            title: L("themes_disable_glass_time"),
                            subtitle: L("themes_disable_glass_time_desc"),
                            binding: $disallowGlassTime
                        )
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.leading, 18)
                        
                        // SBDisableGlassDock
                        toggleRow(
                            title: L("themes_disable_glass_dock"),
                            subtitle: L("themes_disable_glass_dock_desc"),
                            binding: $disableGlassDock
                        )
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.leading, 18)
                        
                        // SBDisableSpecularEverywhereUsingLSSAssertion
                        toggleRow(
                            title: L("themes_disable_specular"),
                            subtitle: L("themes_disable_specular_desc"),
                            binding: $disableSpecularMotion
                        )
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.leading, 18)
                        
                        // SolariumDisableOuterRefraction
                        toggleRow(
                            title: L("themes_disable_refraction"),
                            subtitle: L("themes_disable_refraction_desc"),
                            binding: $disableOuterRefraction
                        )
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.leading, 18)
                        
                        // SolariumAllowHDR (inverted)
                        toggleRow(
                            title: L("themes_disable_hdr"),
                            subtitle: L("themes_disable_hdr_desc"),
                            binding: Binding(
                                get: { !allowHDR },
                                set: { allowHDR = !$0 }
                            )
                        )
                    }
                    .background(AppTheme.row)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    Text(L("themes_controls_desc"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Save Section
                    AppSectionHeader(title: L("section_save_settings"))
                    
                    WalletStyleButton(title: L("themes_save_button")) {
                        saveGlobalPreferences()
                    }
                    .padding(.horizontal, 20)
                    
                    SecondaryActionButton(title: L("themes_reset_button")) {
                        resetAllSettings()
                    }
                    .padding(.horizontal, 20)
                    
                    Text(L("msg_tool_instruction"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(L("themes_important_warning"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 20)
                }
                .padding(.top, 6)
            }
        }
        .alert(L("alert_message"), isPresented: $showErrorAlert) {
            Button(L("alert_ok")) {}
        } message: {
            Text(lastError ?? "???")
        }
        .navigationTitle("Themes UI")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadGlobalPreferences()
        }
    }
    
    private func toggleRow(title: String, subtitle: String, binding: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(.white)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .onChange(of: binding.wrappedValue) {
                    updateGlobalPreferences()
                }
        }
        .padding(18)
        .background(AppTheme.row)
    }
    
    private func loadGlobalPreferences() {
        // Load existing preferences from Documents
        if FileManager.default.fileExists(atPath: globalPrefsURL.path) {
            do {
                globalPrefsDict = try NSMutableDictionary(contentsOf: globalPrefsURL, error: ())
                
                // Load all toggle states
                solariumForceFallback = (globalPrefsDict["SolariumForceFallback"] as? Bool) ?? false
                disableSolarium = (globalPrefsDict["com.apple.SwiftUI.DisableSolarium"] as? Bool) ?? false
                ignoreSolariumLinkedOnCheck = (globalPrefsDict["com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck"] as? Bool) ?? false
                disallowGlassTime = (globalPrefsDict["SBDisallowGlassTime"] as? Bool) ?? false
                disableGlassDock = (globalPrefsDict["SBDisableGlassDock"] as? Bool) ?? false
                disableSpecularMotion = (globalPrefsDict["SBDisableSpecularEverywhereUsingLSSAssertion"] as? Bool) ?? false
                disableOuterRefraction = (globalPrefsDict["SolariumDisableOuterRefraction"] as? Bool) ?? false
                allowHDR = (globalPrefsDict["SolariumAllowHDR"] as? Bool) ?? true
            } catch {
                // If file doesn't exist or is corrupt, start fresh
                globalPrefsDict = [:]
            }
        } else {
            // Start with empty dict
            globalPrefsDict = [:]
        }
    }
    
    private func updateGlobalPreferences() {
        // Update all keys based on toggle states
        globalPrefsDict["SolariumForceFallback"] = solariumForceFallback
        globalPrefsDict["com.apple.SwiftUI.DisableSolarium"] = disableSolarium
        globalPrefsDict["com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck"] = ignoreSolariumLinkedOnCheck
        globalPrefsDict["SBDisallowGlassTime"] = disallowGlassTime
        globalPrefsDict["SBDisableGlassDock"] = disableGlassDock
        globalPrefsDict["SBDisableSpecularEverywhereUsingLSSAssertion"] = disableSpecularMotion
        globalPrefsDict["SolariumDisableOuterRefraction"] = disableOuterRefraction
        globalPrefsDict["SolariumAllowHDR"] = allowHDR
    }
    
    private func saveGlobalPreferences() {
        updateGlobalPreferences() // Ensure dict is up-to-date
        do {
            try globalPrefsDict.write(to: globalPrefsURL)
            toolStore.themesUIEnabled = true
            lastError = "Saved! Now: 1) Go Home → Apply Enabled Tools, 2) Respring/Reboot device for changes to take effect."
            showErrorAlert = true
        } catch {
            lastError = "Failed to save: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    private func resetAllSettings() {
        solariumForceFallback = false
        disableSolarium = false
        ignoreSolariumLinkedOnCheck = false
        disallowGlassTime = false
        disableGlassDock = false
        disableSpecularMotion = false
        disableOuterRefraction = false
        allowHDR = true
        
        // Clear the dictionary
        globalPrefsDict.removeAllObjects()
        
        lastError = "All Themes UI settings have been reset to defaults."
        showErrorAlert = true
    }
    
    init(toolStore: ToolStore) {
        self.toolStore = toolStore
        let documentsDirectory = URL.documentsDirectory
        globalPrefsURL = documentsDirectory.appendingPathComponent("GlobalPreferences.plist", conformingTo: .data)
    }
}
