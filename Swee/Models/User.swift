import Foundation
import SwiftUI

struct User: Identifiable, Codable {
    enum Gender: String, Codable, CaseIterable {
        case male = "M"
        case female = "F"
        case other = "O"
        case notSpecified = "NS"
        
        var toString: String {
            switch self {
            case .male:
                return "Male"
            case .female:
                return "Female"
            case .other:
                return "Other"
            case .notSpecified:
                return "Not specified"
            }
        }
    }
    let id: String
    let name: String
    let preferredLanguage: String
    let phone: String
    let gender: Gender
    let email: String?
    let photoURL: String?
    var uploadingImage: UIImage? = nil
    let profileCompleteness: Int?
    var freshReferral: Bool = false
    @DecodableDayDate var dob: Date?
    
    var birthDayString: String? {
        if let dob = dob {
            return Date.iso8601DateOnly.string(from: dob)
        }

        return nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case preferredLanguage = "preferred_language"
        case phone = "phone_number"
        case gender
        case email
        case photoURL = "photo_url"
        case dob = "date_of_birth"
        case profileCompleteness = "profile_completeness"
    }
}
