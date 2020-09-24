import XCTest
import PixieCut



class TokenRequestTests: XCTestCase {
  
  
  func testMismatchedStateError() {
    let stateWasMismatched = expectation(description: "waiting for error")
    
    let oauth = OAuthSession(clientID: "client", authURL: URL.example, tokenURL: URL.example, redirectURL: URL.example, scope: ["scope"])
    let badResponse = URL(string: "https://example.com?code=1234&state=notastate")!
    
    do {
      _ = try oauth.makeTokenRequest(callback: badResponse)
    } catch {
      switch error {
      case OAuthSession.Error.stateMismatch:
        XCTAssertEqual(error.localizedDescription, "The state returned by the IDP does not match that of the client.")
        XCTAssertEqual((error as NSError).localizedFailureReason, "OAuth Error")
        stateWasMismatched.fulfill()
      default:
        XCTFail()
      }
    }
    wait(for: [stateWasMismatched], timeout: 0)
  }
  
  
  func testMissingStateError() {
    let stateWasMissing = expectation(description: "waiting for error")
    
    let oauth = OAuthSession(clientID: "client", authURL: URL.example, tokenURL: URL.example, redirectURL: URL.example)
    let badResponse = URL(string: "https://example.com?code=1234")!
    
    do {
      _ = try oauth.makeTokenRequest(callback: badResponse)
    } catch {
      switch error {
      case OAuthSession.Error.noState:
        XCTAssertEqual("No state was returned by the IDP.", error.localizedDescription)
        XCTAssertEqual((error as NSError).localizedFailureReason, "OAuth Error")
        stateWasMissing.fulfill()
      default:
        XCTFail()
      }
    }
      
    wait(for: [stateWasMissing], timeout: 0)
  }

  
  func testMissingCodeError() {
    let codeWasMissing = expectation(description: "waiting for error")
    
    let oauth = OAuthSession(clientID: "client", authURL: URL.example, tokenURL: URL.example, redirectURL: URL.example)
    let authComps = URLComponents(url: oauth.authRequest.url!, resolvingAgainstBaseURL: false)!
    let state = (authComps.queryItems?.first(where: { $0.name == "state" })?.value)!
    let responseSansCode = URL(string: "https://example.com?state=\(state)")!
    
    do {
      _ = try oauth.makeTokenRequest(callback: responseSansCode)
    } catch {
      switch error {
      case OAuthSession.Error.noCode:
        XCTAssertEqual(error.localizedDescription, "No authorization code was returned by the IDP.")
        XCTAssertEqual((error as NSError).localizedFailureReason, "OAuth Error")
        codeWasMissing.fulfill()
      default:
        XCTFail()
      }
    }
      
    wait(for: [codeWasMissing], timeout: 0)
  }
  
  
  func testWrongCallbackURLError() {
    let urlWasDifferent = expectation(description: "waiting for error")
    
    let oauth = OAuthSession(clientID: "client", authURL: URL.example, tokenURL: URL.example, redirectURL: URL.example)
    let authComps = URLComponents(url: oauth.authRequest.url!, resolvingAgainstBaseURL: false)!
    let state = (authComps.queryItems?.first(where: { $0.name == "state" })?.value)!
    let differentHostResponse = URL(string: "https://foo.example?code=1234&state=\(state)")!
    
    do {
      _ = try oauth.makeTokenRequest(callback: differentHostResponse)
    } catch {
      switch error {
      case OAuthSession.Error.callbackMismatch:
        XCTAssertEqual(error.localizedDescription, "The callback URL doesn’t match the one given on initialization.")
        XCTAssertEqual((error as NSError).localizedFailureReason, "OAuth Error")
        urlWasDifferent.fulfill()
      default:
        XCTFail()
      }
    }
      
    wait(for: [urlWasDifferent], timeout: 0)
  }
}
