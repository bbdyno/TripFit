import AuthenticationServices
import CryptoKit
import Domain
import Foundation
import Security
import UIKit

@MainActor
public final class AppleSignInCoordinator: NSObject {
    private weak var presentingViewController: UIViewController?
    private var continuation: CheckedContinuation<AuthSession, Error>?
    private var rawNonce: String?
    private var authService: (any AuthService)?

    public func signIn(
        using authService: any AuthService,
        presenting viewController: UIViewController
    ) async throws -> AuthSession {
        guard continuation == nil else {
            throw AuthServiceError.underlying("A Sign in with Apple request is already in progress.")
        }

        self.authService = authService
        presentingViewController = viewController
        let nonce = try Self.makeNonce()
        rawNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName]
        request.nonce = Self.sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    private func finish(_ result: Result<AuthSession, Error>) {
        let continuation = continuation
        self.continuation = nil
        rawNonce = nil
        authService = nil
        presentingViewController = nil
        continuation?.resume(with: result)
    }

    private static func makeNonce(length: Int = 32) throws -> String {
        precondition(length > 0)
        let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw AuthServiceError.underlying("Secure nonce generation failed.")
        }
        return String(bytes.map { characters[Int($0) % characters.count] })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let rawNonce,
              let tokenData = appleCredential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8),
              let authService else {
            finish(.failure(AuthServiceError.missingIdentityToken))
            return
        }

        let credential = AppleIdentityCredential(
            identityToken: identityToken,
            rawNonce: rawNonce,
            givenName: appleCredential.fullName?.givenName,
            familyName: appleCredential.fullName?.familyName
        )
        Task {
            do {
                finish(.success(try await authService.signIn(with: credential)))
            } catch {
                finish(.failure(error))
            }
        }
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let nsError = error as NSError
        if nsError.domain == ASAuthorizationError.errorDomain,
           nsError.code == ASAuthorizationError.canceled.rawValue {
            finish(.failure(AuthServiceError.cancelled))
        } else {
            finish(.failure(AuthServiceError.underlying(nsError.localizedDescription)))
        }
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        presentingViewController?.view.window ?? ASPresentationAnchor()
    }
}
