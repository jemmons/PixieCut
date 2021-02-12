import Foundation



public struct Credentials: Decodable {
  public let accessToken: String
  public let refreshToken: String?
  public let tokenType: String
  public let expiresIn: TimeInterval?
  public let scope: [String]
  public let created: Date
  
  
  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case tokenType = "token_type"
    case expiresIn = "expires_in"
    case scope
  }
  

  public init(json: Data) throws {
    try self = JSONDecoder().decode(Credentials.self, from: json)
  }
  
  
  public init(query: OAuthQuery) throws {
    guard let newAccessToken = query.value(for: CodingKeys.accessToken.rawValue) else {
      throw Error.missingRequiredQueryParameter(CodingKeys.accessToken.rawValue)
    }
    guard let newTokenType = query.value(for: CodingKeys.tokenType.rawValue) else {
      throw Error.missingRequiredQueryParameter(CodingKeys.tokenType.rawValue)
    }
    self.init(accessToken: newAccessToken,
              tokenType: newTokenType,
              refreshToken: query.value(for: CodingKeys.refreshToken.rawValue),
              expiresIn: query.value(for: CodingKeys.expiresIn.rawValue),
              scope: query.value(for: CodingKeys.scope.rawValue))
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
    created = Date()
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
    
    public var errorDescription: String? {
      switch self {
      case .missingRequiredQueryParameter(let param):
        return "The required parameter “\(param)” was not found."
      }
    }
    
    public var failureReason: String? {
      return "Credential Error"
    }
  }
}
