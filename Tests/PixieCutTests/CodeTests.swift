import XCTest
import PixieCut



class CodeTests: XCTestCase {
  func testValidCodeChallenges() {
    var comps = URLComponents()
    
    let codeVerifiers: [String] = globalOAuths.map { oauthRequest in
      comps.query = oauthRequest.authRequest.url?.query
      return (comps.queryItems?.first { $0.name == "code_challenge" }?.value)!
    }
    
    let invalidCharaters = CharacterSet(charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_").inverted
    
    let looped = expectation(description: "Waiting for all the loops.")
    looped.expectedFulfillmentCount = globalOAuthCount

    codeVerifiers.forEach { codeVerifier in
      XCTAssertNil(codeVerifier.rangeOfCharacter(from: invalidCharaters))
      XCTAssertEqual(codeVerifier.count, 43)
      looped.fulfill()
    }

    wait(for: [looped], timeout: 0)
  }

  
  func testUniqueCodeChallenges() {
    var comps = URLComponents()
    
    let codeVerifiers: [String] = globalOAuths.map { oauthRequest in
      comps.query = oauthRequest.authRequest.url?.query
      return (comps.queryItems?.first { $0.name == "code_challenge" }?.value)!
    }
    
    let codeVerifierSet = Set(codeVerifiers)
    XCTAssertEqual(codeVerifierSet.count, codeVerifiers.count)
  }
  
  
  func testVerifierMatchesChallenge() {
    globalOAuths.forEach { oauth in
      var authRequestComps = URLComponents()
      authRequestComps.query = oauth.authRequest.url?.query
      let authRequestChallenge = (authRequestComps.queryItems?.first { $0.name == "code_challenge" }?.value)!
      let authRequestChallengeMethod = (authRequestComps.queryItems?.first { $0.name == "code_challenge_method" }?.value)!
      let authRequestState = (authRequestComps.queryItems?.first { $0.name == "state" }?.value)!
      

      let tokenReq = try! oauth.makeTokenRequest(callback: URL(string: "https://example.com?code=123&state=" + authRequestState)!)
      var tokenRequestComps = URLComponents()
      tokenRequestComps.query = String(data: tokenReq.httpBody!, encoding: .utf8)
      let tokenRequestVerifier = (tokenRequestComps.queryItems?.first {$0.name == "code_verifier"}?.value)!
      XCTAssertEqual(authRequestChallengeMethod, "S256")
      XCTAssertEqual(authRequestChallenge, DigestHelper.base64SHA256(from: tokenRequestVerifier))
    }
  }
}
