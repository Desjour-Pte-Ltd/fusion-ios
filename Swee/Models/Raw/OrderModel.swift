import Foundation

enum OrderStatus: String, Codable, Equatable {
    case pending = "PENDING"
    case completed = "COMPLETED"
    case failed = "FAILED"
}

enum OrderType: String, Codable, Equatable {
    case online = "ONLINE"
    case otc = "OTC"
}

struct OrderModel: Codable {
    let id: UUID
    let userID: UUID
    let cartID: UUID
    let status: OrderStatus
    let type: OrderType
    let currencyCode: String
    let priceCents: Int
    let totalPriceCents: Int
    let paymentIntent: PaymentIntent?
    let paymentLink: PaymentLink?
    let items: [OrderItem]?
    let fees: [FeeModel]?
    @DecodableDate var createdAt: Date
    @DecodableDate var updatedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case cartID = "cart_id"
        case status
        case paymentIntent = "payment_intent"
        case paymentLink = "payment_link"
        case type = "order_type"
        case currencyCode = "currency_code"
        case priceCents = "price_cents"
        case totalPriceCents = "total_price_cents"
        case items, fees
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
