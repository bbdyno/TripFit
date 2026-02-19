import Foundation

public struct CountryEssential: Codable {
    public let countryCode: String
    public let countryName: String
    public let voltageText: String
    public let frequencyText: String
    public let plugTypes: [String]
}

public final class CountryEssentialsService {
    public static let shared = CountryEssentialsService()
    private var cache: [CountryEssential] = []

    private init() {
        loadData()
    }

    private func loadData() {
        guard let url = Bundle.main.url(forResource: "CountryEssentials", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([CountryEssential].self, from: data)
        else { return }
        cache = items
    }

    public func essentials(for countryCode: String) -> CountryEssential? {
        cache.first { $0.countryCode == countryCode }
    }

    public static let recommendedPackingItems = [
        "Travel plug adapter",
        "USB charger",
        "Power strip",
    ]

    public static let recommendedNote = "Check device input voltage"
}
