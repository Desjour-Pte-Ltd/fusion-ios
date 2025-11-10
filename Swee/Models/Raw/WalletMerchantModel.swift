import Foundation

struct WalletMerchantModel: Codable {
    let merchantID: UUID
    let merchantName: String
    let merchantPhotoURL: URL?
    let merchantBackgroundColors: [String]?
    let purchaseSummary: String
    let products: [PurchaseProductModel]?
    let activeSession: SessionModel?
    let productType: ProductType?
    
    private enum CodingKeys: String, CodingKey {
        case merchantID = "merchant_id"
        case merchantName = "merchant_name"
        case merchantPhotoURL = "merchant_photo_url"
        case merchantBackgroundColors = "merchant_background_colors"
        case purchaseSummary = "purchase_summary"
        case products
        case activeSession = "active_session"
        case productType = "product_type"
    }
}

