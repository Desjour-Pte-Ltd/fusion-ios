//
//  Analytics.swift
//  Swee
//
//  Created by Serghei on 08.03.2025.
//

import Foundation
import Mixpanel

protocol Trackable {
    var properties: [String: String] { get }
}

enum Analytics {
    struct Home: Trackable {
        enum Region: String {
            case Singapore = "SG"
            case Indonesia = "ID"
            case Philippines = "PH"
        }
        let region: Region
        
        var properties: [String: String] {
            return ["region": region.rawValue]
        }
    }
    
    struct Merchant: Trackable {
        let id: String
        let name: String
        
        var properties: [String : String] {
            return ["merchant_id": id,
                    "merchant_name": name]
        }
    }
    
    struct Product: Trackable {
        let id: String
        let name: String
        
        var properties: [String : String] {
            return ["product_id": id,
                    "product_name": name]
        }
    }
    
    case homeScreen(Home)
    case merchantScreen(Merchant)
    case productScreen(Product)
    case cartScreen
    case walletScreen
    case activityScreen
    case profileScreen
    case seeAllProductsScreen(String)
    case alertsScreen

    fileprivate var eventName: String {
        switch self {
        case .homeScreen(_),
                .merchantScreen(_),
                .productScreen(_),
                .cartScreen,
                .walletScreen,
                .activityScreen,
                .profileScreen,
                .seeAllProductsScreen(_),
                .alertsScreen:
            return "Show Screen"
        }
    }
    
    fileprivate var properties: [String: String] {
        let screenNameKey = "screen_name"
        switch self {
        case .homeScreen(let home):
            return [screenNameKey: "Home"] + home.properties
        case .merchantScreen(let merchant):
            return [screenNameKey: "Merchant"] + merchant.properties
        case .productScreen(let product):
            return [screenNameKey: "Product"] + product.properties
        case .cartScreen:
            return [screenNameKey: "Cart"]
        case .walletScreen:
            return [screenNameKey: "Wallet"]
        case .activityScreen:
            return [screenNameKey: "Activity"]
        case .profileScreen:
            return [screenNameKey: "Profile"]
        case .seeAllProductsScreen(let name):
            return [screenNameKey: "See All Products"]
        case .alertsScreen:
            return [screenNameKey: "Alerts"]
        }
    }

    func capture() {
        Mixpanel.mainInstance().track(event: eventName,
                                      properties: properties)
    }
}

extension Dictionary {
    static func + (lhs: Dictionary, rhs: Dictionary) -> Dictionary {
        var result = lhs
        for (key, value) in rhs {
            result[key] = value
        }
        return result
    }
}
