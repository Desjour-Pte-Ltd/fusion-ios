import Foundation

enum Country: String, Codable, CaseIterable, Identifiable {
    case Singapore = "SG"
    case Indonesia = "ID"
    case Philippines = "PH"
    
    var flagEmoji: String {
        switch self {
        case .Singapore: return "🇸🇬"
        case .Indonesia: return "🇮🇩"
        case .Philippines: return "🇵🇭"
        }
    }
    
    var name: String {
        // @todo localize
        switch self {
        case .Singapore: return "Singapore"
        case .Indonesia: return "Indonesia"
        case .Philippines: return "Philippines"
        }
    }
    
    var phoneCode: String {
        switch self {
        case .Singapore: return "+65"
        case .Indonesia: return "+62"
        case .Philippines: return "+63"
        }
    }
    
    var phoneRegex: String {
        switch self {
        case .Singapore: return Strings.singaporePhoneRegex
        case .Indonesia: return Strings.indonesiaPhoneRegex
        case .Philippines: return Strings.philippinesPhoneRegex
        }
    }
    
    var localeIdentifier: String {
        switch self {
        case .Singapore: return "en_SG"
        case .Indonesia: return "id_ID"
        case .Philippines: return "en_PH"
        }
    }
    
    var tosLink: String {
        switch self {
        case .Singapore, .Philippines: return Strings.sgdTOSLink
        case .Indonesia: return Strings.indTOSLink
        }
    }
    
    var id: Country { self }
}
