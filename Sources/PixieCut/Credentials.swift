import Foundation



public struct Credentials: Decodable {
  public let accessToken: String
  public let refreshToken: String?
  public let tokenType: String
  public let expiresInSeconds: Int?
  public let scope: [String]
  public let created = Date()
  
  
  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case tokenType = "token_type"
    case expiresInSeconds = "expires_in"
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
              expiresInSeconds: comps.queryValue(for: CodingKeys.expiresInSeconds.rawValue),
              scope: comps.queryValue(for: CodingKeys.scope.rawValue))
  }
  
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(accessToken: container.decode(String.self, forKey: .accessToken),
                  tokenType: container.decode(String.self, forKey: .tokenType),
                  refreshToken: container.decodeIfPresent(String.self, forKey: .refreshToken),
                  expiresInSeconds: container.decodeIfPresent(String.self, forKey: .expiresInSeconds),
                  scope: container.decodeIfPresent(String.self, forKey: .scope))
  }


  private init(accessToken: String, tokenType: String, refreshToken: String?, expiresInSeconds: String?, scope: String?) {
    self.accessToken = accessToken
    self.tokenType = tokenType
    self.refreshToken = refreshToken
    self.expiresInSeconds = expiresInSeconds.flatMap(Int.init)
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

