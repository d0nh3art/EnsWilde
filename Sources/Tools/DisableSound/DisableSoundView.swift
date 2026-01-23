import SwiftUI

struct DisableSoundView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @AppStorage("DisableDisclosureSoundEnabled") private var enabled: Bool = false

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    AppSectionHeader(title: L("tool_disable_sound"))
                    
                    CardRow(
                        title: L("enable_tweak"),
                        subtitle: enabled ? L("enabled") : L("disabled"),
                        ok: nil,
                        showChevron: false,
                        trailing: AnyView(Toggle("", isOn: $enabled).labelsHidden())
                    )
                    .padding(.horizontal, 20)
                    
                    Text(L("msg_tool_enable_instruction_2"))
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .navigationTitle(L("tool_disable_sound"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
