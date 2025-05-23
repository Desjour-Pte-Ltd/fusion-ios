import SwiftUI

extension Double {
    func toPrice(currencyCode: String, localeIdentifier: String, dropCurrency: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.currencySymbol = dropCurrency ? "" : currencyCode + " "
        
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

}

extension Int {
    var toString: String {
        String(self)
    }
}

