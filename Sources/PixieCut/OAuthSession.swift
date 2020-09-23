import Foundation
import CommonCrypto



// MARK: - INIT
public class OAuthSession {
  public let authRequest: URLRequest

  
  private let clientID: String
  private let state: String
  private let codeVerifier: String
  private let redirectURL: URL
  private let tokenURL: URL

  
  public init(clientID: String, authURL: URL, tokenURL: URL, redirectURL: URL, scope: [String] = []) {
    self.clientID = clientID
    self.redirectURL = redirectURL
    self.tokenURL = tokenURL
    state = Helper.makeState()
    codeVerifier = Helper.makeCodeVerifier()

    var authQueryItems = [
      URLQueryItem(name: "client_id", value: self.clientID),
      URLQueryItem(name: "redirect_uri", value: self.redirectURL.absoluteString),
      URLQueryItem(name: "state", value: state),
      URLQueryItem(name: "code_challenge", value: DigestHelper.base64SHA256(from: codeVerifier)),
      URLQueryItem(name: "code_challenge_method", value: "S256"),
      URLQueryItem(name: "response_type", value: "code"),
    ]
    
    if !scope.isEmpty {
      authQueryItems.append(URLQueryItem(name: "scope", value: scope.joined(separator: " ")))
    }
    
    var authComps = URLComponents(url: authURL, resolvingAgainstBaseURL: false)
    authComps?.queryItems = authQueryItems
    authRequest = URLRequest(url: authComps?.url ?? authURL)
  }
}



// MARK: - PUBLIC
public extension OAuthSession {
  func makeTokenRequest(callback: URL) throws -> URLRequest {
    let authorizationCode = try Helper.validateCallback(callback, redirect: redirectURL, state: state)
        
    let queryItems = [
      URLQueryItem(name: "code", value: authorizationCode),
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "redirect_uri", value: redirectURL.absoluteString),
      URLQueryItem(name: "code_verifier", value: codeVerifier),
      URLQueryItem(name: "grant_type", value: "authorization_code"),
    ]
    
    return Helper.makePOSTRequest(url: tokenURL, query: queryItems)
  }
  
  
  func makeRefreshRequest(refreshToken: String) -> URLRequest {
    let queryItems = [
      URLQueryItem(name: "refresh_token", value: refreshToken),
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "grant_type", value: "refresh_token"),
    ]

    return Helper.makePOSTRequest(url: tokenURL, query: queryItems)
  }
}



// MARK: - ERRORS
public extension OAuthSession {
  enum Error: LocalizedError {
    case callbackMismatch, noCode, noState, stateMismatch
    
    
    public var errorDescription: String? {
      switch self {
      case .callbackMismatch:
        return "The callback URL doesn’t match the one given on initialization."
      case .noCode:
        return "No authorization code was returned by the IDP."
      case .noState:
        return "No state was returned by the IDP."
      case .stateMismatch:
        return "The state returned by the IDP does not match that of the client."
      }
    }
    
    public var failureReason: String? {
      return "OAuth Error"
    }
  }
}

// MARK: - HELPER
private enum Helper {
  private static let stateCharacters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  private static let codeVerifierCharacters = stateCharacters + "-._~"
  
    
  static func makePOSTRequest(url: URL, query: [URLQueryItem]) -> URLRequest {
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.allHTTPHeaderFields = [
      "content-type": "application/x-www-form-urlencoded",
      "accept": "application/x-www-form-urlencoded,application/json",
    ]
    req.httpBody = URLComponents.queryData(from: query)
    return req
  }

  
  static func validateCallback(_ callback: URL, redirect: URL, state: String) throws -> String {
    guard let _preQueryPart = callback.absoluteString.split(separator: "?").first,
          _preQueryPart == redirect.absoluteString else {
      throw OAuthSession.Error.callbackMismatch
    }

    let callbackComps = URLComponents(url: callback, resolvingAgainstBaseURL: false)
    guard let _callbackState = callbackComps?.queryValue(for: "state") else {
      throw OAuthSession.Error.noState
    }
    
    guard _callbackState == state else {
      throw OAuthSession.Error.stateMismatch
    }

    guard let authorizationCode = callbackComps?.queryValue(for: "code") else {
      throw OAuthSession.Error.noCode
    }
    
    return authorizationCode
  }
  

  static func makeCodeVerifier() -> String {
    var buf: String = ""
    (0..<128).forEach { _ in
      if let char = codeVerifierCharacters.randomElement() {
        buf.append(char)
      }
    }
    return buf
  }

  
  static func makeState() -> String {
    var buf: String = ""
    (0..<42).forEach { _ in
      if let char = stateCharacters.randomElement() {
        buf.append(char)
      }
    }
    return buf
  }
}
