import Foundation

struct OrderDetailModel: Codable {
    let id: UUID
    let merchantName: String
    let merchantBackgroundColors: [String]?
    let quantity: Int
    let orderType: OrderType
    let currencyCode: String
    let totalPriceCents: Double
    let status: OrderStatus
    @DecodableDate var createdAt: Date
    @DecodableDate var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case merchantName = "merchant_name"
        case merchantBackgroundColors = "merchant_background_colors"
        case quantity
        case orderType = "order_type"
        case currencyCode = "currency_code"
        case totalPriceCents = "total_price_cents"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
