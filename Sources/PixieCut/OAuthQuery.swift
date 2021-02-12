import Foundation



// MARK: - INIT
public struct OAuthQuery {
  private let queryItems: [URLQueryItem]
  
  
  public init(query: FormURLEncoded) {
    queryItems = query.decodeItems()
  }
  
  
  public init(queryItems: [URLQueryItem]) {
    // Query Items are assumed to be unencoded.
    self.queryItems = queryItems
  }


  public init(url: URL) throws {
    // URLs are assumed to have encoded queries.
    let encodedString = try FormURLEncoded.init(encodedString: url.query ?? "")
    self.init(query: encodedString)
  }


  public init(formURLEncodedBody: Data) throws {
    try self.init(query: FormURLEncoded(encodedData: formURLEncodedBody))
  }
}



// MARK: - PUBLIC
public extension OAuthQuery {
  func value(for name: String) -> String? {
    queryItems
      .first { $0.name == name }?
      .value
  }


  func makeQuery() -> FormURLEncoded {
    FormURLEncoded(items: queryItems)
  }
  
  
  func makeFormURLEncodedBody() -> Data {
    return Data(makeQuery().encoded.utf8)
  }
  
  
  func makeURL(with url: URL) -> URL? {
    var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
    comps?.percentEncodedQuery = makeQuery().encoded
    return comps?.url
  }
}
