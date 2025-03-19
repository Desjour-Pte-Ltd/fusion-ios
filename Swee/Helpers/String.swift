import SwiftUI

extension String {
    func underline(font: Font = .custom("Poppins-Medium", size: 14),
                   color: Color = Color.text.black80) -> AttributedString {
        var string = AttributedString(self)
        string.font = font
        string.foregroundColor = color
        string.underlineStyle = Text.LineStyle(pattern: .solid, color: color)
        
        return string
    }
    
    func strikethroughText(color: Color = Color.text.black40) -> AttributedString {
        var string = AttributedString(self)
        string.strikethroughStyle = Text.LineStyle(color: color)
        
        return string
    }
    
    var singularName: String {
        let mutableName = self
        return mutableName.replacingOccurrences(of: "(s)", with: "")
    }
    
    func i18n(with arguments: any CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments)
    }
    
    var i18n: String {
        return i18n(with: "")
    }
}

extension Optional where Wrapped == String {
    var isEmpty: Bool {
        if let string = self {
            return string.isEmpty
        }
        
        return true
    }
}
