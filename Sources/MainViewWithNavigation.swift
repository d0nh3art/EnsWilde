import SwiftUI

// MARK: - Main View with Navigation
struct MainViewWithNavigation: View {
    @State private var selectedTab: NavigationTab = .home
    @StateObject private var themeStore = PasscodeThemeStore()
    @State private var showApplySheet = false
    @State private var showStatusSheet = false
    @State private var isInNestedView = false
    @State private var isSystemReady = false
    
    // Animation Config (same as ContentView)
    private let panelAnimation: Animation = .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)
    private let navBarAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.85, blendDuration: 0)
    
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
            // Content Area - Each view manages its own navigation
            Group {
                if selectedTab == .home {
                    ContentView(
                        showApplySheetBinding: $showApplySheet,
                        showStatusSheetBinding: $showStatusSheet,
                        hideBottomApplyButton: true,
                        isInNestedViewBinding: $isInNestedView,
                        isSystemReadyBinding: $isSystemReady
                    )
                } else {
                    ThemeStoreView(themeStore: themeStore)
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
            
            // Dynamic Island Navigation Bar - Fixed at bottom using ZStack overlay
            // Hide when in nested view OR when Apply panel OR Status panel is open
            VStack {
                Spacer()
                
                if !isInNestedView && !showApplySheet && !showStatusSheet {
                    DynamicIslandNavigationBar(
                        selectedTab: $selectedTab,
                        showApplyButton: selectedTab == .home,
                        isApplyEnabled: isSystemReady,
                        onApplyTapped: {
                            withAnimation(panelAnimation) {
                                showApplySheet = true
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(navBarAnimation, value: isInNestedView)
            .animation(navBarAnimation, value: showApplySheet)
            .animation(navBarAnimation, value: showStatusSheet)
        }
    }
}
