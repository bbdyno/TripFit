import AuthenticationServices
import Domain
import FirebaseAuth
import Foundation

@MainActor
public final class FirebaseAuthService: AuthService {
    public private(set) var session: AuthSession?

    private let auth: Auth

    public init(auth: Auth = .auth()) {
        self.auth = auth
        self.session = auth.currentUser.map(Self.makeSession)
    }

    public func restoreSession() async -> AuthSession? {
        session = auth.currentUser.map(Self.makeSession)
        await validateAppleCredential()
        return session
    }

    public func signIn(with credential: AppleIdentityCredential) async throws -> AuthSession {
        var fullName = PersonNameComponents()
        fullName.givenName = credential.givenName
        fullName.familyName = credential.familyName
        let hasName = credential.givenName != nil || credential.familyName != nil

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: credential.identityToken,
            rawNonce: credential.rawNonce,
            fullName: hasName ? fullName : nil
        )

        do {
            let result = try await auth.signIn(with: firebaseCredential)
            if result.user.displayName == nil, hasName {
                let formatter = PersonNameComponentsFormatter()
                let displayName = formatter.string(from: fullName).trimmingCharacters(in: .whitespaces)
                if displayName.isEmpty == false {
                    let request = result.user.createProfileChangeRequest()
                    request.displayName = displayName
                    try await request.commitChanges()
                }
            }
            let restored = Self.makeSession(from: result.user)
            session = restored
            return restored
        } catch {
            throw Self.map(error)
        }
    }

    public func validateAppleCredential() async {
        guard let current = auth.currentUser,
              let appleSubject = current.providerData.first(where: { $0.providerID == "apple.com" })?.uid else {
            return
        }

        let state = await credentialState(for: appleSubject)
        switch state {
        case .revoked, .notFound:
            try? auth.signOut()
            session = nil
        case .authorized, .transferred:
            session = Self.makeSession(from: current)
        @unknown default:
            break
        }
    }

    public func signOut() throws {
        do {
            try auth.signOut()
            session = nil
        } catch {
            throw Self.map(error)
        }
    }

    private func credentialState(for userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, _ in
                continuation.resume(returning: state)
            }
        }
    }

    private static func makeSession(from user: User) -> AuthSession {
        AuthSession(
            user: AppUser(
                id: user.uid,
                appleSubject: user.providerData.first(where: { $0.providerID == "apple.com" })?.uid,
                displayName: user.displayName
            ),
            authenticatedAt: user.metadata.lastSignInDate ?? Date()
        )
    }

    private static func map(_ error: Error) -> AuthServiceError {
        let nsError = error as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return .underlying(nsError.localizedDescription)
        }
        switch code {
        case .networkError:
            return .networkFailure
        case .invalidCredential, .credentialAlreadyInUse:
            return .invalidCredential
        case .requiresRecentLogin:
            return .requiresRecentLogin
        default:
            return .underlying(nsError.localizedDescription)
        }
    }
}
