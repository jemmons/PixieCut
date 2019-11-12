import Foundation
import CommonCrypto



public struct OAuthRequests {
  public let authRequest: URLRequest

  
  private let tokenRequest: URLRequest
  private let state: String
  private let redirectURL: URL

  
  public init(clientID: String, authURL: URL, tokenURL: URL, redirectURL: URL, scope: [String] = []) {
    self.redirectURL = redirectURL
    state = Helper.makeState()
    let codeVerifier = Helper.makeCodeVerifier()
    authRequest = Helper.makeAuthRequest(authURL: authURL, clientID: clientID, redirectURL: redirectURL, scope: scope, state: state, codeVerifier: codeVerifier)
    tokenRequest = Helper.makeTokenRequest(tokenURL: tokenURL, clientID: clientID, redirectURL: redirectURL, codeVerifier: codeVerifier);
  }
  
  
  public func makeTokenRequest(callback: URL) throws -> URLRequest {
    guard callback.absoluteString.hasPrefix(redirectURL.absoluteString) else {
      throw Error.callbackMismatch
    }
    
    let comps = URLComponents(url: callback, resolvingAgainstBaseURL: false)
    guard let code = comps?.queryValue(for: "code") else {
      throw Error.noCode
    }
    guard let state = comps?.queryValue(for: "state") else {
      throw Error.noState
    }
    guard state == self.state else {
      throw Error.stateMismatch
    }
    
    return Helper.update(tokenRequest: tokenRequest, code: code)
  }
}



// MARK: - ERRORS
public extension OAuthRequests {
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
  
  
  private static func makeAuthQueryItems(clientID: String, redirectURL: URL, scope: [String], state: String, codeVerifier: String) -> [URLQueryItem] {
    var items = [
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "redirect_uri", value: redirectURL.absoluteString),
      URLQueryItem(name: "state", value: state),
      URLQueryItem(name: "code_challenge", value: DigestHelper.base64SHA256(from: codeVerifier)),
      URLQueryItem(name: "code_challenge_method", value: "S256"),
      URLQueryItem(name: "response_type", value: "code"),
    ]
    
    if !scope.isEmpty {
      items.append(URLQueryItem(name: "scope", value: scope.joined(separator: " ")))
    }
    
    return items
  }
  
  
  private static func makeTokenQueryItems(clientID: String, redirectURL: URL, codeVerifier: String) -> [URLQueryItem] {
    return [
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "redirect_uri", value: redirectURL.absoluteString),
      URLQueryItem(name: "code_verifier", value: codeVerifier),
      URLQueryItem(name: "grant_type", value: "authorization_code"),
    ]
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

  
  static func makeAuthRequest(authURL: URL, clientID: String, redirectURL: URL, scope: [String], state: String, codeVerifier: String) -> URLRequest {
    var comps = URLComponents(url: authURL, resolvingAgainstBaseURL: false)
    comps?.queryItems = makeAuthQueryItems(clientID: clientID, redirectURL: redirectURL, scope: scope, state: state, codeVerifier: codeVerifier)
    return URLRequest(url: comps?.url ?? authURL)
  }
  
  
  static func makeTokenRequest(tokenURL: URL, clientID: String, redirectURL: URL, codeVerifier: String) -> URLRequest {
    var req = URLRequest(url: tokenURL)
    req.httpMethod = "POST"
    req.allHTTPHeaderFields = [
      "content-type": "application/x-www-form-urlencoded",
      "accept": "application/x-www-form-urlencoded,application/json",
    ]
    req.httpBody = URLComponents.queryData(from: makeTokenQueryItems(clientID: clientID, redirectURL: redirectURL, codeVerifier: codeVerifier))
    return req
  }
  
  
  static func update(tokenRequest: URLRequest, code: String) -> URLRequest {
    let existingBody = tokenRequest.httpBody.flatMap(String.init(utf8Data:))
    let newQueryItems = (URLComponents.queryItems(from: existingBody) ?? [])
      .filter { $0.name != "code" }
      + [URLQueryItem(name: "code", value: code)]
    
    return tokenRequest.replacing(body: URLComponents.queryData(from: newQueryItems))
  }
}



// MARK: - CONVENIENCE EXTENSIONS
private extension String {
  init?(utf8Data: Data) {
    self.init(data: utf8Data, encoding: .utf8)
  }
}



private extension URLRequest {
  func replacing(body: Data?) -> URLRequest {
    var newRequest = self
    newRequest.httpBody = body
    return newRequest
  }
}
