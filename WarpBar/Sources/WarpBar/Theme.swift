import SwiftUI

enum WarpTheme {
    // Official Cloudflare Orange Palette
    static let orange = Color(red: 246/255, green: 130/255, blue: 31/255) // #F6821F
    static let orangeLight = Color(red: 251/255, green: 173/255, blue: 65/255) // #FBAD41
    static let orangeDim = Color(red: 246/255, green: 130/255, blue: 31/255).opacity(0.16)
    static let orangeGlow = Color(red: 246/255, green: 130/255, blue: 31/255).opacity(0.3)

    // Status Colors
    static let green = Color(red: 46/255, green: 204/255, blue: 113/255)
    static let greenDim = Color(red: 46/255, green: 204/255, blue: 113/255).opacity(0.18)

    // Sleek Card Backgrounds
    static let cardBackground = Color(NSColor.controlBackgroundColor).opacity(0.45)
    static let cardSelected = Color(red: 246/255, green: 130/255, blue: 31/255).opacity(0.14)
    static let cardBorder = Color.white.opacity(0.08)
    static let cardSelectedBorder = Color(red: 246/255, green: 130/255, blue: 31/255).opacity(0.4)
}

