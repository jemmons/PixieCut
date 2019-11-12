import Foundation


internal extension URLComponents {
  func queryValue(for name: String) -> String? {
    return queryItems?.first { $0.name == name }?.value
  }
  
  
  static func queryItems(from query: String?) -> [URLQueryItem]? {
    var comps = Self.init()
    comps.query = query
    return comps.queryItems
  }
  

  static func queryData(from queryItems: [URLQueryItem]?) -> Data? {
    var comps = Self.init()
    comps.queryItems = queryItems
    return comps.query?.data(using: .utf8)
  }
}
