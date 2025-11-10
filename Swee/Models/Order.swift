import SwiftUI

struct Order: Hashable {
    let id: UUID
    let status: OrderStatus
    let type: OrderType
    let paymentIntent: PaymentIntent?
    let paymentLink: PaymentLink?
    let currencyCode: String
    let totalPriceCents: Int
    let quantity: Int
    let merchantName: String
    let createdAtDate: Date
}

extension OrderModel: RawModelConvertable {
    func toLocal() -> Order {
        var quantity = 0
        if let items = items {
           quantity = items.reduce(0) { acc, item in
                return acc + item.quantity
            }
        }
        let merchantName =  items?.first?.snapshot.merchantName ?? "N/A"
        return .init(id: id,
                     status: status,
                     type: type,
                     paymentIntent: paymentIntent,
                     paymentLink: paymentLink,
                     currencyCode: currencyCode,
                     totalPriceCents: totalPriceCents,
                     quantity: quantity,
                     merchantName: merchantName,
                     createdAtDate: createdAt)
    }
}
