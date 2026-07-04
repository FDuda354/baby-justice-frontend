import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }

    static let bjPrimary = Color(hex: 0x2FA96C)
    static let bjPrimaryDark = Color(hex: 0x1D7A4C)
    static let bjMint = Color(hex: 0xE6F4EC)
    static let bjAmber = Color(hex: 0xF5A623)
    static let bjDanger = Color(hex: 0xD64545)
    static let bjInk = Color(hex: 0x17251D)
}

enum BJRadius {
    static let card: CGFloat = 16
    static let button: CGFloat = 14
    static let field: CGFloat = 12
    static let small: CGFloat = 8
}

enum BJSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum BJSize {
    static let buttonHeight: CGFloat = 50
    static let fieldHeight: CGFloat = 48
}
