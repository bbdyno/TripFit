import Domain
import Foundation

@MainActor
public final class DisabledAuthService: AuthService {
    public private(set) var session: AuthSession?

    private let reason: String

    public init(reason: String) {
        self.reason = reason
    }

    public func restoreSession() async -> AuthSession? { nil }

    public func signIn(with credential: AppleIdentityCredential) async throws -> AuthSession {
        throw AuthServiceError.unavailable(reason)
    }

    public func validateAppleCredential() async {}

    public func signOut() throws {
        session = nil
    }
}
