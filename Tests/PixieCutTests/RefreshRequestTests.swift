import XCTest
import PixieCut



class RefreshRequestTests: XCTestCase {
  func testTokenURLInRequest() {
    let tokenURL = URL.example.appendingPathComponent("token")
    let session = OAuthSession(clientID: "foo", authURL: .example, tokenURL: tokenURL, redirectURL: .example)
    let subject = session.makeRefreshRequest(refreshToken: "bar")
    XCTAssert(subject.url?.absoluteString.hasPrefix(tokenURL.absoluteString) ?? false)
  }
  
  
  func testClientIDInRequest() {
    let clientID = "123ABC"
    let session = OAuthSession(clientID: clientID, authURL: .example, tokenURL: .example, redirectURL: .example)
    let subject = session.makeRefreshRequest(refreshToken: "foo")
    
    var refreshComps = URLComponents()
    refreshComps.query = String(data: subject.httpBody!, encoding: .utf8)
    let clientIDParam = (refreshComps.queryItems?.first {$0.name == "client_id"}?.value)!
    XCTAssertEqual(clientIDParam, clientID)
  }

  
  func testRefreshTokenInRequest() {
    let token = "XYZZY"
    let session = OAuthSession(clientID: "foo", authURL: .example, tokenURL: .example, redirectURL: .example)
    let subject = session.makeRefreshRequest(refreshToken: token)
    
    var refreshComps = URLComponents()
    refreshComps.query = String(data: subject.httpBody!, encoding: .utf8)
    let tokenParam = (refreshComps.queryItems?.first {$0.name == "refresh_token"}?.value)!
    XCTAssertEqual(tokenParam, token)
  }

  
  func testGrantTypeIsRefresh() {
    let session = OAuthSession(clientID: "foo", authURL: .example, tokenURL: .example, redirectURL: .example)
    let subject = session.makeRefreshRequest(refreshToken: "foo")

    var refreshComps = URLComponents()
    refreshComps.query = String(data: subject.httpBody!, encoding: .utf8)
    let grantParam = (refreshComps.queryItems?.first {$0.name == "grant_type"}?.value)!
    XCTAssertEqual(grantParam, "refresh_token")
  }
  
  
}
