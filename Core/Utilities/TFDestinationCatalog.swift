//
//  TFDestinationCatalog.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Foundation

public struct TFDestinationInfo: Hashable {
    public let countryCode: String
    public let countryName: String
    public let cityName: String
    public let timeZoneIdentifier: String

    public init(countryCode: String, countryName: String, cityName: String, timeZoneIdentifier: String) {
        self.countryCode = countryCode
        self.countryName = countryName
        self.cityName = cityName
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    public var displayName: String {
        "\(cityName), \(countryName)"
    }
}

public enum TFDestinationCatalog {
    private static let primaryDestinations: [TFDestinationInfo] = [
        TFDestinationInfo(countryCode: "US", countryName: "United States", cityName: "New York", timeZoneIdentifier: "America/New_York"),
        TFDestinationInfo(countryCode: "CA", countryName: "Canada", cityName: "Toronto", timeZoneIdentifier: "America/Toronto"),
        TFDestinationInfo(countryCode: "MX", countryName: "Mexico", cityName: "Mexico City", timeZoneIdentifier: "America/Mexico_City"),
        TFDestinationInfo(countryCode: "BR", countryName: "Brazil", cityName: "Sao Paulo", timeZoneIdentifier: "America/Sao_Paulo"),
        TFDestinationInfo(countryCode: "AR", countryName: "Argentina", cityName: "Buenos Aires", timeZoneIdentifier: "America/Argentina/Buenos_Aires"),
        TFDestinationInfo(countryCode: "CL", countryName: "Chile", cityName: "Santiago", timeZoneIdentifier: "America/Santiago"),
        TFDestinationInfo(countryCode: "PE", countryName: "Peru", cityName: "Lima", timeZoneIdentifier: "America/Lima"),
        TFDestinationInfo(countryCode: "CO", countryName: "Colombia", cityName: "Bogota", timeZoneIdentifier: "America/Bogota"),
        TFDestinationInfo(countryCode: "PA", countryName: "Panama", cityName: "Panama City", timeZoneIdentifier: "America/Panama"),
        TFDestinationInfo(countryCode: "CR", countryName: "Costa Rica", cityName: "San Jose", timeZoneIdentifier: "America/Costa_Rica"),
        TFDestinationInfo(countryCode: "DO", countryName: "Dominican Republic", cityName: "Santo Domingo", timeZoneIdentifier: "America/Santo_Domingo"),
        TFDestinationInfo(countryCode: "CU", countryName: "Cuba", cityName: "Havana", timeZoneIdentifier: "America/Havana"),
        TFDestinationInfo(countryCode: "JM", countryName: "Jamaica", cityName: "Kingston", timeZoneIdentifier: "America/Jamaica"),
        TFDestinationInfo(countryCode: "PR", countryName: "Puerto Rico", cityName: "San Juan", timeZoneIdentifier: "America/Puerto_Rico"),
        TFDestinationInfo(countryCode: "VE", countryName: "Venezuela", cityName: "Caracas", timeZoneIdentifier: "America/Caracas"),
        TFDestinationInfo(countryCode: "UY", countryName: "Uruguay", cityName: "Montevideo", timeZoneIdentifier: "America/Montevideo"),
        TFDestinationInfo(countryCode: "GB", countryName: "United Kingdom", cityName: "London", timeZoneIdentifier: "Europe/London"),
        TFDestinationInfo(countryCode: "IE", countryName: "Ireland", cityName: "Dublin", timeZoneIdentifier: "Europe/Dublin"),
        TFDestinationInfo(countryCode: "FR", countryName: "France", cityName: "Paris", timeZoneIdentifier: "Europe/Paris"),
        TFDestinationInfo(countryCode: "DE", countryName: "Germany", cityName: "Berlin", timeZoneIdentifier: "Europe/Berlin"),
        TFDestinationInfo(countryCode: "IT", countryName: "Italy", cityName: "Rome", timeZoneIdentifier: "Europe/Rome"),
        TFDestinationInfo(countryCode: "ES", countryName: "Spain", cityName: "Madrid", timeZoneIdentifier: "Europe/Madrid"),
        TFDestinationInfo(countryCode: "PT", countryName: "Portugal", cityName: "Lisbon", timeZoneIdentifier: "Europe/Lisbon"),
        TFDestinationInfo(countryCode: "NL", countryName: "Netherlands", cityName: "Amsterdam", timeZoneIdentifier: "Europe/Amsterdam"),
        TFDestinationInfo(countryCode: "BE", countryName: "Belgium", cityName: "Brussels", timeZoneIdentifier: "Europe/Brussels"),
        TFDestinationInfo(countryCode: "CH", countryName: "Switzerland", cityName: "Zurich", timeZoneIdentifier: "Europe/Zurich"),
        TFDestinationInfo(countryCode: "AT", countryName: "Austria", cityName: "Vienna", timeZoneIdentifier: "Europe/Vienna"),
        TFDestinationInfo(countryCode: "SE", countryName: "Sweden", cityName: "Stockholm", timeZoneIdentifier: "Europe/Stockholm"),
        TFDestinationInfo(countryCode: "NO", countryName: "Norway", cityName: "Oslo", timeZoneIdentifier: "Europe/Oslo"),
        TFDestinationInfo(countryCode: "FI", countryName: "Finland", cityName: "Helsinki", timeZoneIdentifier: "Europe/Helsinki"),
        TFDestinationInfo(countryCode: "DK", countryName: "Denmark", cityName: "Copenhagen", timeZoneIdentifier: "Europe/Copenhagen"),
        TFDestinationInfo(countryCode: "PL", countryName: "Poland", cityName: "Warsaw", timeZoneIdentifier: "Europe/Warsaw"),
        TFDestinationInfo(countryCode: "CZ", countryName: "Czech Republic", cityName: "Prague", timeZoneIdentifier: "Europe/Prague"),
        TFDestinationInfo(countryCode: "HU", countryName: "Hungary", cityName: "Budapest", timeZoneIdentifier: "Europe/Budapest"),
        TFDestinationInfo(countryCode: "GR", countryName: "Greece", cityName: "Athens", timeZoneIdentifier: "Europe/Athens"),
        TFDestinationInfo(countryCode: "TR", countryName: "Turkey", cityName: "Istanbul", timeZoneIdentifier: "Europe/Istanbul"),
        TFDestinationInfo(countryCode: "RO", countryName: "Romania", cityName: "Bucharest", timeZoneIdentifier: "Europe/Bucharest"),
        TFDestinationInfo(countryCode: "BG", countryName: "Bulgaria", cityName: "Sofia", timeZoneIdentifier: "Europe/Sofia"),
        TFDestinationInfo(countryCode: "HR", countryName: "Croatia", cityName: "Zagreb", timeZoneIdentifier: "Europe/Zagreb"),
        TFDestinationInfo(countryCode: "RS", countryName: "Serbia", cityName: "Belgrade", timeZoneIdentifier: "Europe/Belgrade"),
        TFDestinationInfo(countryCode: "UA", countryName: "Ukraine", cityName: "Kyiv", timeZoneIdentifier: "Europe/Kyiv"),
        TFDestinationInfo(countryCode: "LT", countryName: "Lithuania", cityName: "Vilnius", timeZoneIdentifier: "Europe/Vilnius"),
        TFDestinationInfo(countryCode: "LV", countryName: "Latvia", cityName: "Riga", timeZoneIdentifier: "Europe/Riga"),
        TFDestinationInfo(countryCode: "EE", countryName: "Estonia", cityName: "Tallinn", timeZoneIdentifier: "Europe/Tallinn"),
        TFDestinationInfo(countryCode: "SI", countryName: "Slovenia", cityName: "Ljubljana", timeZoneIdentifier: "Europe/Ljubljana"),
        TFDestinationInfo(countryCode: "SK", countryName: "Slovakia", cityName: "Bratislava", timeZoneIdentifier: "Europe/Bratislava"),
        TFDestinationInfo(countryCode: "IS", countryName: "Iceland", cityName: "Reykjavik", timeZoneIdentifier: "Atlantic/Reykjavik"),
        TFDestinationInfo(countryCode: "MT", countryName: "Malta", cityName: "Valletta", timeZoneIdentifier: "Europe/Malta"),
        TFDestinationInfo(countryCode: "CY", countryName: "Cyprus", cityName: "Nicosia", timeZoneIdentifier: "Asia/Nicosia"),
        TFDestinationInfo(countryCode: "AE", countryName: "United Arab Emirates", cityName: "Dubai", timeZoneIdentifier: "Asia/Dubai"),
        TFDestinationInfo(countryCode: "SA", countryName: "Saudi Arabia", cityName: "Riyadh", timeZoneIdentifier: "Asia/Riyadh"),
        TFDestinationInfo(countryCode: "QA", countryName: "Qatar", cityName: "Doha", timeZoneIdentifier: "Asia/Qatar"),
        TFDestinationInfo(countryCode: "KW", countryName: "Kuwait", cityName: "Kuwait City", timeZoneIdentifier: "Asia/Kuwait"),
        TFDestinationInfo(countryCode: "OM", countryName: "Oman", cityName: "Muscat", timeZoneIdentifier: "Asia/Muscat"),
        TFDestinationInfo(countryCode: "JO", countryName: "Jordan", cityName: "Amman", timeZoneIdentifier: "Asia/Amman"),
        TFDestinationInfo(countryCode: "LB", countryName: "Lebanon", cityName: "Beirut", timeZoneIdentifier: "Asia/Beirut"),
        TFDestinationInfo(countryCode: "IL", countryName: "Israel", cityName: "Tel Aviv", timeZoneIdentifier: "Asia/Jerusalem"),
        TFDestinationInfo(countryCode: "IR", countryName: "Iran", cityName: "Tehran", timeZoneIdentifier: "Asia/Tehran"),
        TFDestinationInfo(countryCode: "IQ", countryName: "Iraq", cityName: "Baghdad", timeZoneIdentifier: "Asia/Baghdad"),
        TFDestinationInfo(countryCode: "EG", countryName: "Egypt", cityName: "Cairo", timeZoneIdentifier: "Africa/Cairo"),
        TFDestinationInfo(countryCode: "MA", countryName: "Morocco", cityName: "Casablanca", timeZoneIdentifier: "Africa/Casablanca"),
        TFDestinationInfo(countryCode: "ZA", countryName: "South Africa", cityName: "Cape Town", timeZoneIdentifier: "Africa/Johannesburg"),
        TFDestinationInfo(countryCode: "KE", countryName: "Kenya", cityName: "Nairobi", timeZoneIdentifier: "Africa/Nairobi"),
        TFDestinationInfo(countryCode: "NG", countryName: "Nigeria", cityName: "Lagos", timeZoneIdentifier: "Africa/Lagos"),
        TFDestinationInfo(countryCode: "GH", countryName: "Ghana", cityName: "Accra", timeZoneIdentifier: "Africa/Accra"),
        TFDestinationInfo(countryCode: "ET", countryName: "Ethiopia", cityName: "Addis Ababa", timeZoneIdentifier: "Africa/Addis_Ababa"),
        TFDestinationInfo(countryCode: "TZ", countryName: "Tanzania", cityName: "Dar es Salaam", timeZoneIdentifier: "Africa/Dar_es_Salaam"),
        TFDestinationInfo(countryCode: "IN", countryName: "India", cityName: "New Delhi", timeZoneIdentifier: "Asia/Kolkata"),
        TFDestinationInfo(countryCode: "PK", countryName: "Pakistan", cityName: "Karachi", timeZoneIdentifier: "Asia/Karachi"),
        TFDestinationInfo(countryCode: "BD", countryName: "Bangladesh", cityName: "Dhaka", timeZoneIdentifier: "Asia/Dhaka"),
        TFDestinationInfo(countryCode: "LK", countryName: "Sri Lanka", cityName: "Colombo", timeZoneIdentifier: "Asia/Colombo"),
        TFDestinationInfo(countryCode: "NP", countryName: "Nepal", cityName: "Kathmandu", timeZoneIdentifier: "Asia/Kathmandu"),
        TFDestinationInfo(countryCode: "BT", countryName: "Bhutan", cityName: "Thimphu", timeZoneIdentifier: "Asia/Thimphu"),
        TFDestinationInfo(countryCode: "MV", countryName: "Maldives", cityName: "Male", timeZoneIdentifier: "Indian/Maldives"),
        TFDestinationInfo(countryCode: "KZ", countryName: "Kazakhstan", cityName: "Almaty", timeZoneIdentifier: "Asia/Almaty"),
        TFDestinationInfo(countryCode: "UZ", countryName: "Uzbekistan", cityName: "Tashkent", timeZoneIdentifier: "Asia/Tashkent"),
        TFDestinationInfo(countryCode: "CN", countryName: "China", cityName: "Beijing", timeZoneIdentifier: "Asia/Shanghai"),
        TFDestinationInfo(countryCode: "HK", countryName: "Hong Kong", cityName: "Hong Kong", timeZoneIdentifier: "Asia/Hong_Kong"),
        TFDestinationInfo(countryCode: "TW", countryName: "Taiwan", cityName: "Taipei", timeZoneIdentifier: "Asia/Taipei"),
        TFDestinationInfo(countryCode: "JP", countryName: "Japan", cityName: "Tokyo", timeZoneIdentifier: "Asia/Tokyo"),
        TFDestinationInfo(countryCode: "KR", countryName: "South Korea", cityName: "Seoul", timeZoneIdentifier: "Asia/Seoul"),
        TFDestinationInfo(countryCode: "MN", countryName: "Mongolia", cityName: "Ulaanbaatar", timeZoneIdentifier: "Asia/Ulaanbaatar"),
        TFDestinationInfo(countryCode: "SG", countryName: "Singapore", cityName: "Singapore", timeZoneIdentifier: "Asia/Singapore"),
        TFDestinationInfo(countryCode: "TH", countryName: "Thailand", cityName: "Bangkok", timeZoneIdentifier: "Asia/Bangkok"),
        TFDestinationInfo(countryCode: "VN", countryName: "Vietnam", cityName: "Ho Chi Minh City", timeZoneIdentifier: "Asia/Ho_Chi_Minh"),
        TFDestinationInfo(countryCode: "MY", countryName: "Malaysia", cityName: "Kuala Lumpur", timeZoneIdentifier: "Asia/Kuala_Lumpur"),
        TFDestinationInfo(countryCode: "ID", countryName: "Indonesia", cityName: "Jakarta", timeZoneIdentifier: "Asia/Jakarta"),
        TFDestinationInfo(countryCode: "PH", countryName: "Philippines", cityName: "Manila", timeZoneIdentifier: "Asia/Manila"),
        TFDestinationInfo(countryCode: "KH", countryName: "Cambodia", cityName: "Phnom Penh", timeZoneIdentifier: "Asia/Phnom_Penh"),
        TFDestinationInfo(countryCode: "LA", countryName: "Laos", cityName: "Vientiane", timeZoneIdentifier: "Asia/Vientiane"),
        TFDestinationInfo(countryCode: "MM", countryName: "Myanmar", cityName: "Yangon", timeZoneIdentifier: "Asia/Yangon"),
        TFDestinationInfo(countryCode: "AU", countryName: "Australia", cityName: "Sydney", timeZoneIdentifier: "Australia/Sydney"),
        TFDestinationInfo(countryCode: "NZ", countryName: "New Zealand", cityName: "Auckland", timeZoneIdentifier: "Pacific/Auckland"),
        TFDestinationInfo(countryCode: "FJ", countryName: "Fiji", cityName: "Nadi", timeZoneIdentifier: "Pacific/Fiji"),
        TFDestinationInfo(countryCode: "PG", countryName: "Papua New Guinea", cityName: "Port Moresby", timeZoneIdentifier: "Pacific/Port_Moresby"),
        TFDestinationInfo(countryCode: "WS", countryName: "Samoa", cityName: "Apia", timeZoneIdentifier: "Pacific/Apia"),
        TFDestinationInfo(countryCode: "GU", countryName: "Guam", cityName: "Hagatna", timeZoneIdentifier: "Pacific/Guam"),
    ]

