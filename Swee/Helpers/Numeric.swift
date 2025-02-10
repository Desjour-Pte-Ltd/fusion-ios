import SwiftUI

extension Double {
    func toPrice() -> String {
        return "S$ \(self)"
    }
}

extension Int {
    var toString: String {
        String(self)
    }
}

