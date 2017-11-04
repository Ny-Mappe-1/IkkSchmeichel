import Foundation

let path = Bundle.main.path(forResource: "Secrets", ofType: "plist")
let dict = NSDictionary(contentsOfFile: path!) as! [String: String]

class Secrets {
    static func fetch(_ key: String) -> String {
        return dict[key]!
    }
}
