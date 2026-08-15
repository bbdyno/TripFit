import Foundation

public enum InviteLinkParser {
    public static let hostingDomain = "tripfit-bbdyno.web.app"

    public static func rawToken(from url: URL) -> String? {
        guard url.scheme?.lowercased() == "https",
              url.host?.lowercased() == hostingDomain else {
            return nil
        }
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count == 2, components[0] == "join" else { return nil }
        let token = components[1]
        guard token.count >= 43, token.count <= 256,
              token.unicodeScalars.allSatisfy({
                  CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_"
              }) else {
            return nil
        }
        return token
    }
}
