import Foundation

enum AppConfig {
#if targetEnvironment(simulator)
    static let baseURL = URL(string: "http://localhost:8080")!
#else
    static let baseURL = URL(string: "https://baby-justice.dudios.pl")!
#endif
}
