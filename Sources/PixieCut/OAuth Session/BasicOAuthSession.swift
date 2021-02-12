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
    
    authRequest = URLRequest(url: OAuthQuery(queryItems: authQueryItems).makeURL(with: authURL) ?? authURL)
  }
}



// MARK: - PUBLIC
public extension OAuthSession {
  /**
   Creates an OAuth 2 + PKCE Access Token Request.
   
   This creates a POST request to the `tokenURL` specified at init that will exchange an Authorization Code for an Access Token. The request contains the following (x-www-form-urlencoded) parameters:

   - `code`: The Authorization Code given in the `callback` `URL`.
   - `client_id`: The `clientID` given on init.
   - `redirect_url`: The `redirectURL` given on init, passed along for verification purposes.
   - `code_verifier`: The [Code Verifier](https://tools.ietf.org/html/rfc7636#section-4.1) half  of the randomly generated [Code Challenge](https://tools.ietf.org/html/rfc7636#section-4.2) sent in the `authRequest`. Both the Code Challenge and Code Verifier are unique per instance of `OAuthSession`.
   - `grant_type`: Always "authorization_code".

   - parameter callback:
     The `URL` the Authorization Server redirected to at the conclusion of a request to `authRequest`.
   
     The non-query portion of this `URL` is compared to the `redirectURL` given at init, and its `state` parameter is compared to the randomly generated state of this `OAuthSession` instance to ensure validity.
     
     The `code` parameter of this `URL` is used as the `code` parameter of the generated token request.
   
   - throws:
     - `Error.callbackMismatch`: The non-query portion of the given `callback` does not match the `redirectURL` given at init.
     - `Error.noCode`: No authorization code is present in the `callback` URL.
     - `Error.noState`: No state is present in the `callback` URL.
     - `Error.stateMismatch`: The state in the `callback` URL does not match the one generated by this `OAuthSession` instance on init.
   
   - returns: A `URLRequest` suitable for exchaning an Authorization Code with an Authorization Server for an Access Token.
   */
  func makeTokenRequest(callback: URL) throws -> URLRequest {
    let authorizationCode = try Helper.validateCallback(callback, redirect: redirectURL, state: state)
        
    let query = OAuthQuery(queryItems: [
      URLQueryItem(name: "code", value: authorizationCode),
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "redirect_uri", value: redirectURL.absoluteString),
      URLQueryItem(name: "code_verifier", value: codeVerifier),
      URLQueryItem(name: "grant_type", value: "authorization_code"),
    ])
    
    return Helper.makePOSTRequest(url: tokenURL, query: query)
  }
  
  
  /**
   Creates an OAuth 2 Refresh Access Token request.
   
   The request to exchange a Refresh Token for a new Access Token doesn’t participate in any of the generated state or code challenge/verifier hoops that `authRequest` or `makeTokenRequest(callback:)` must jump through. Thus it doesn’t require any of the “per instance” random value generated by `OAuthSession`.
   
   It *can* make use of the `tokenURL` and `clientID` given to `OAuthSession` at init, though, so is provided here as a convenience.
   
   - parameter refreshToken: The refresh token (optionally returned by the Authorization Server when requesting an Access Token via `makeTokenRequest(callback:)`).

   - returns: A `URLRequest` suitable for exchanging `refreshToken` with the Authorization Server for a new Access Token.
   */
  func makeRefreshRequest(refreshToken: String) -> URLRequest {
    let query = OAuthQuery(queryItems: [
      URLQueryItem(name: "refresh_token", value: refreshToken),
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "grant_type", value: "refresh_token"),
    ])

    return Helper.makePOSTRequest(url: tokenURL, query: query)
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
  
    
  static func makePOSTRequest(url: URL, query: OAuthQuery) -> URLRequest {
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.allHTTPHeaderFields = [
      "content-type": "application/x-www-form-urlencoded",
      "accept": "application/x-www-form-urlencoded,application/json",
    ]
    req.httpBody = query.makeFormURLEncodedBody()
    return req
  }

  
  static func validateCallback(_ callback: URL, redirect: URL, state: String) throws -> String {
    guard let _preQueryPart = callback.absoluteString.split(separator: "?").first,
          _preQueryPart == redirect.absoluteString else {
      throw OAuthSession.Error.callbackMismatch
    }

    let callbackQuery = try OAuthQuery(url: callback)
    guard let _callbackState = callbackQuery.value(for: "state") else {
      throw OAuthSession.Error.noState
    }
    
    guard _callbackState == state else {
      throw OAuthSession.Error.stateMismatch
    }

    guard let authorizationCode = callbackQuery.value(for: "code") else {
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
