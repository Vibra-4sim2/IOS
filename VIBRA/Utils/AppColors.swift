import SwiftUI

struct AppColors {
    // Arrière-plan général (dégradé vert sombre)
    static let BackgroundDark = Color(hex: "#050D0A")
    static let BackgroundGradientStart = Color(hex: "#0C2317")
    static let BackgroundGradientEnd = Color(hex: "#02100B")

    // Cartes et overlays (effet glass)
    static let CardDark = Color(hex: "#112820")
    static let CardGlass = Color.white.opacity(0.2)   // blanc translucide
    static let CardOverlay = Color.black.opacity(0.4)

    // Verts principaux
    static let GreenAccent = Color(hex: "#7FDB8A")     // vert clair pour CTA
    static let GreenLight = Color(hex: "#A6F2B0")
    static let GreenDark = Color(hex: "#3C8B52")

    // Teal / autres accents
    static let TealAccent = Color(hex: "#5DDBC4")
    static let AmberAccent = Color(hex: "#FFD17A")

    // Textes
    static let TextPrimary = Color.white
    static let TextSecondary = Color(hex: "#C7D8C7")
    static let TextTertiary = Color(hex: "#7A8F7A")

    // États
    static let SuccessGreen = Color(hex: "#4ADE80")
    static let ErrorRed = Color(hex: "#EF4444")
    static let WarningOrange = Color(hex: "#F59E0B")
    static let InfoBlue = Color(hex: "#3B82F6")

    // Divers
    static let BorderColor = Color.white.opacity(0.2)
    static let DividerColor = Color.white.opacity(0.1)
    static let ShadowColor = Color.black.opacity(0.5)

    static let GlowGreen = Color(hex: "#997FDB8A")
    static let ShimmerLight = Color.white.opacity(0.2)
}

extension Color {
    init(hex: String) {
        var hex = hex.replacingOccurrences(of: "#", with: "")
        if hex.count == 6 { hex += "FF" }

        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)

        let r = Double((value >> 24) & 0xFF) / 255
        let g = Double((value >> 16) & 0xFF) / 255
        let b = Double((value >> 8) & 0xFF) / 255
        let a = Double((value >> 0) & 0xFF) / 255

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
