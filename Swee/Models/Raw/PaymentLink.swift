import Foundation

struct PaymentLink: Codable, Hashable {
    let id: String
    let invoiceURL: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case invoiceURL = "invoice_url"
    }
}
