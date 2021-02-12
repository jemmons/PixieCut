import XCTest
import PixieCut



class ScopeTests: XCTestCase {
  func testNoScope() {
    let oauth = OAuthSession(clientID: "client", authURL: URL.example, tokenURL: URL.example, redirectURL: URL.example)
    let query = oauth.authRequest.url!.query!
    XCTAssertNil(query.range(of: "scope=", options: .caseInsensitive))
  }
  
  
  func testEmptyScope() {
    let oauth = OAuthSession(clientID: "client", authURL: URL.example, tokenURL: URL.example, redirectURL: URL.example, scope: [])
    let query = oauth.authRequest.url!.query!
    XCTAssertNil(query.range(of: "scope=", options: .caseInsensitive))
  }
  
  
  func testSingleScope() {
    let oauth = OAuthSession(clientID: "client", authURL: URL.example, tokenURL: URL.example, redirectURL: URL.example, scope: ["One"])
    let query = oauth.authRequest.url!.query!
    XCTAssert(query.contains("scope=One"))
  }
  
  
  func testMultipleScopes() {
    let oauth = OAuthSession(clientID: "client", authURL: URL.example, tokenURL: URL.example, redirectURL: URL.example, scope: ["One", "tWo", "thrEE"])
    let query = oauth.authRequest.url!.query!
    XCTAssert(query.contains("scope=One+tWo+thrEE"))
  }
}
