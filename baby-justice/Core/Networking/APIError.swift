import Foundation

struct ApiErrorBody: Codable {
    let path: String
    let message: String
    let statusCode: Int
    let timestamp: Date
}

enum APIError: LocalizedError {
    case server(message: String, status: Int)
    case network
    case decoding
    case unauthorized
    case invalidPassword

    var errorDescription: String? {
        switch self {
        case .server(let message, _):
            message
        case .network:
            "Nie udało się połączyć z serwerem. Sprawdź połączenie z internetem i spróbuj ponownie."
        case .decoding:
            "Nie udało się odczytać odpowiedzi serwera. Spróbuj ponownie później."
        case .unauthorized:
            "Twoja sesja wygasła. Zaloguj się ponownie."
        case .invalidPassword:
            "Nieprawidłowe hasło."
        }
    }
}
