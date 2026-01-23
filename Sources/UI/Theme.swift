import SwiftUI
import UIKit

// MARK: - Color Extension

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - App Theme

struct AppTheme {
    static let bg = Color(hex: 0x151515)
    static let row = Color(hex: 0x212121)
    static let textSecondary = Color.white.opacity(0.72)
    static let accent = Color(hex: 0x9FE7FF)
}

// MARK: - Gradient Button (Wallet Style)

struct WalletStyleButton: View {
    let title: String
    var isLoading: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    private let grad = LinearGradient(
        colors: [Color(hex: 0xAEEBFF), Color(hex: 0xE6B2FF), Color(hex: 0xFFE08A)],
        startPoint: .leading, endPoint: .trailing
    )

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.86))
                
                if isLoading {
                    HStack { Spacer(); ProgressView().tint(.black.opacity(0.75)) }
                        .padding(.trailing, 18)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(grad)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
        )
        .opacity(disabled ? 0.55 : 1.0)
        .saturation(disabled ? 0.0 : 1.0)
        .disabled(disabled)
    }
}

// MARK: - Secondary Button (Outline)

struct SecondaryActionButton: View {
    let title: String
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.88))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
        .opacity(disabled ? 0.35 : 1.0)
        .disabled(disabled)
    }
}

// MARK: - App Title Header

struct AppTitleHeader: View {
    private let title = "EnsWilde"
    private let subtitle = "itunesstored & bookassetd sbx escape"
    
    private let grad = LinearGradient(
        colors: [Color(hex: 0xAEEBFF), Color(hex: 0xE6B2FF), Color(hex: 0xFFE08A)],
        startPoint: .leading, endPoint: .trailing
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .overlay(grad)
                .mask(Text(title).font(.system(size: 40, weight: .heavy, design: .rounded)))
                .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 6)

            Text(subtitle)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }
}

// MARK: - Section Header

struct AppSectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.86))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }
}

// MARK: - Card Row

struct CardRow: View {
    let title: String
    let subtitle: String?
    let ok: Bool?
    let showChevron: Bool
    let trailing: AnyView?

    var body: some View {
        HStack(spacing: 12) {
            // Icon status
            if let ok {
                Image(systemName: ok ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ok ? .green : Color.white.opacity(0.55))
            } else {
                Image(systemName: "circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.20))
                    .padding(.horizontal, 4)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(.white)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .foregroundStyle(AppTheme.textSecondary)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .lineLimit(2)
                }
            }

            Spacer()

            if let trailing { trailing }

            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.white.opacity(0.55))
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .padding(18)
        .background(AppTheme.row)
        .cornerRadius(16)
    }
}

// MARK: - Custom Corner Radius

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
