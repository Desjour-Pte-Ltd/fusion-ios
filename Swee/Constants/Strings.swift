import Foundation

struct Strings {
    #if BETA
    static let baseURL: String = "https://api.fusionkidsapp.com/v1"
    #else
    static let baseURL: String = "https://api.greenkidsapp.com/v1"
    #endif
    static let indTOSLink: String = "https://www.greenyourday.app/kebijakan-privasi"
    static let sgdTOSLink: String = "https://greenappkids.s3.ap-southeast-1.amazonaws.com/docs/terms_and_condition.pdf"
    static let helpLink: String = "https://www.greenyourday.app/help"
    static let rateAppLink: String = "itms-apps://itunes.apple.com/app/id6738002000?action=write-review"
    
    static let stripeReturnURL = "com.zoomoov.greenapp://stripe-redirect"
#if BETA
    static let stripePublishableKey = "pk_test_51LUUoYK8RYfweLYTt9LSdAlQaxjwIyk7UPjXYme3J1zstiC0mcQA2zTMeEj4yTZryjzTsPJcnTWpjj9J5Epf7hzE002MVGVeVE" // @todo replace the publishable key with the live version
    static let stripeMerchantId = "merchant.com.desjour.fusion"
#else
    static let stripePublishableKey = "pk_live_51LUUoYK8RYfweLYTRufc5faC8hrb2hQYpqraOH7THzYEwbgj3rwejrcaejBENTzWaMkhNK2Fdz7RaonMgj1shz8E00dVwwiM2N" // @todo replace the publishable key with the live version
    static let stripeMerchantId = "merchant.com.zoomoov.green"
#endif
    static let stripeMerchantName = "Green"
    static let singaporePhoneRegex = "^(?:\\+65)?[3689]\\d{7}$"
    static let indonesiaPhoneRegex = "^(?:\\+62)?8\\d{8,11}$"
    static let philippinesPhoneRegex = "^(?:\\+63)?9\\d{9}$"
}

struct Keys {
    static let authToken: String = "AuthTokenKey"
    static let authVerificationID: String = "AuthVerificationID"
    static let onboardingFlagKey: String = "OnboardingFlagKey"
}