    private static let additionalCitiesByCountryCode: [String: [(cityName: String, timeZoneIdentifier: String)]] = [
        "US": [("Los Angeles", "America/Los_Angeles"), ("Chicago", "America/Chicago"), ("Miami", "America/New_York"), ("Seattle", "America/Los_Angeles"), ("Honolulu", "Pacific/Honolulu")],
        "CA": [("Vancouver", "America/Vancouver"), ("Montreal", "America/Toronto"), ("Calgary", "America/Edmonton")],
        "MX": [("Cancun", "America/Cancun"), ("Guadalajara", "America/Mexico_City")],
        "BR": [("Rio de Janeiro", "America/Sao_Paulo"), ("Brasilia", "America/Sao_Paulo"), ("Salvador", "America/Bahia")],
        "AR": [("Cordoba", "America/Argentina/Cordoba"), ("Mendoza", "America/Argentina/Mendoza")],
        "CL": [("Valparaiso", "America/Santiago"), ("San Pedro de Atacama", "America/Santiago")],
        "PE": [("Cusco", "America/Lima"), ("Arequipa", "America/Lima")],
        "CO": [("Medellin", "America/Bogota"), ("Cartagena", "America/Bogota")],
        "PA": [("Bocas del Toro", "America/Panama")],
        "CR": [("Liberia", "America/Costa_Rica")],
        "DO": [("Punta Cana", "America/Santo_Domingo")],
        "CU": [("Santiago de Cuba", "America/Havana")],
        "JM": [("Montego Bay", "America/Jamaica")],
        "PR": [("Ponce", "America/Puerto_Rico")],
        "VE": [("Maracaibo", "America/Caracas")],
        "UY": [("Punta del Este", "America/Montevideo")],
        "GB": [("Manchester", "Europe/London"), ("Edinburgh", "Europe/London"), ("Liverpool", "Europe/London")],
        "IE": [("Cork", "Europe/Dublin"), ("Galway", "Europe/Dublin")],
        "FR": [("Lyon", "Europe/Paris"), ("Nice", "Europe/Paris"), ("Marseille", "Europe/Paris")],
        "DE": [("Munich", "Europe/Berlin"), ("Hamburg", "Europe/Berlin"), ("Frankfurt", "Europe/Berlin")],
        "IT": [("Milan", "Europe/Rome"), ("Florence", "Europe/Rome"), ("Venice", "Europe/Rome"), ("Naples", "Europe/Rome")],
        "ES": [("Barcelona", "Europe/Madrid"), ("Seville", "Europe/Madrid"), ("Valencia", "Europe/Madrid")],
        "PT": [("Porto", "Europe/Lisbon"), ("Faro", "Europe/Lisbon")],
        "NL": [("Rotterdam", "Europe/Amsterdam"), ("Utrecht", "Europe/Amsterdam")],
        "BE": [("Antwerp", "Europe/Brussels"), ("Bruges", "Europe/Brussels")],
        "CH": [("Geneva", "Europe/Zurich"), ("Lucerne", "Europe/Zurich"), ("Interlaken", "Europe/Zurich")],
        "AT": [("Salzburg", "Europe/Vienna"), ("Innsbruck", "Europe/Vienna")],
        "SE": [("Gothenburg", "Europe/Stockholm"), ("Malmo", "Europe/Stockholm")],
        "NO": [("Bergen", "Europe/Oslo"), ("Tromso", "Europe/Oslo")],
        "FI": [("Turku", "Europe/Helsinki"), ("Rovaniemi", "Europe/Helsinki")],
        "DK": [("Aarhus", "Europe/Copenhagen"), ("Odense", "Europe/Copenhagen")],
        "PL": [("Krakow", "Europe/Warsaw"), ("Gdansk", "Europe/Warsaw")],
        "CZ": [("Brno", "Europe/Prague")],
        "HU": [("Debrecen", "Europe/Budapest")],
        "GR": [("Thessaloniki", "Europe/Athens"), ("Heraklion", "Europe/Athens")],
        "TR": [("Ankara", "Europe/Istanbul"), ("Izmir", "Europe/Istanbul"), ("Antalya", "Europe/Istanbul")],
        "RO": [("Cluj-Napoca", "Europe/Bucharest")],
        "BG": [("Plovdiv", "Europe/Sofia")],
        "HR": [("Split", "Europe/Zagreb"), ("Dubrovnik", "Europe/Zagreb")],
        "RS": [("Novi Sad", "Europe/Belgrade")],
        "UA": [("Lviv", "Europe/Kyiv"), ("Odesa", "Europe/Kyiv")],
        "LT": [("Kaunas", "Europe/Vilnius")],
        "LV": [("Jurmala", "Europe/Riga")],
        "EE": [("Tartu", "Europe/Tallinn")],
        "SI": [("Maribor", "Europe/Ljubljana")],
        "SK": [("Kosice", "Europe/Bratislava")],
        "IS": [("Akureyri", "Atlantic/Reykjavik")],
        "MT": [("Sliema", "Europe/Malta")],
        "CY": [("Limassol", "Asia/Nicosia"), ("Larnaca", "Asia/Nicosia")],
        "AE": [("Abu Dhabi", "Asia/Dubai"), ("Sharjah", "Asia/Dubai")],
        "SA": [("Jeddah", "Asia/Riyadh"), ("Dammam", "Asia/Riyadh")],
        "QA": [("Al Wakrah", "Asia/Qatar")],
        "KW": [("Salmiya", "Asia/Kuwait")],
        "OM": [("Salalah", "Asia/Muscat")],
        "JO": [("Aqaba", "Asia/Amman")],
        "LB": [("Tripoli", "Asia/Beirut")],
        "IL": [("Jerusalem", "Asia/Jerusalem"), ("Haifa", "Asia/Jerusalem")],
        "IR": [("Isfahan", "Asia/Tehran"), ("Shiraz", "Asia/Tehran")],
        "IQ": [("Basra", "Asia/Baghdad")],
        "EG": [("Alexandria", "Africa/Cairo"), ("Luxor", "Africa/Cairo"), ("Sharm El Sheikh", "Africa/Cairo")],
        "MA": [("Marrakech", "Africa/Casablanca"), ("Rabat", "Africa/Casablanca"), ("Fes", "Africa/Casablanca")],
        "ZA": [("Johannesburg", "Africa/Johannesburg"), ("Durban", "Africa/Johannesburg")],
        "KE": [("Mombasa", "Africa/Nairobi")],
        "NG": [("Abuja", "Africa/Lagos")],
        "GH": [("Kumasi", "Africa/Accra")],
        "ET": [("Bahir Dar", "Africa/Addis_Ababa")],
        "TZ": [("Arusha", "Africa/Dar_es_Salaam"), ("Zanzibar", "Africa/Dar_es_Salaam")],
        "IN": [("Mumbai", "Asia/Kolkata"), ("Bengaluru", "Asia/Kolkata"), ("Chennai", "Asia/Kolkata"), ("Kolkata", "Asia/Kolkata"), ("Hyderabad", "Asia/Kolkata")],
        "PK": [("Lahore", "Asia/Karachi"), ("Islamabad", "Asia/Karachi")],
        "BD": [("Chittagong", "Asia/Dhaka")],
        "LK": [("Kandy", "Asia/Colombo")],
        "NP": [("Pokhara", "Asia/Kathmandu")],
        "BT": [("Paro", "Asia/Thimphu")],
        "MV": [("Addu City", "Indian/Maldives")],
        "KZ": [("Astana", "Asia/Almaty"), ("Shymkent", "Asia/Almaty")],
        "UZ": [("Samarkand", "Asia/Tashkent"), ("Bukhara", "Asia/Tashkent")],
        "CN": [("Shanghai", "Asia/Shanghai"), ("Guangzhou", "Asia/Shanghai"), ("Shenzhen", "Asia/Shanghai"), ("Chengdu", "Asia/Shanghai"), ("Xian", "Asia/Shanghai")],
        "HK": [("Kowloon", "Asia/Hong_Kong")],
        "TW": [("Kaohsiung", "Asia/Taipei"), ("Taichung", "Asia/Taipei")],
        "JP": [("Osaka", "Asia/Tokyo"), ("Kyoto", "Asia/Tokyo"), ("Fukuoka", "Asia/Tokyo"), ("Sapporo", "Asia/Tokyo"), ("Nagoya", "Asia/Tokyo")],
        "KR": [("Busan", "Asia/Seoul"), ("Jeju", "Asia/Seoul"), ("Daejeon", "Asia/Seoul"), ("Incheon", "Asia/Seoul")],
        "MN": [("Darkhan", "Asia/Ulaanbaatar")],
        "SG": [("Jurong East", "Asia/Singapore")],
        "TH": [("Chiang Mai", "Asia/Bangkok"), ("Phuket", "Asia/Bangkok"), ("Pattaya", "Asia/Bangkok")],
        "VN": [("Hanoi", "Asia/Ho_Chi_Minh"), ("Da Nang", "Asia/Ho_Chi_Minh"), ("Nha Trang", "Asia/Ho_Chi_Minh")],
        "MY": [("Penang", "Asia/Kuala_Lumpur"), ("Johor Bahru", "Asia/Kuala_Lumpur"), ("Kota Kinabalu", "Asia/Kuching")],
        "ID": [("Bali", "Asia/Makassar"), ("Surabaya", "Asia/Jakarta"), ("Yogyakarta", "Asia/Jakarta"), ("Medan", "Asia/Jakarta")],
        "PH": [("Cebu", "Asia/Manila"), ("Davao", "Asia/Manila"), ("Boracay", "Asia/Manila")],
        "KH": [("Siem Reap", "Asia/Phnom_Penh")],
        "LA": [("Luang Prabang", "Asia/Vientiane")],
        "MM": [("Mandalay", "Asia/Yangon"), ("Naypyidaw", "Asia/Yangon")],
        "AU": [("Melbourne", "Australia/Sydney"), ("Brisbane", "Australia/Brisbane"), ("Perth", "Australia/Perth"), ("Adelaide", "Australia/Adelaide")],
        "NZ": [("Wellington", "Pacific/Auckland"), ("Christchurch", "Pacific/Auckland"), ("Queenstown", "Pacific/Auckland")],
        "FJ": [("Suva", "Pacific/Fiji")],
        "PG": [("Lae", "Pacific/Port_Moresby")],
        "WS": [("Savaii", "Pacific/Apia")],
        "GU": [("Tumon", "Pacific/Guam")],
    ]

