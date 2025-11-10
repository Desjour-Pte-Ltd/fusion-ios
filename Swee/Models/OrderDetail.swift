import SwiftUI

struct OrderDetail: Hashable {
    let id: UUID
    let merchantName: String
    let bgColors: [Color]
    let quantity: Int
    let type: OrderType
    let status: OrderStatus
    let currencyCode: String
    let totalPriceCents: Double
    let createdAt: Date
}

extension OrderDetailModel: RawModelConvertable {
    func toLocal() -> OrderDetail {
        var colors: [Color] = [.gray]
        if let bgColors = merchantBackgroundColors {
            colors = bgColors.map { Color(hex: $0) }
        }
        return .init(id: id,
                     merchantName: merchantName,
                     bgColors: colors, 
                     quantity: quantity,
                     type: orderType,
                     status: status,
                     currencyCode: currencyCode,
                     totalPriceCents: totalPriceCents,
                     createdAt: createdAt)
    }
}
