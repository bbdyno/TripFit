import FirebaseAppCheck
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation

public final class FirebaseRuntime: @unchecked Sendable {
    public enum State: Equatable, Sendable {
        case notConfigured
        case configured(projectID: String)
        case unavailable(reason: String)
    }

    public static let shared = FirebaseRuntime()

    public private(set) var state: State = .notConfigured

    private init() {}

    public func configure(
        bundle: Bundle = .main,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        guard FirebaseApp.app() == nil else { return }
        guard let path = bundle.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            state = .unavailable(reason: "GoogleService-Info.plist is not bundled")
#if DEBUG
            print("[TripFit] Firebase disabled: GoogleService-Info.plist is not bundled")
#endif
            return
        }

        AppCheck.setAppCheckProviderFactory(makeAppCheckProviderFactory())
        FirebaseApp.configure(options: options)

        if environment["TRIPFIT_USE_FIREBASE_EMULATOR"] == "1" {
            Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
            Firestore.firestore().useEmulator(withHost: "127.0.0.1", port: 8080)
        }

        state = .configured(projectID: options.projectID ?? "unknown")
    }

    private func makeAppCheckProviderFactory() -> AppCheckProviderFactory {
#if DEBUG && targetEnvironment(simulator)
        AppCheckDebugProviderFactory()
#else
        AppAttestProviderFactory()
#endif
    }
}
