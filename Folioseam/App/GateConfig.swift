import Foundation

enum GateConfig {
    static let siteHost = "quire-seam.pro"
    static var siteURL: URL { URL(string: "https://\(siteHost)")! }
    static var contactURL: URL { URL(string: "https://\(siteHost)/contact-us")! }
}
