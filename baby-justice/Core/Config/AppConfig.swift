import Foundation

enum AppConfig {
#if DEBUG
    static let baseURL = URL(string: "http://localhost:8080")!
#else
    static let baseURL = URL(string: "https://baby-justice.dudios.pl")!
#endif
}
