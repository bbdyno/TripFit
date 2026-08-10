import Foundation

public struct AppUser: Equatable, Sendable {
    public let id: String
    public let appleSubject: String?
    public let displayName: String?

    public init(id: String, appleSubject: String?, displayName: String?) {
        self.id = id
        self.appleSubject = appleSubject
        self.displayName = displayName
    }
}

public struct AuthSession: Equatable, Sendable {
    public let user: AppUser
    public let authenticatedAt: Date

    public init(user: AppUser, authenticatedAt: Date) {
        self.user = user
        self.authenticatedAt = authenticatedAt
    }
}

public struct AppleIdentityCredential: Equatable, Sendable {
    public let identityToken: String
    public let rawNonce: String
    public let givenName: String?
    public let familyName: String?

    public init(
        identityToken: String,
        rawNonce: String,
        givenName: String?,
        familyName: String?
    ) {
        self.identityToken = identityToken
        self.rawNonce = rawNonce
        self.givenName = givenName
        self.familyName = familyName
    }
}

public enum AuthServiceError: Error, Equatable, Sendable {
    case unavailable(String)
    case cancelled
    case missingIdentityToken
    case invalidCredential
    case networkFailure
    case requiresRecentLogin
    case underlying(String)
}

extension AuthServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .unavailable(reason): reason
        case .cancelled: "Sign in was cancelled."
        case .missingIdentityToken: "Apple did not return an identity token."
        case .invalidCredential: "The Apple credential is no longer valid."
        case .networkFailure: "Check your network connection and try again."
        case .requiresRecentLogin: "Please sign in with Apple again to continue."
        case let .underlying(message): message
        }
    }
}

@MainActor
public protocol AuthService: AnyObject {
    var session: AuthSession? { get }

    @discardableResult
    func restoreSession() async -> AuthSession?

    @discardableResult
    func signIn(with credential: AppleIdentityCredential) async throws -> AuthSession

    func validateAppleCredential() async
    func signOut() throws
}
