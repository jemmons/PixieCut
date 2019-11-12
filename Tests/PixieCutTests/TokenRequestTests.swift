import XCTest
import PixieCut



class TokenRequestTests: XCTestCase {
  func testMismatchedStateError() {
    let stateWasMismatched = expectation(description: "waiting for error")
    
    let oauth = OAuthRequests(clientID: "client", authURL: URL.example, tokenURL: URL.example, redirectURL: URL.example, scope: ["scope"])
    let badResponse = URL(string: "https://example.com?code=1234&state=notastate")!
    
    do {
      _ = try oauth.makeTokenRequest(callback: badResponse)
    } catch OAuthRequests.Error.stateMismatch {
      stateWasMismatched.fulfill()
    } catch {
      XCTFail()
    }
      
    wait(for: [stateWasMismatched], timeout: 0)
  }
  
  
  func testMissingStateError() {
    let stateWasMissing = expectation(description: "waiting for error")
    
    let oauth = OAuthRequests(clientID: "client", authURL: URL.example, tokenURL: URL.example, redirectURL: URL.example)
    let badResponse = URL(string: "https://example.com?code=1234")!
    
    do {
      _ = try oauth.makeTokenRequest(callback: badResponse)
    } catch OAuthRequests.Error.noState {
      stateWasMissing.fulfill()
    } catch {
      XCTFail()
    }
      
    wait(for: [stateWasMissing], timeout: 0)
  }

  
  func testMissingCodeError() {
    let codeWasMissing = expectation(description: "waiting for error")
    
    let oauth = OAuthRequests(clientID: "client", authURL: URL.example, tokenURL: URL.example, redirectURL: URL.example)
    let badResponse = URL(string: "https://example.com?state=1234")!
    
    do {
      _ = try oauth.makeTokenRequest(callback: badResponse)
    } catch OAuthRequests.Error.noCode {
      codeWasMissing.fulfill()
    } catch {
      XCTFail()
    }
      
    wait(for: [codeWasMissing], timeout: 0)
  }
  
  
  func testWrongCallbackURLError() {
    let urlWasDifferent = expectation(description: "waiting for error")
    
    let oauth = OAuthRequests(clientID: "client", authURL: URL.example, tokenURL: URL.example, redirectURL: URL.example)
    let badResponse = URL(string: "https://foo.example?code=1234&state=1234")!
    
    do {
      _ = try oauth.makeTokenRequest(callback: badResponse)
    } catch OAuthRequests.Error.callbackMismatch {
      urlWasDifferent.fulfill()
    } catch {
      XCTFail()
    }
      
    wait(for: [urlWasDifferent], timeout: 0)

  }
}