    public static let all: [TFDestinationInfo] = {
        var destinations = primaryDestinations
        for primary in primaryDestinations {
            guard let extras = additionalCitiesByCountryCode[primary.countryCode] else { continue }
            for extra in extras where extra.cityName.caseInsensitiveCompare(primary.cityName) != .orderedSame {
                destinations.append(
                    TFDestinationInfo(
                        countryCode: primary.countryCode,
                        countryName: primary.countryName,
                        cityName: extra.cityName,
                        timeZoneIdentifier: extra.timeZoneIdentifier
                    )
                )
            }
        }
        return destinations
    }()

    private static let codeMap = Dictionary(grouping: all, by: { $0.countryCode.uppercased() })
    public static func info(forCountryCode code: String?) -> TFDestinationInfo? {
        guard let code else { return nil }
        return codeMap[code.uppercased()]?.first
    }

    public static func info(matchingDestinationText text: String?) -> TFDestinationInfo? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        let query = text.lowercased()
        return all.first { info in
            query.contains(info.cityName.lowercased())
                || query.contains(info.countryName.lowercased())
                || query.contains(info.countryCode.lowercased())
        }
    }

    public static func locationTimeString(
        for timeZoneIdentifier: String?,
        at date: Date = Date(),
        includeSeconds: Bool = true
    ) -> String? {
        guard let timeZoneIdentifier, let timeZone = TimeZone(identifier: timeZoneIdentifier) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = includeSeconds ? "HH:mm:ss" : "HH:mm"
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    public static func gmtOffsetString(for timeZoneIdentifier: String?, at date: Date = Date()) -> String? {
        guard let timeZoneIdentifier, let timeZone = TimeZone(identifier: timeZoneIdentifier) else { return nil }
        let seconds = timeZone.secondsFromGMT(for: date)
        let sign = seconds >= 0 ? "+" : "-"
        let absSeconds = abs(seconds)
        let hours = absSeconds / 3600
        let minutes = (absSeconds % 3600) / 60
        return String(format: "GMT%@%02d:%02d", sign, hours, minutes)
    }

    public static func localDeltaString(
        for timeZoneIdentifier: String?,
        at date: Date = Date(),
        localTimeZone: TimeZone = .current
    ) -> String? {
        guard let timeZoneIdentifier, let targetZone = TimeZone(identifier: timeZoneIdentifier) else { return nil }
        let delta = targetZone.secondsFromGMT(for: date) - localTimeZone.secondsFromGMT(for: date)
        if delta == 0 { return "Local ±0h" }

        let sign = delta >= 0 ? "+" : "-"
        let absSeconds = abs(delta)
        let hours = absSeconds / 3600
        let minutes = (absSeconds % 3600) / 60
        if minutes == 0 {
            return "Local \(sign)\(hours)h"
        } else {
            return String(format: "Local %@%02d:%02d", sign, hours, minutes)
        }
    }
}
