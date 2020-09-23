import XCTest
import PixieCut



class TokenRequestTests: XCTestCase {
  func testMismatchedStateError() {
    let stateWasMismatched = expectation(description: "waiting for error")
    
    let oauth = OAuthSession(clientID: "client", authURL: URL.example, tokenURL: URL.example, redirectURL: URL.example, scope: ["scope"])
    let badResponse = URL(string: "https://example.com?code=1234&state=notastate")!
    
    do {
      _ = try oauth.makeTokenRequest(callback: badResponse)
    } catch OAuthSession.Error.stateMismatch {
      stateWasMismatched.fulfill()
    } catch {
      XCTFail()
    }
      
    wait(for: [stateWasMismatched], timeout: 0)
  }
  
  
  func testMissingStateError() {
    let stateWasMissing = expectation(description: "waiting for error")
    
    let oauth = OAuthSession(clientID: "client", authURL: URL.example, tokenURL: URL.example, redirectURL: URL.example)
    let badResponse = URL(string: "https://example.com?code=1234")!
    
    do {
      _ = try oauth.makeTokenRequest(callback: badResponse)
    } catch OAuthSession.Error.noState {
      stateWasMissing.fulfill()
    } catch {
      XCTFail()
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
    } catch OAuthSession.Error.noCode {
      codeWasMissing.fulfill()
    } catch {
      XCTFail()
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
    } catch OAuthSession.Error.callbackMismatch {
      urlWasDifferent.fulfill()
    } catch {
      XCTFail()
    }
      
    wait(for: [urlWasDifferent], timeout: 0)

  }
}
