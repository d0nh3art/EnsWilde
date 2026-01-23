import SwiftUI

// MARK: - Navigation Tab
enum NavigationTab: String, CaseIterable {
    case home = "nav_home"
    case themeStore = "nav_theme_store"
    
    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .themeStore:
            return "square.grid.2x2.fill"
        }
    }
    
    var localizedTitle: String {
        return L(self.rawValue)
    }
}

// MARK: - Dynamic Island Navigation Bar
struct DynamicIslandNavigationBar: View {
    @Binding var selectedTab: NavigationTab
    var showApplyButton: Bool
    var isApplyEnabled: Bool = true
    var onApplyTapped: () -> Void
    
    // Use LocalizationManager directly without observing to prevent crashes
    private var localizationManager: LocalizationManager { LocalizationManager.shared }
    
    var body: some View {
        HStack(spacing: 12) {
            navigationPills
            Spacer()
            
            if showApplyButton {
                applyButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showApplyButton)
    }
    
    // MARK: - Navigation Pills
    private var navigationPills: some View {
        HStack(spacing: 0) {
            ForEach(NavigationTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(4)
        .background(navigationPillsBackground)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private var navigationPillsBackground: some View {
        Capsule()
            .fill(Color.black.opacity(0.85))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    // MARK: - Tab Button
    private func tabButton(for tab: NavigationTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            tabButtonLabel(for: tab)
        }
    }
    
    private func tabButtonLabel(for tab: NavigationTab) -> some View {
        HStack(spacing: 6) {
            Image(systemName: tab.icon)
                .font(.system(size: 16, weight: .semibold))
            
            if selectedTab == tab {
                Text(tab.localizedTitle)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .foregroundStyle(selectedTab == tab ? .white : Color.white.opacity(0.5))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(tabButtonBackground(for: tab))
    }
    
    private func tabButtonBackground(for tab: NavigationTab) -> some View {
        Capsule()
            .fill(selectedTab == tab ? Color.white.opacity(0.15) : Color.clear)
    }
    
    // MARK: - Apply Button
    private var applyButton: some View {
        Button {
            onApplyTapped()
        } label: {
            applyButtonLabel
        }
        .disabled(!isApplyEnabled)
        .opacity(isApplyEnabled ? 1.0 : 0.55)
        .saturation(isApplyEnabled ? 1.0 : 0.0)
        .transition(.scale.combined(with: .opacity))
    }
    
    private var applyButtonLabel: some View {
        Text(L("nav_apply"))
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(Color.black.opacity(0.86))
            .frame(width: 90)
            .padding(.vertical, 12)
            .background(applyButtonBackground)
    }
    
    private var applyButtonBackground: some View {
        let grad = LinearGradient(
            colors: [Color(hex: 0xAEEBFF), Color(hex: 0xE6B2FF), Color(hex: 0xFFE08A)],
            startPoint: .leading, endPoint: .trailing
        )
        
        return Capsule()
            .fill(grad)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        DynamicIslandNavigationBar(
            selectedTab: .constant(.home),
            showApplyButton: true,
            onApplyTapped: {}
        )
        
        DynamicIslandNavigationBar(
            selectedTab: .constant(.themeStore),
            showApplyButton: false,
            onApplyTapped: {}
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppTheme.bg)
}
