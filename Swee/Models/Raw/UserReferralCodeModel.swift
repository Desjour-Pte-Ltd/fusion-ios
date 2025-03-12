import Foundation

struct UserReferralCodeModel: Codable {
    let customerId: String
    let referralCode: String
    
    private enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
        case referralCode = "referral_code"
    }
}
