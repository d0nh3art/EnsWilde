import SwiftUI
import PhotosUI

// MARK: - Apple Wallet View
struct AppleWalletView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject var walletStore: AppleWalletStore
    @State private var showAddSheet = false
    @State private var showScanSheet = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isScanning = false
    
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    AppSectionHeader(title: L("wallet_title"))
                    
                    // Enable Toggle
                    CardRow(
                        title: L("wallet_enable"),
                        subtitle: walletStore.appleWalletEnabled ? L("enabled") : L("disabled"),
                        ok: nil,
                        showChevron: false,
                        trailing: AnyView(Toggle("", isOn: $walletStore.appleWalletEnabled).labelsHidden())
                    )
                    .padding(.horizontal, 20)
                    
                    Text(L("msg_tool_enable_instruction"))
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Cards Section
                    AppSectionHeader(title: L("section_wallet_cards"))
                    
                    if walletStore.cards.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.white.opacity(0.3))
                            Text(L("wallet_no_cards"))
                                .font(.system(size: 16, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Card Stack (Apple Wallet style)
                        VStack(spacing: 12) {
                            ForEach(Array(walletStore.cards.enumerated()), id: \.element.id) { index, card in
                                NavigationLink(destination: AppleWalletCardDetailView(card: card, walletStore: walletStore)) {
                                    WalletCardPreview(card: card, index: index, total: walletStore.cards.count, walletStore: walletStore)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Add Card Buttons
                    AppSectionHeader(title: L("section_add_card"))
                    
                    VStack(spacing: 12) {
                        WalletStyleButton(title: L("wallet_scan_card")) {
                            showScanSheet = true
                        }
                        
                        SecondaryActionButton(title: L("wallet_manual_input")) {
                            showAddSheet = true
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Text(L("wallet_scan_manual_desc"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 20)
                }
                .padding(.top, 6)
            }
        }
        .navigationTitle(L("wallet_title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSheet) {
            ManualAddCardSheet(walletStore: walletStore)
        }
        .sheet(isPresented: $showScanSheet) {
            ScanCardIDSheet(walletStore: walletStore, isPresented: $showScanSheet)
        }
        .alert(L("alert_error"), isPresented: $showErrorAlert) {
            Button(L("alert_ok")) {}
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Wallet Card Preview
struct WalletCardPreview: View {
    let card: AppleWalletCard
    let index: Int
    let total: Int
    @ObservedObject var walletStore: AppleWalletStore
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        ZStack {
            if let imageData = card.backgroundImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1.586, contentMode: .fill)
                    .frame(height: 200)
                    .cornerRadius(16)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x667eea), Color(hex: 0x764ba2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
            }
            
            VStack {
                HStack {
                    Spacer()
                    if card.enabled {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.green)
                    }
                }
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(card.id.prefix(16) + "...")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                }
            }
            .padding(16)
        }
        .frame(height: 200)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .offset(y: CGFloat(index) * -8)
        .contextMenu {
            Button {
                showEditSheet = true
            } label: {
                Label(L("alert_edit"), systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label(L("alert_delete"), systemImage: "trash")
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditCardSheet(card: card, walletStore: walletStore)
        }
        .alert(L("alert_delete_card"), isPresented: $showDeleteAlert) {
            Button(L("alert_cancel"), role: .cancel) {}
            Button(L("alert_delete"), role: .destructive) {
                walletStore.deleteCard(card)
            }
        } message: {
            Text(L("alert_delete_card_confirm").replacingOccurrences(of: "{cardName}", with: "\(card.name)?"))
        }
    }
}

// MARK: - Manual Add Card Sheet
struct ManualAddCardSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var walletStore: AppleWalletStore
    @State private var cardID = ""
    @State private var cardName = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                
                Form {
                    Section(header: Text(L("section_card_information"))) {
                        TextField(L("wallet_card_id"), text: $cardID)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        TextField(L("wallet_card_name"), text: $cardName)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(L("wallet_add_manually"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("alert_cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("alert_add")) {
                        let card = AppleWalletCard(id: cardID.trimmingCharacters(in: .whitespacesAndNewlines),
                                                   name: cardName.isEmpty ? "Card \(cardID.prefix(8))" : cardName)
                        walletStore.addCard(card)
                        dismiss()
                    }
                    .disabled(cardID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Scan Card ID Sheet
struct ScanCardIDSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var walletStore: AppleWalletStore
    @Binding var isPresented: Bool
    @State private var isScanning = false
    @State private var scanStatus = L("wallet_scan_ready")
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Scanning Animation
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 8)
                            .frame(width: 150, height: 150)
                        
                        if isScanning {
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(hex: 0xAEEBFF), Color(hex: 0xE6B2FF)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(isScanning ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isScanning)
                        }
                        
                        Image(systemName: isScanning ? "wave.3.right.circle.fill" : "creditcard.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(isScanning ? Color(hex: 0xAEEBFF) : .white.opacity(0.6))
                    }
                    
                    VStack(spacing: 12) {
                        Text(scanStatus)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        
                        if isScanning {
                            Text(String(format: "%.0f / 300 seconds", elapsedTime))
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    if isScanning {
                        Text(L("wallet_scan_instruction"))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    if isScanning {
                        SecondaryActionButton(title: "Cancel Scan") {
                            stopScanning()
                            dismiss()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    } else {
                        WalletStyleButton(title: "Start Scanning") {
                            startScanning()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(L("wallet_scan_card"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        stopScanning()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startScanning() {
        isScanning = true
        elapsedTime = 0
        scanStatus = "Scanning... Open Apple Wallet now"
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
        
        Task {
            do {
                let cardID = try await scanOneWalletCardID(timeout: 300) // 5 minutes
                await MainActor.run {
                    stopScanning()
                    let newCard = AppleWalletCard(id: cardID, name: "Card \(cardID.prefix(8))")
                    walletStore.addCard(newCard)
                    scanStatus = "✓ Successfully scanned card ID!"
                    
                    // Auto dismiss after 1.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    stopScanning()
                    scanStatus = "✗ Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func stopScanning() {
        isScanning = false
        timer?.invalidate()
        timer = nil
        JITEnableContext.shared.stopSyslogRelay()
    }
}

// MARK: - Edit Card Sheet
struct EditCardSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var card: AppleWalletCard
    @ObservedObject var walletStore: AppleWalletStore
    @State private var cardName: String
    
    init(card: AppleWalletCard, walletStore: AppleWalletStore) {
        self._card = State(initialValue: card)
        self.walletStore = walletStore
        self._cardName = State(initialValue: card.name)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                
                Form {
                    Section(header: Text(L("section_card_information"))) {
                        // Card ID is read-only
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Card ID (Read-only)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(card.id)
                                .font(.system(.body, design: .monospaced))
                        }
                        TextField(L("wallet_card_name"), text: $cardName)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("alert_cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updatedCard = card
                        updatedCard.name = cardName.isEmpty ? "Card \(card.id.prefix(8))" : cardName
                        walletStore.updateCard(updatedCard)
                        dismiss()
                    }
                    .disabled(cardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Card Detail View
struct AppleWalletCardDetailView: View {
    @State var card: AppleWalletCard
    @ObservedObject var walletStore: AppleWalletStore
    @State private var showImagePicker = false
    @State private var selectedImageType: ImageType = .background
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) var dismiss
    
    enum ImageType {
        case background
    }
    
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Card Preview
                    AppSectionHeader(title: "Card Preview")
                    
                    if let imageData = card.backgroundImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(1.586, contentMode: .fit)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 20)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0x667eea), Color(hex: 0x764ba2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .aspectRatio(1.586, contentMode: .fit)
                            .overlay(
                                Text("No Image")
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                            )
                            .padding(.horizontal, 20)
                    }
                    
                    // Card Info
                    AppSectionHeader(title: L("section_card_information"))
                    
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("wallet_card_name"))
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                TextField(L("wallet_card_name"), text: $card.name)
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white)
                                    .onChange(of: card.name) { _ in walletStore.updateCard(card) }
                            }
                            Spacer()
                        }
                        .padding(18)
                        .background(AppTheme.row)
                        .cornerRadius(16)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("wallet_card_id"))
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text(card.id)
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                        }
                        .padding(18)
                        .background(AppTheme.row)
                        .cornerRadius(16)
                        
                        CardRow(
                            title: "Enable Card",
                            subtitle: card.enabled ? "This card will be applied" : "This card will not be applied",
                            ok: nil,
                            showChevron: false,
                            trailing: AnyView(Toggle("", isOn: $card.enabled)
                                .labelsHidden()
                                .onChange(of: card.enabled) { _ in walletStore.updateCard(card) })
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Image Resolution
                    AppSectionHeader(title: "Image Resolution")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select image resolution for card background")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        Picker("Resolution", selection: $card.useRetina) {
                            Text("@2x (Standard)").tag(false)
                            Text("@3x (Retina)").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: card.useRetina) { _ in walletStore.updateCard(card) }
                    }
                    .padding(18)
                    .background(AppTheme.row)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // Images
                    AppSectionHeader(title: "Card Images")
                    
                    VStack(spacing: 12) {
                        ImagePickerButton(
                            title: "Background Image",
                            subtitle: card.useRetina ? "cardBackgroundCombined@3x.png" : "cardBackgroundCombined@2x.png",
                            hasImage: card.backgroundImageData != nil
                        ) {
                            selectedImageType = .background
                            showImagePicker = true
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Text("FrontFace, PlaceHolder, and Preview files are automatically loaded from Resources.")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Delete
                    AppSectionHeader(title: "Danger Zone")
                    
                    SecondaryActionButton(title: L("alert_delete_card")) {
                        showDeleteAlert = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 6)
            }
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(imageData: bindingForImageType(selectedImageType), useRetina: card.useRetina)
        }
        .alert(L("alert_delete_card"), isPresented: $showDeleteAlert) {
            Button(L("alert_cancel"), role: .cancel) {}
            Button(L("alert_delete"), role: .destructive) {
                walletStore.deleteCard(card)
                dismiss()
            }
        } message: {
            Text(L("alert_delete_card_confirm").replacingOccurrences(of: "{cardName}", with: "\(card.name)?"))
        }
    }
    
    private func bindingForImageType(_ type: ImageType) -> Binding<Data?> {
        Binding(
            get: {
                switch type {
                case .background: return card.backgroundImageData
                }
            },
            set: { newValue in
                switch type {
                case .background: card.backgroundImageData = newValue
                }
                walletStore.updateCard(card)
            }
        )
    }
}

// MARK: - Image Picker Button
struct ImagePickerButton: View {
    let title: String
    let subtitle: String
    let hasImage: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                if hasImage {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 20))
                }
                Image(systemName: "photo")
                    .foregroundStyle(Color.white.opacity(0.6))
                    .font(.system(size: 20))
            }
            .padding(18)
            .background(AppTheme.row)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) var dismiss
    let useRetina: Bool  // true = @3x, false = @2x
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, useRetina: useRetina)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        let useRetina: Bool
        
        init(_ parent: ImagePicker, useRetina: Bool) {
            self.parent = parent
            self.useRetina = useRetina
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, error in
                guard let image = image as? UIImage else { return }
                
                // Resize to Apple Wallet dimensions based on resolution
                // Apple Wallet card background sizes:
                // @3x (Retina): 2304x1452
                // @2x (Standard): 1536x969 (user-specified default)
                let targetSize: CGSize
                if self.useRetina {
                    targetSize = CGSize(width: 2304, height: 1452)
                } else {
                    targetSize = CGSize(width: 1536, height: 969)
                }
                
                let resizedImage = self.resizeImage(image, targetSize: targetSize)
                
                DispatchQueue.main.async {
                    self.parent.imageData = resizedImage.pngData()
                }
            }
        }
        
        private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
            let size = image.size
            let widthRatio = targetSize.width / size.width
            let heightRatio = targetSize.height / size.height
            let ratio = min(widthRatio, heightRatio)
            let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
            
            let renderer = UIGraphicsImageRenderer(size: newSize)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }
    }
}

// MARK: - Wallet Card ID Scanner
private enum WalletIDScanError: Error, LocalizedError {
    case timedOut
    case unknownError

    var errorDescription: String? {
        switch self {
        case .timedOut:
            return "Hết thời gian chờ (Timeout). Vui lòng thêm thẻ vào Wallet và thử lại."
        case .unknownError:
            return "Lỗi không xác định khi quét ID thẻ."
        }
    }
}

// MARK: - 2. Hàm trích xuất ID từ dòng log (Regex Logic)

private func extractWalletCardID(from line: String) -> String? {
    // Danh sách các mẫu Regex để bắt ID thẻ trong các trường hợp khác nhau của iOS
    let patterns = [
        // Mẫu 1: Khi PDCardFileManager ghi dữ liệu thẻ
        #"PDCardFileManager: writing card\s+([A-Za-z0-9+/]+={0,2})(?=\s|\)|,|$)"#,
        // Mẫu 2: Khi PDPassLibrary ghi nhận pass mới
        #"PDPassLibrary: wrote pass\s+([A-Za-z0-9+/]+={0,2})(?=\s|\)|,|$)"#,
        // Mẫu 3: Khi hệ thống thực hiện VerificationCheck
        #"VerificationCheck\.([A-Za-z0-9+/]+={0,2})(?=\s|\)|,|$)"#
    ]

    for pattern in patterns {
        // Tạo đối tượng Regex an toàn
        guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
        
        let nsRange = NSRange(line.startIndex..., in: line)
        
        // Tìm match đầu tiên trong dòng log
        if let match = regex.firstMatch(in: line, options: [], range: nsRange) {
            // Lấy nhóm capture thứ 1 (ID thẻ)
            if let range = Range(match.range(at: 1), in: line) {
                return String(line[range])
            }
        }
    }
    return nil
}

func scanOneWalletCardID(timeout: TimeInterval = 300) async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
        var finished = false
        
        JITEnableContext.shared.startSyslogRelay { line in
            guard !finished else { return }
            guard let line else { return }
            
            // Filter for passd logs only
            guard line.localizedCaseInsensitiveContains("passd") else { return }
            
            if let cardID = extractWalletCardID(from: line) {
                finished = true
                JITEnableContext.shared.stopSyslogRelay()
                continuation.resume(returning: cardID)
            }
        } onError: { error in
            guard !finished else { return }
            finished = true
            JITEnableContext.shared.stopSyslogRelay()
            continuation.resume(throwing: error ?? WalletIDScanError.unknownError)
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            guard !finished else { return }
            finished = true
            JITEnableContext.shared.stopSyslogRelay()
            continuation.resume(throwing: WalletIDScanError.timedOut)
        }
    }
}
