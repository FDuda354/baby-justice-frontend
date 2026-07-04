import SwiftUI

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1.0
        )
    }

    static func adaptive(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }

    static let bjPrimary = Color(hex: 0x2FA96C)
    static let bjPrimaryDark = Color(hex: 0x1D7A4C)
    static let bjMint = Color(uiColor: .adaptive(light: 0xE6F4EC, dark: 0x16301F))
    static let bjAccent = Color(uiColor: .adaptive(light: 0x1D7A4C, dark: 0x7FD8A8))
    static let bjAmber = Color(hex: 0xF5A623)
    static let bjDanger = Color(hex: 0xD64545)
    static let bjInk = Color(uiColor: .adaptive(light: 0x17251D, dark: 0xE9F4EE))
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
