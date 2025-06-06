import Foundation

protocol LocaleProviderType {
    var locale: Locale { get }
}

struct LocaleProvider: LocaleProviderType {
    var locale: Locale {
        Locale.current
    }
}
