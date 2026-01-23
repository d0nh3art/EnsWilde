import SwiftUI
import UniformTypeIdentifiers

struct MobileGestaltView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    let origMGURL, modMGURL, featFlagsURL, resolutionURL: URL
    @Environment(\.scenePhase) var scenePhase
    @ObservedObject var toolStore: ToolStore

    @State var mbdb: Backup?
    @State var eligibilityData = Data()
    @State var featureFlagsData = Data()
    @State var mobileGestalt: NSMutableDictionary
    @State var productType = machineName()
    @State var respring = true
    @State var showPairingFileImporter = false
    @State var showErrorAlert = false
    @State var taskRunning = false
    @State var initError: String?
    @State var lastError: String?
    @State var dynamicIslandType: Int = 0 // 0 = None, 1-7 = different types
    @State var enableRdarFix: Bool = false
    @State var enableModelName: Bool = false
    @State var modelName: String = ""

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    // MobileGestalt Section
                    AppSectionHeader(title: L("tool_mobile_gestalt"))
                    
                    // Enable Tweak Toggle
                    CardRow(
                        title: L("enable_tweak"),
                        subtitle: toolStore.replaceMobileGestaltEnabled ? L("enabled") : L("disabled"),
                        ok: nil,
                        showChevron: false,
                        trailing: AnyView(Toggle("", isOn: $toolStore.replaceMobileGestaltEnabled).labelsHidden())
                    )
                    .padding(.horizontal, 20)
                    
                    // Device Subtype & Dynamic Island Section
                    AppSectionHeader(title: L("section_device_subtype"))
                    
                    VStack(spacing: 0) {
                        // Dynamic Island Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L("mg_device_subtype_preset"))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            Picker("Device Subtype", selection: $dynamicIslandType) {
                                Text(L("mg_subtype_none")).tag(0)
                                Text(L("mg_subtype_2436")).tag(1)
                                Text(L("mg_subtype_2556")).tag(2)
                                Text(L("mg_subtype_2796")).tag(3)
                                Text(L("mg_subtype_2976")).tag(4)
                                Text(L("mg_subtype_2622")).tag(5)
                                Text(L("mg_subtype_2868")).tag(6)
                                Text(L("mg_subtype_2736")).tag(7)
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                            .onChange(of: dynamicIslandType) { newValue in
                                applyDynamicIsland(type: newValue)
                            }
                        }
                        .padding(18)
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 18)
                        
                        // RDAR Fix Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("mg_rdar_fix"))
                                    .foregroundStyle(.white)
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                Text(L("mg_rdar_fix_desc"))
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: $enableRdarFix)
                                .labelsHidden()
                                .disabled(dynamicIslandType == 0)
                        }
                        .padding(18)
                        .opacity(dynamicIslandType == 0 ? 0.5 : 1.0)
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 18)
                        
                        // Change Device Model Name
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(L("mg_change_model_name"))
                                    .foregroundStyle(.white)
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                Spacer()
                                Toggle("", isOn: $enableModelName)
                                    .labelsHidden()
                            }
                            
                            if enableModelName {
                                TextField(L("mg_model_name_placeholder"), text: $modelName)
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundStyle(.white)
                            }
                            
                            Text(L("mg_model_name_desc"))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(18)
                    }
                    .background(AppTheme.row)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // Hardware Features (Grouped - no spacing)
                    AppSectionHeader(title: L("section_hardware_features"))
                    VStack(spacing: 0) {
                        // Boot & Sound
                        groupedToggleRow(L("mg_boot_chime"), binding: bindingForMGKeys(["QHxt+hGLaBPbQJbXiUJX3w"]), isFirst: true)
                        groupedToggleRow(L("mg_charge_limit"), binding: bindingForMGKeys(["37NVydb//GP/GrhuTN+exg"]), disabled: Utils.requiresVersion(17))
                        if UIDevice._hasHomeButton() {
                            groupedToggleRow(L("mg_tap_to_wake"), binding: bindingForMGKeys(["yZf3GTRMGTuwSV/lD7Cagw"]))
                        }
                        groupedToggleRow(L("mg_camera_button"), binding: bindingForMGKeys(["CwvKxM2cEogD3p+HYgaW0Q", "oOV1jhJbdV3AddkcCg0AEA"]), disabled: Utils.requiresVersion(18), isLast: true)
                    }
                    .padding(.horizontal, 20)
                    
                    // UI Effects
                    VStack(spacing: 0) {
                        groupedToggleRow(L("mg_disable_parallax"), binding: bindingForMGKeys(["UIParallaxCapability"], type: Int.self, defaultValue: 1, enableValue: 0), isFirst: true)
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            groupedToggleRow(L("mg_stage_manager"), binding: bindingForMGKeys(["qeaj75wk3HF4DwQ8qbIi7g"]), isLast: true)
                        } else {
                            groupedToggleRow(L("mg_stage_manager"), binding: bindingForMGKeys(["qeaj75wk3HF4DwQ8qbIi7g"]), isLast: UIDevice.current.userInterfaceIdiom != .pad)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // iPad Features
                    VStack(spacing: 0) {
                        groupedToggleRow(L("mg_install_ipad_apps"), binding: bindingForMGKeys(["9MZ5AdH43csAUajl/dU+IQ"], type: [Int].self, defaultValue: [1], enableValue: [1, 2]), isFirst: true, isLast: true)
                    }
                    .padding(.horizontal, 20)
                    
                    // Region & Location
                    VStack(spacing: 0) {
                        groupedToggleRow(L("mg_disable_region"), binding: bindingForRegionRestriction(), isFirst: true)
                        groupedToggleRow(L("mg_find_my_friends"), binding: bindingForMGKeys(["Y2Y67z0Nq/XdDXgW2EeaVg"]), isLast: true)
                    }
                    .padding(.horizontal, 20)
                    
                    // Accessories
                    VStack(spacing: 0) {
                        groupedToggleRow(L("mg_apple_pencil"), binding: bindingForMGKeys(["yhHcB0iH0d1XzPO/CFd3ow"]), isFirst: true)
                        groupedToggleRow(L("mg_action_button"), binding: bindingForMGKeys(["cT44WE1EohiwRzhsZ8xEsw"]), disabled: Utils.requiresVersion(17), isLast: true)
                    }
                    .padding(.horizontal, 20)
                    
                    // Internal Features
                    VStack(spacing: 0) {
                        groupedToggleRow(L("mg_internal_storage"), binding: bindingForMGKeys(["LBJfwOEzExRxzlAnSuI7eg"]), isFirst: true)
                        groupedToggleRow(L("mg_internal_stuff"), binding: bindingForInternalStuff())
                        groupedToggleRow(L("mg_security_research"), binding: bindingForMGKeys(["XYlJKKkj2hztRP1NWWnhlw"]))
                        groupedToggleRow(L("mg_metal_hud"), binding: bindingForMGKeys(["EqrsVvjcYDdxHBiQmGhAWw"]), isLast: true)
                    }
                    .padding(.horizontal, 20)
                    
                    // Safety Features
                    VStack(spacing: 0) {
                        groupedToggleRow(L("mg_crash_detection"), binding: bindingForMGKeys(["HCzWusHQwZDea6nNhaKndw"]), isFirst: true, isLast: true)
                    }
                    .padding(.horizontal, 20)
                    
                    // Display Features (iOS 18+)
                    VStack(spacing: 0) {
                        groupedToggleRow(L("mg_aod"), binding: bindingForMGKeys(["j8/Omm6s1lsmTDFsXjsBfA", "2OOJf1VhaM7NxfRok3HbWQ"]), disabled: Utils.requiresVersion(18), isFirst: true)
                        groupedToggleRow(L("mg_aod_vibrancy"), binding: bindingForMGKeys(["ykpu7qyhqFweVMKtxNylWA"]), disabled: Utils.requiresVersion(18))
                        groupedToggleRow(L("mg_enable_lglpm"), binding: bindingForMGKeys(["SAGvsp6O6kAQ4fEfDJpC4Q"]))
                        groupedToggleRow(L("mg_disable_lglpm"), binding: bindingForMGKeys(["SAGvsp6O6kAQ4fEfDJpC4Q"], type: Int.self, defaultValue: 1, enableValue: 0), isLast: true)
                    }
                    .padding(.horizontal, 20)
                    
                    // AI Features
                    VStack(spacing: 0) {
                        groupedToggleRow(L("mg_apple_intelligence"), binding: bindingForAppleIntelligence(), disabled: Utils.requiresVersion(18), isFirst: true, isLast: true)
                    }
                    .padding(.horizontal, 20)
                    
                    // Device spoofing Section
                    AppSectionHeader(title: L("section_device_spoofing"))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("mg_device_model"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        Picker(L("mg_device_model"), selection: $productType) {
                            Text(L("mg_device_model_unchanged")).tag(MobileGestaltView.machineName())
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                Text("iPad Pro 11 inch 5th Gen").tag("iPad16,3")
                            } else {
                                Text("iPhone 15 Pro Max").tag("iPhone16,2")
                                Text("iPhone 16 Pro Max").tag("iPhone17,2")
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                        
                        Text("Only change device model if you're downloading Apple Intelligence models. Face ID may break.")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(18)
                    .background(AppTheme.row)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // iPadOS Section
                    AppSectionHeader(title: "iPadOS")
                    
                    let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary
                    toggleCardRow("Become iPadOS", binding: bindingForTrollPad(), disabled: cacheExtra?["+3Uf0Pm5F8Xy7Onyvko0vA"] as? String != "iPhone")
                        .padding(.horizontal, 20)
                    
                    Text("Override user interface idiom to iPadOS, so you could use all iPadOS multitasking features on iPhone. Gives you the same capabilities as TrollPad, but may cause some issues.\nPLEASE DO NOT TURN OFF SHOW DOCK IN STAGE MANAGER OTHERWISE YOUR PHONE WILL BOOTLOOP WHEN ROTATING TO LANDSCAPE.")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Save / Reset Section
                    AppSectionHeader(title: "Save / Reset")
                    
                    WalletStyleButton(title: L("mg_save_settings")) {
                        do {
                            saveProductType()
                            try mobileGestalt.write(to: modMGURL)
                            
                            // Save resolution plist for RDAR fix
                            try saveResolutionPlist()
                            
                            lastError = "Saved ModifiedMobileGestalt.plist. Now go Home → Apply Enabled Tools."
                            showErrorAlert = true
                        } catch {
                            lastError = "Save failed: \(error)"
                            showErrorAlert = true
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    SecondaryActionButton(title: "Reset Original") {
                        do {
                            let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary
                            let wasTrollPadEnabled = (cacheExtra?["uKc7FPnEO++lVhHWHFlGbQ"] as? Int) == 1
                            
                            try? FileManager.default.removeItem(at: modMGURL)
                            try FileManager.default.copyItem(at: origMGURL, to: modMGURL)
                            mobileGestalt = try NSMutableDictionary(contentsOf: modMGURL, error: ())
                            toolStore.replaceMobileGestaltEnabled = true
                            
                            if wasTrollPadEnabled {
                                toolStore.bookassetdUUID = nil
                                lastError = "Reset done. MobileGestalt tool enabled. Bookassetd UUID cleared (iPadOS was enabled). Now go Home → Apply Enabled Tools to apply the reset to system."
                            } else {
                                lastError = "Reset done. MobileGestalt tool enabled. Now go Home → Apply Enabled Tools to apply the reset to system."
                            }
                            showErrorAlert = true
                        } catch {
                            lastError = "Reset failed: \(error)"
                            showErrorAlert = true
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Text("This screen only edits files in Documents. Use Home → Apply Enabled Tools to apply to system.")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 20)
                }
                .padding(.top, 6)
            }
        }
        .alert("Message", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(lastError ?? "???")
        }
        .navigationTitle(L("tool_mobile_gestalt"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if initError != nil {
                lastError = initError
                initError = nil
                showErrorAlert.toggle()
                return
            }

            if let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary {
                productType = cacheExtra["h9jDsbgj7xIVeIQ8S3/X3Q"] as? String ?? productType
                
                // Load Dynamic Island setting
                if let diValue = cacheExtra["oPeik/9e8lQWMszEjbPzng"] as? NSDictionary,
                   let subtype = diValue["ArtworkDeviceSubType"] as? Int {
                    switch subtype {
                    case 2436: dynamicIslandType = 1
                    case 2556: dynamicIslandType = 2
                    case 2796: dynamicIslandType = 3
                    case 2976: dynamicIslandType = 4
                    case 2622: dynamicIslandType = 5
                    case 2868: dynamicIslandType = 6
                    case 2736: dynamicIslandType = 7
                    default: dynamicIslandType = 0
                    }
                }
                
                // Load Model Name setting
                if let diValue = cacheExtra["oPeik/9e8lQWMszEjbPzng"] as? NSDictionary,
                   let modelNameValue = diValue["ArtworkDeviceProductDescription"] as? String,
                   !modelNameValue.isEmpty {
                    enableModelName = true
                    modelName = modelNameValue
                }
            }
            
            // Load RDAR Fix state from resolution plist
            loadRdarFixState()
        }
        .onChange(of: enableModelName) { enabled in
            if enabled {
                applyModelName()
            } else {
                removeModelName()
            }
        }
        .onChange(of: modelName) { _ in
            if enableModelName && !modelName.isEmpty {
                applyModelName()
            }
        }
        .onChange(of: scenePhase) { _ in
            if scenePhase == .inactive {
                Utils.bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                    UIApplication.shared.endBackgroundTask(Utils.bgTask)
                    Utils.bgTask = .invalid
                })
            } else if scenePhase == .active {
                if Utils.bgTask != .invalid {
                    UIApplication.shared.endBackgroundTask(Utils.bgTask)
                    Utils.bgTask = .invalid
                }
            }
        }
    }
    
    // Helper function to create toggle rows
    private func toggleCardRow(_ title: String, binding: Binding<Bool>, disabled: Bool = false) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(.white)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
            }
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .disabled(disabled)
        }
        .padding(18)
        .background(AppTheme.row)
        .cornerRadius(16)
        .opacity(disabled ? 0.5 : 1.0)
    }
    
    // Helper function for grouped rows (stick together like Settings.app)
    private func groupedToggleRow(_ title: String, binding: Binding<Bool>, disabled: Bool = false, isFirst: Bool = false, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            if isFirst {
                Divider().opacity(0)
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(.white)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                }
                Spacer()
                Toggle("", isOn: binding)
                    .labelsHidden()
                    .disabled(disabled)
            }
            .padding(18)
            .background(AppTheme.row)
            .opacity(disabled ? 0.5 : 1.0)
            
            if !isLast {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 18)
            }
        }
        .background(AppTheme.row)
        .cornerRadius(isFirst && isLast ? 16 : (isFirst ? 16 : (isLast ? 16 : 0)), corners: isFirst && isLast ? .allCorners : (isFirst ? [.topLeft, .topRight] : (isLast ? [.bottomLeft, .bottomRight] : [])))
    }

    init(toolStore: ToolStore) {
        self.toolStore = toolStore
        
        let documentsDirectory = URL.documentsDirectory
        featFlagsURL = documentsDirectory.appendingPathComponent("FeatureFlags.plist", conformingTo: .data)
        origMGURL = documentsDirectory.appendingPathComponent("OriginalMobileGestalt.plist", conformingTo: .data)
        modMGURL = documentsDirectory.appendingPathComponent("ModifiedMobileGestalt.plist", conformingTo: .data)
        resolutionURL = documentsDirectory.appendingPathComponent("Resolution.plist", conformingTo: .data)

        do {
            if !FileManager.default.fileExists(atPath: origMGURL.path) {
                // Use obfuscated path from MobileGestaltApplyTask
                let url = URL(filePath: MobileGestaltApplyTask.onDeviceMGPath)
                try FileManager.default.copyItem(at: url, to: origMGURL)
            }
            chmod(origMGURL.path, 0o644)

            if !FileManager.default.fileExists(atPath: modMGURL.path) {
                try FileManager.default.copyItem(at: origMGURL, to: modMGURL)
            }
            chmod(modMGURL.path, 0o644)

            _mobileGestalt = State(initialValue: try NSMutableDictionary(contentsOf: modMGURL, error: ()))
        } catch {
            _mobileGestalt = State(initialValue: [:])
            _initError = State(initialValue: "Failed to copy MobileGestalt: \(error)")
            taskRunning = true
        }
    }

    // MARK: - Bindings (mostly unchanged)

    func bindingForAppleIntelligence() -> Binding<Bool> {
        guard let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        let key = "A62OafQ85EJAiiqKn4agtg"
        return Binding(
            get: {
                if let value = cacheExtra[key] as? Int? { return value == 1 }
                return false
            },
            set: { enabled in
                if enabled {
                    eligibilityData = try! Data(contentsOf: Bundle.main.url(forResource: "eligibility", withExtension: "plist")!)
                    featureFlagsData = try! Data(contentsOf: Bundle.main.url(forResource: "FeatureFlags_Global", withExtension: "plist")!)
                    cacheExtra[key] = 1
                } else {
                    featureFlagsData = try! PropertyListSerialization.data(fromPropertyList: [:], format: .xml, options: 0)
                    eligibilityData = featureFlagsData
                    cacheExtra.removeObject(forKey: key)
                }
            }
        )
    }
    
    func bindingForMedusa() -> Binding<Bool> {
        guard let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        let keys = [
            "mG0AnH/Vy1veoqoLRAIgTA", // MedusaFloatingLiveAppCapability
            "UCG5MkVahJxG1YULbbd5Bg", // MedusaOverlayAppCapability
            "ZYqko/XM5zD3XBfN5RmaXA", // MedusaPinnedAppCapability
            "nVh/gwNpy7Jv1NOk00CMrw", // MedusaPIPCapability
            "qeaj75wk3HF4DwQ8qbIi7g", // DeviceSupportsEnhancedMultitasking
        ]
        return Binding(
            get: {
                if let value = cacheExtra[keys.first!] as? Int? { return value == 1 }
                return false
            },
            set: { enabled in
                for key in keys {
                    if enabled {
                        cacheExtra[key] = 1
                    } else {
                        cacheExtra.removeObject(forKey: key)
                    }
                }
            }
        )
    }

    func bindingForRegionRestriction() -> Binding<Bool> {
        guard let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        return Binding<Bool>(
            get: {
                return cacheExtra["h63QSdBCiT/z0WU6rdQv6Q"] as? String == "US" &&
                cacheExtra["zHeENZu+wbg7PUprwNwBWg"] as? String == "LL/A"
            },
            set: { enabled in
                if enabled {
                    cacheExtra["h63QSdBCiT/z0WU6rdQv6Q"] = "US"
                    cacheExtra["zHeENZu+wbg7PUprwNwBWg"] = "LL/A"
                } else {
                    cacheExtra.removeObject(forKey: "h63QSdBCiT/z0WU6rdQv6Q")
                    cacheExtra.removeObject(forKey: "zHeENZu+wbg7PUprwNwBWg")
                }
            }
        )
    }

    func bindingForInternalStuff() -> Binding<Bool> {
        guard let cacheData = mobileGestalt["CacheData"] as? NSMutableData else {
            return State(initialValue: false).projectedValue
        }
        let off_appleInternalInstall = FindCacheDataOffset("EqrsVvjcYDdxHBiQmGhAWw")
        let off_HasInternalSettingsBundle = FindCacheDataOffset("Oji6HRoPi7rH7HPdWVakuw")
        let off_InternalBuild = FindCacheDataOffset("LBJfwOEzExRxzlAnSuI7eg")

        return Binding(
            get: { cacheData.bytes.load(fromByteOffset: off_appleInternalInstall, as: Int.self) == 1 },
            set: { enabled in
                cacheData.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_appleInternalInstall, as: Int.self)
                cacheData.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_HasInternalSettingsBundle, as: Int.self)
                cacheData.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_InternalBuild, as: Int.self)
            }
        )
    }

    func bindingForTrollPad() -> Binding<Bool> {
        guard let cacheData = mobileGestalt["CacheData"] as? NSMutableData,
              let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        let valueOffset = FindCacheDataOffset("mtrAoWJ3gsq+I90ZnQ0vQw")

        let keys = [
            "uKc7FPnEO++lVhHWHFlGbQ", // ipad
            "mG0AnH/Vy1veoqoLRAIgTA", // MedusaFloatingLiveAppCapability
            "UCG5MkVahJxG1YULbbd5Bg", // MedusaOverlayAppCapability
            "ZYqko/XM5zD3XBfN5RmaXA", // MedusaPinnedAppCapability
            "nVh/gwNpy7Jv1NOk00CMrw", // MedusaPIPCapability
            "qeaj75wk3HF4DwQ8qbIi7g", // DeviceSupportsEnhancedMultitasking
        ]

        return Binding(
            get: {
                if let value = cacheExtra[keys.first!] as? Int? { return value == 1 }
                return false
            },
            set: { enabled in
                cacheData.mutableBytes.storeBytes(of: enabled ? 3 : 1, toByteOffset: valueOffset, as: Int.self)
                for key in keys {
                    if enabled {
                        cacheExtra[key] = 1
                    } else {
                        cacheExtra.removeObject(forKey: key)
                    }
                }
            }
        )
    }

    func bindingForMGKeys<T: Equatable>(_ keys: [String], type: T.Type = Int.self, defaultValue: T? = 0, enableValue: T? = 1) -> Binding<Bool> {
        guard let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        return Binding(
            get: {
                if let value = cacheExtra[keys.first!] as? T?, let enableValue { return value == enableValue }
                return false
            },
            set: { enabled in
                for key in keys {
                    if enabled {
                        cacheExtra[key] = enableValue
                    } else {
                        cacheExtra.removeObject(forKey: key)
                    }
                }
            }
        )
    }

    // MARK: - Helpers

    static func machineName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }

    func saveProductType() {
        let cacheExtra = mobileGestalt["CacheExtra"] as! NSMutableDictionary
        cacheExtra["h9jDsbgj7xIVeIQ8S3/X3Q"] = productType
    }
    
    func applyDynamicIsland(type: Int) {
        guard let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary else { return }
        
        let subtypeValues = [0, 2436, 2556, 2796, 2976, 2622, 2868, 2736]
        
        if type == 0 {
            // Remove Dynamic Island
            cacheExtra.removeObject(forKey: "oPeik/9e8lQWMszEjbPzng")
            cacheExtra.removeObject(forKey: "YlEtTtHlNesRBMal1CqRaA")
        } else if type > 0 && type < subtypeValues.count {
            // Set Dynamic Island
            let subtypeValue = subtypeValues[type]
            
            // Create or update the dictionary for the key
            var gestaltDict: NSMutableDictionary
            if let existing = cacheExtra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary {
                gestaltDict = existing
            } else {
                gestaltDict = NSMutableDictionary()
                cacheExtra["oPeik/9e8lQWMszEjbPzng"] = gestaltDict
            }
            
            gestaltDict["ArtworkDeviceSubType"] = subtypeValue
            
            // Enable Dynamic Island flag
            cacheExtra["YlEtTtHlNesRBMal1CqRaA"] = 1
        }
    }
    
    func applyModelName() {
        guard let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary else { return }
        
        // Create or update the dictionary for the key
        var gestaltDict: NSMutableDictionary
        if let existing = cacheExtra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary {
            gestaltDict = existing
        } else {
            gestaltDict = NSMutableDictionary()
            cacheExtra["oPeik/9e8lQWMszEjbPzng"] = gestaltDict
        }
        
        gestaltDict["ArtworkDeviceProductDescription"] = modelName
    }
    
    func removeModelName() {
        guard let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary else { return }
        
        if let gestaltDict = cacheExtra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary {
            gestaltDict.removeObject(forKey: "ArtworkDeviceProductDescription")
        }
    }
    
    // MARK: - RDAR Fix Functions
    
    /// Determines the RDAR fix mode based on device model
    /// Mode 1: iPhone XR, XS, 11 series
    /// Mode 2: iPhone 12+ series
    /// Mode 3: iPhone SE series
    private func getRdarMode() -> Int {
        let model = Self.machineName()
        
        // Mode 1: iPhone XR, XS, and 11 series
        let mode1Models: Set<String> = [
            "iPhone11,2", "iPhone11,4", "iPhone11,6", "iPhone11,8",
            "iPhone12,1", "iPhone12,3", "iPhone12,5"
        ]
        if mode1Models.contains(model) {
            return 1
        }
        
        // Mode 2: iPhone 12, 13, 14, 15, 16, 17 series
        let mode2Models: Set<String> = [
            "iPhone13,2", "iPhone13,3", "iPhone13,4",
            "iPhone14,5", "iPhone14,2", "iPhone14,3",
            "iPhone14,7", "iPhone14,8", "iPhone17,5"
        ]
        if mode2Models.contains(model) {
            return 2
        }
        
        // Mode 3: iPhone SE series
        let mode3Models: Set<String> = ["iPhone12,8", "iPhone14,6"]
        if mode3Models.contains(model) {
            return 3
        }
        
        return 0
    }
    
    /// Calculates the resolution based on dynamic island type and device mode
    private func calculateResolution() -> (width: Int, height: Int)? {
        let mode = getRdarMode()
        
        if dynamicIslandType == 0 || !enableRdarFix {
            // No fix needed
            return nil
        }
        
        if mode == 1 {
            // iPhone XR, XS, and 11 - Fixed resolution for older devices
            return (828, 1791)
        } else if mode == 3 {
            // iPhone SEs - Fixed resolution for SE models
            return (1000, 1779)
        } else if mode == 2 {
            // Status bar fix for iPhone 12+ (requires dynamic island type)
            // Subtype values correspond to screen heights: 0=None, 2436, 2556, 2796, 2976, 2622, 2868, 2736
            let subtypeValues = [0, 2436, 2556, 2796, 2976, 2622, 2868, 2736]
            guard dynamicIslandType > 0 && dynamicIslandType < subtypeValues.count else {
                return nil
            }
            
            let subtypeValue = subtypeValues[dynamicIslandType]
            
            // Calculate width and height based on the selected dynamic island subtype
            switch subtypeValue {
            case 2556: // iPhone 14 Pro / 15 Pro
                return (1179, 2556)
            case 2796: // iPhone 14 Pro Max / 15 Pro Max
                return (1290, 2796)
            case 2622: // iPhone 16 Pro
                return (1206, 2622)
            case 2868: // iPhone 16 Pro Max
                return (1320, 2868)
            case 2736: // iPhone 17 Pro Max
                return (1260, 2736)
            default:
                // Default to iPhone 16 Pro Max dimensions if unknown
                return (1320, 2868)
            }
        }
        
        return nil
    }
    
    /// Saves the resolution plist file for RDAR fix
    func saveResolutionPlist() throws {
        if let resolution = calculateResolution() {
            // Create the resolution plist with canvas_width and canvas_height
            let resolutionDict: NSDictionary = [
                "canvas_width": resolution.width,
                "canvas_height": resolution.height
            ]
            
            try resolutionDict.write(to: resolutionURL)
            chmod(resolutionURL.path, 0o644)
        } else {
            // Remove resolution plist if RDAR fix is disabled or not needed
            if FileManager.default.fileExists(atPath: resolutionURL.path) {
                try? FileManager.default.removeItem(at: resolutionURL)
            }
        }
    }
    
    /// Loads the RDAR fix state from existing resolution plist
    private func loadRdarFixState() {
        if FileManager.default.fileExists(atPath: resolutionURL.path),
           let resolutionDict = NSDictionary(contentsOf: resolutionURL),
           resolutionDict["canvas_width"] != nil && resolutionDict["canvas_height"] != nil {
            // Resolution plist exists with valid data, enable RDAR fix
            enableRdarFix = true
        } else {
            enableRdarFix = false
        }
    }
}
