import Foundation



public struct Credentials: Decodable {
  public let accessToken: String
  public let refreshToken: String?
  public let tokenType: String
  public let expiresIn: TimeInterval?
  public let scope: [String]
  public let created = Date()
  
  
  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case tokenType = "token_type"
    case expiresIn = "expires_in"
    case scope
  }
  
  
  public init(mimeType: String, data: Data) throws {
    switch mimeType {
    case String.Contains("application/x-www-form-urlencoded"):
      try self.init(queryData: data)
      
    case String.Contains("application/json"):
      try self = JSONDecoder().decode(Credentials.self, from: data)
      
    default:
      throw Error.unexpectedMIMEType(mimeType)
    }
  }
  
  
  public init(queryData: Data) throws {
    var comps = URLComponents()
    comps.query = String(data: queryData, encoding: .utf8)
    
    guard let newAccessToken = comps.queryValue(for: CodingKeys.accessToken.rawValue) else {
      throw Error.missingRequiredQueryParameter(CodingKeys.accessToken.rawValue)
    }
    guard let newTokenType = comps.queryValue(for: CodingKeys.tokenType.rawValue) else {
      throw Error.missingRequiredQueryParameter(CodingKeys.tokenType.rawValue)
    }
    self.init(accessToken: newAccessToken,
              tokenType: newTokenType,
              refreshToken: comps.queryValue(for: CodingKeys.refreshToken.rawValue),
              expiresIn: comps.queryValue(for: CodingKeys.expiresIn.rawValue),
              scope: comps.queryValue(for: CodingKeys.scope.rawValue))
  }
  
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    let expiresIn: String?
    // Some JSON I’ve seen treats `expires_in` as an Int, and some treats it as a String.
    do {
      expiresIn = try container.decodeIfPresent(String.self, forKey: .expiresIn)
    } catch {
      expiresIn = try container.decodeIfPresent(Double.self, forKey: .expiresIn).flatMap { String($0) }
    }
    
    try self.init(accessToken: container.decode(String.self, forKey: .accessToken),
                  tokenType: container.decode(String.self, forKey: .tokenType),
                  refreshToken: container.decodeIfPresent(String.self, forKey: .refreshToken),
                  expiresIn: expiresIn,
                  scope: container.decodeIfPresent(String.self, forKey: .scope))
  }


  private init(accessToken: String, tokenType: String, refreshToken: String?, expiresIn: String?, scope: String?) {
    self.accessToken = accessToken
    self.tokenType = tokenType
    self.refreshToken = refreshToken
    self.expiresIn = expiresIn.flatMap(Double.init).flatMap(TimeInterval.init)
    self.scope = scope?.split(separator: " ").map(String.init) ?? []
  }
}


// MARK: - ERRORS
public extension Credentials {
  enum  Error: LocalizedError {
    case missingRequiredQueryParameter(String)
    case unexpectedMIMEType(String)
  }
}



// MARK: - CONVENIENCE EXTENSIONS
extension String {
  static func ~= (pattern: Contains, value: String) -> Bool {
    return value.contains(pattern.value)
  }
  
  struct Contains {
    let value: String
    init(_ value: String) {
      self.value = value
    }
  }
}

